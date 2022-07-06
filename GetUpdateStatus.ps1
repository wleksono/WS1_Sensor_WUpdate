$testnet = Test-NetConnection -ComputerName www.catalog.update.microsoft.com -CommonTCPPort HTTP
if($testnet.TcpTestSucceeded -eq "True"){}Else{return "No Connection"}

$Sysinfo = New-Object -ComObject Microsoft.Update.SystemInfo
$pending = $Sysinfo.RebootRequired
if ($pending){return "Pending Reboot"}

$Session = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session"))#,$Computer))
$UpdateSearcher = $Session.CreateUpdateSearcher()
$TotalHistoryCount = $UpdateSearcher.GetTotalHistoryCount()
$UpdateHistory = $UpdateSearcher.QueryHistory(0,$TotalHistoryCount)

$Criteria = "IsHidden=0 and IsInstalled=0 and IsAssigned=1"
$SearchResult = $UpdateSearcher.Search($Criteria).Updates

$FailedUpdates = @()

if($SearchResult.count -ne 0){
    foreach ($entry in $SearchResult){
        $Matches = $null
        $entry.Title -match "KB(\d+)" | Out-Null
        if ($Matches -eq $null){
            Add-Member -InputObject $entry -MemberType NoteProperty -Name KB -Value ""
        }
        else{
            Add-Member -InputObject $entry -MemberType NoteProperty -Name KB -Value ($Matches[0])
        }
        $cond=$false
        foreach ($record in $UpdateHistory){
            if($entry.Identity.updateID -eq $record.UpdateIdentity.updateID -and $record.ResultCode -eq 4){
                $cond=$true
            }
        }
        if($cond){
            $FailedUpdates += $entry
        }
    }

    if($FailedUpdates.count -ne 0){
        return "Updates Failed"
    }
    return "Updates Available"
}
else{
    return "Up to Date"
}