$Sysinfo = New-Object -ComObject Microsoft.Update.SystemInfo
$pending = $Sysinfo.RebootRequired
if ($pending){return "Pending Reboot"}

$Session = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session"))#,$Computer))
$UpdateSearcher = $Session.CreateUpdateSearcher()
$TotalHistoryCount = $UpdateSearcher.GetTotalHistoryCount()
$UpdateHistory = $UpdateSearcher.QueryHistory(0,$TotalHistoryCount)

$Criteria = "IsHidden=0 and IsInstalled=0 and IsAssigned=1"

try{
    $SearchResult = $UpdateSearcher.Search($Criteria).Updates
}
catch{
    return "Update Search Failed"
}

$FailedUpdates = @()

if($SearchResult.count -ne 0){
    foreach ($entry in $SearchResult){
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
