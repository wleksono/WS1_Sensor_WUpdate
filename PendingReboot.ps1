$Sysinfo = New-Object -ComObject Microsoft.Update.SystemInfo
$pending = $Sysinfo.RebootRequired
if ($pending){return $true}
else {return $false}
