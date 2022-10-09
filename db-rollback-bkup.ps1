
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

$dbamiparameter = $dbaminame+"-DB-AMI"
$appamiparameter = $appaminame+"-APP-AMI"

$DbInstanceID = (Get-EC2Instance -Region $sourceRegion -ProfileName $profile -Filter @{name='private-ip-address'; values="$dbipaddress"}).Instances

Write-Host "Instance ID for the Database Server is "$DbInstanceID.InstanceId

$AppInstanceID = (Get-EC2Instance -Region $sourceRegion -ProfileName $profile -Filter @{name='private-ip-address'; values="$appipaddress"}).Instances

Write-Host "Instance ID for the Application  Server is "$AppInstanceID.InstanceId

#$AppServerAmi = (Get-EC2Instance -Region $sourceRegion -ProfileName $profile -Filter @{name='private-ip-address'; values="$appipaddress"} | Select-Object -ExpandProperty instances | Select-Object ImageId).imageid
$AppServerAmi = (Get-SSMParameterValue -Name $dbamiparameter -ProfileName $profile -Region $sourceRegion).Parameters | Select-Object -ExpandProperty Value
Write-Host "APP server image backup taken before deployment is "$AppServerAmi


$DbServerAmi = (Get-SSMParameterValue -Name $dbamiparameter -ProfileName $profile -Region $sourceRegion).Parameters | Select-Object -ExpandProperty Value
Write-Host "DB server image backup taken before deployment is"$DbServerAmi


$dbamistatus = (Get-EC2Image -Owner self -Filter @{ Name="image-id"; Values="$DbServerAmi" } -Region $sourceRegion -ProfileName $profile ) | Select-Object -ExpandProperty State | Out-String
Write-Host $dbamistatus

if ($dbamistatus -match 'available')

	{
		$DbServerAmi = (Get-SSMParameterValue -Name $dbamiparameter -ProfileName $profile -Region $sourceRegion).Parameters | Select-Object -ExpandProperty Value
		# AMI parameter
        $p0 = new-object Amazon.CloudFormation.Model.Parameter   
		$p0.ParameterKey = "VPCStack"
		$p0.ParameterValue = "OS-BASE-DR-VPC-STACK"
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
		$p5.ParameterValue = "sg-039601687533875f4"
		$p6 = new-object Amazon.CloudFormation.Model.Parameter   
		$p6.ParameterKey = "AppSecurityGroup"
		$p6.ParameterValue = "sg-0fdc3de7dcebc6ee3"
		$p7 = new-object Amazon.CloudFormation.Model.Parameter   
		$p7.ParameterKey = "SNSTopicArn"
		$p7.ParameterValue = "arn:aws:sns:ap-southeast-1:391897533456:OS-BASE-DR-VPC-STACK-SnsTopic-1LQXOAJ62XSFY"
		
        #Remove CloudFormation Stack
        Remove-CFNStack -ProfileName $profile -StackName $stackname -Region $sourceRegion -Force

        #Wait for 1 minute
        Start-Sleep -s 1
        
        

        while($true)
        {
        #check status of the stack
        $cfstackstatus = (Test-CFNStack -ProfileName $profile -StackName $stackname -Region $sourceRegion -Status PENDING_DELETE,DELETE_IN_PROGRESS) 2>$null

        #Write-Host $cfstackstatus
        if ($cfstackstatus -match 'False' )
            {
            New-CFNStack -ProfileName $profile -StackName $stackname -Parameter @( $p0, $p1, $p2, $p3, $p4, $p5, $p6, $p7  ) -TemplateURL $stackURL -Region $sourceRegion -Capability CAPABILITY_IAM
            Break
            }
        else
            {
            Start-Sleep -s 10
            Write-Host "Stack already exists, waiting......."
            }
         }
    }
else
	{
		Write-Host "Image is not ready."

	}