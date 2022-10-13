param(
    [Parameter(Mandatory=$true)][string]$instanceid,
    [Parameter(Mandatory=$false)][string]$dnsserverid   
)

$InstanceID = $instanceid

$Region = "ap-south-1"
$profile = "xxxxxxxxxxxxxxx"

$dnsServerId = "$dnsserverid"
$hostName = (Get-EC2Instance -Region $region -ProfileName $profile -InstanceId $InstanceID ).Instances | ?{$_.InstanceId -eq $instanceId} | select -ExpandProperty tag | ?{$_.Key -eq "Name"} | select -ExpandProperty value


Write-Host $hostName
$hostAddress = (Get-EC2Instance -Region $region -ProfileName $profile -InstanceId $InstanceID ).Instances | ?{$_.InstanceId -eq $instanceId} | select -ExpandProperty PrivateIpAddress

Write-Host $hostAddress


Send-SSMCommand -Region $Region -ProfileName $profile -InstanceId @($dnsServerId) -DocumentName update-dns-record -Comment 'updating dns record for new host' -Parameter @{ "dnsServerIp" = "$dnsServerIp";"hostName" = "$hostName";"hostAddress" = "$hostAddress" }
