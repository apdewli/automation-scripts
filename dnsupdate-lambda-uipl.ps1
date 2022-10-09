$InstanceID = $serverinstanceid
$Region = "ap-south-1"
$dnsServerId = "$dnsserverid"

$hostName = (Get-EC2Instance -Region $region  -InstanceId $InstanceID ).Instances | ?{$_.InstanceId -eq $instanceId} | select -ExpandProperty tag | ?{$_.Key -eq "Name"} | select -ExpandProperty value


Write-Host $hostName
$hostAddress = (Get-EC2Instance -Region $region  -InstanceId $InstanceID ).Instances | ?{$_.InstanceId -eq $instanceId} | select -ExpandProperty PrivateIpAddress

Write-Host $hostAddress

Send-SSMCommand -Region $Region  -InstanceId @($dnsServerId) -DocumentName update-dns-record -Comment 'updating dns record for new host' -Parameter @{ "dnsServerIp" = "$dnsServerIp";"hostName" = "$hostName";"hostAddress" = "$hostAddress" }