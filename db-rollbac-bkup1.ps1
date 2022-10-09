
param(
    [Parameter(Mandatory=$true)][string]$appipaddress,
    [Parameter(Mandatory=$true)][string]$appaminame,
	[Parameter(Mandatory=$true)][string]$dbipaddress,
    [Parameter(Mandatory=$true)][string]$dbaminame,
    [Parameter(Mandatory=$true)][string]$sourceRegion,
    [Parameter(Mandatory=$false)][string]$profile,
    [Parameter(Mandatory=$false)][string]$stackURL,
    [Parameter(Mandatory=$false)][string]$stackname   
)


# Set Variables

$appsecuritygroup = "sg-0fdc3de7dcebc6ee3"
$dbsecuritygroup = "sg-039601687533875f4"
$snstopicarn = "arn:aws:sns:ap-southeast-1:391897533456:OS-BASE-DR-VPC-STACK-SnsTopic-1LQXOAJ62XSFY"
$vpcstackname = "OS-BASE-DR-VPC-STACK"
$errorFile = "stack-error.log"

$stackURL = "https://s3.ap-south-1.amazonaws.com/os-base-cf-templates/BASEINT3.json"

Invoke-WebRequest -Uri "$stackURL" | select -ExpandProperty Content




#Check if Stack template URL is accessible . First we create the request.
$HTTP_Request = [System.Net.WebRequest]::Create("$stackURL") 2>$null

# We then get a response from the site.
$HTTP_Response = $HTTP_Request.GetResponse() 2>$null

Write-Host $HTTP_Response

# We then get the HTTP code as an integer.
$HTTP_Status = [int]$HTTP_Response.StatusCode 2>$null

Write-Host $HTTP_Status 

If ($HTTP_Status -eq 200) {
    Write-Host "Site is OK!"
}
Else {
    Write-Host "The Stack templatet URL is not accessible."
    exit 0
}


$dbamiparameter = $dbaminame+"-DB-AMI"
$appamiparameter = $appaminame+"-APP-AMI"

$DbInstanceID = (Get-EC2Instance -Region $sourceRegion -ProfileName $profile -Filter @{name='private-ip-address'; values="$dbipaddress"}).Instances

if ($DbInstanceID) 
    {
        Write-Host "$(Get-Date) Instance ID for the Database Server is "$DbInstanceID.InstanceId 
    }
else 
    {
        Write-Host "$(Get-Date) There is no server with provided ip address for db server. Will create new server."
    }


$AppInstanceID = (Get-EC2Instance -Region $sourceRegion -ProfileName $profile -Filter @{name='private-ip-address'; values="$appipaddress"}).Instances

if ($AppInstanceID) 
    {
        Write-Host "$(Get-Date) Instance ID for the Application  Server is "$AppInstanceID.InstanceId 
    }
else 
    {
        Write-Host "$(Get-Date) There is no server with provided ip address for app server. Will create new server." 
    }


$AppServerAmi = (Get-SSMParameterValue -Name $dbamiparameter -ProfileName $profile -Region $sourceRegion).Parameters | Select-Object -ExpandProperty Value
Write-Host "$(Get-Date) APP server image backup taken before deployment is "$AppServerAmi 


$DbServerAmi = (Get-SSMParameterValue -Name $dbamiparameter -ProfileName $profile -Region $sourceRegion).Parameters | Select-Object -ExpandProperty Value
Write-Host "$(Get-Date) DB server image backup taken before deployment is"$DbServerAmi 


$dbamistatus = (Get-EC2Image -Owner self -Filter @{ Name="image-id"; Values="$DbServerAmi" } -Region $sourceRegion -ProfileName $profile ) | Select-Object -ExpandProperty State | Out-String
#Write-Host $dbamistatus

$appamistatus = (Get-EC2Image -Owner self -Filter @{ Name="image-id"; Values="$AppServerAmi" } -Region $sourceRegion -ProfileName $profile ) | Select-Object -ExpandProperty State | Out-String
#Write-Host $appamistatus

if ($dbamistatus -match 'available' -And $appamistatus -match 'available' )

	{
		# Set Parameters for Cloudformation template
        $p0 = new-object Amazon.CloudFormation.Model.Parameter   
		$p0.ParameterKey = "VPCStack"
		$p0.ParameterValue = "$vpcstackname"
		$p1 = new-object Amazon.CloudFormation.Model.Parameter   
		$p1.ParameterKey = "AppServerAmi"
		$p1.ParameterValue = "$AppServerAmi"
		$p2 = new-object Amazon.CloudFormation.Model.Parameter   
		$p2.ParameterKey = "DbServerAmi"
		$p2.ParameterValue = "$DbServerAmi"
		$p3 = new-object Amazon.CloudFormation.Model.Parameter   
		$p3.ParameterKey = "AppServerIpAddress"
		$p3.ParameterValue = "$appipaddress"
		$p4 = new-object Amazon.CloudFormation.Model.Parameter   
		$p4.ParameterKey = "DbServerIpAddress"
		$p4.ParameterValue = "$dbipaddress"
		$p5 = new-object Amazon.CloudFormation.Model.Parameter   
		$p5.ParameterKey = "DBSecurityGroup"
		$p5.ParameterValue = "$dbsecuritygroup"
		$p6 = new-object Amazon.CloudFormation.Model.Parameter   
		$p6.ParameterKey = "AppSecurityGroup"
		$p6.ParameterValue = "$appsecuritygroup"
		$p7 = new-object Amazon.CloudFormation.Model.Parameter   
		$p7.ParameterKey = "SNSTopicArn"
		$p7.ParameterValue = "$snstopicarn"
		
        #Remove CloudFormation Stack

        Write-Host "$(Get-Date) AMIs of App and Db serveres are available. Now terminating existing stack."
        Remove-CFNStack -ProfileName $profile -StackName $stackname -Region $sourceRegion -Force

        #Wait for 1 minute
        Start-Sleep -s 1
        
        
        while($true)
        {
        #check status of the stack
        $cfstackstatus = (Test-CFNStack -ProfileName $profile -StackName $stackname -Region $sourceRegion -Status PENDING_DELETE,DELETE_IN_PROGRESS) 

            if ($cfstackstatus -match 'False' )  
                {
                    Write-Host "$(Get-Date) Existing Stack terminated. Creating new stack with below detail:"
                    Write-Host "            Stack Name : $stackname"
                    Write-Host "            Template URL : $stackURL"
                    $NewStackArn = (New-CFNStack -ProfileName $profile -StackName $stackname -Parameter @( $p0, $p1, $p2, $p3, $p4, $p5, $p6, $p7  ) -TemplateURL $stackURL -Region $sourceRegion -Capability CAPABILITY_IAM ) 2>&1 | tee -filePath $errorFile
                    Write-Host 
                    if ($NewStackArn) 
                        {
                            Write-Host "$(Get-Date) New stack created with ARN: "$NewStackArn
                        }
                        else
                        {
                            Write-Host "$(Get-Date) Error in creating the Stack. Check logsin $errorFile for detail."
                        }
                    Break
                }
            else
                {
                    Start-Sleep -s 10
                    Write-Host "$(Get-Date) Stack already exists, waiting for stack to be terminated......."
                }
         }
    }
else
	{
		Write-Host "Image is not ready." | timestamp

	}