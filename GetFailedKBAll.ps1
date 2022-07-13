$Session = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session"))#,$Computer))
$UpdateSearcher = $Session.CreateUpdateSearcher()
$TotalHistoryCount = $UpdateSearcher.GetTotalHistoryCount()
$UpdateHistory = $UpdateSearcher.QueryHistory(0,$TotalHistoryCount)

$FailedUpdates = @()

foreach ($entry in $UpdateHistory){
    $Matches = $null
    $entry.Title -match "KB(\d+)" | Out-Null
    if ($Matches -eq $null){
        Add-Member -InputObject $entry -MemberType NoteProperty -Name KB -Value "KBNoID"
    }
    else{
        Add-Member -InputObject $entry -MemberType NoteProperty -Name KB -Value ($Matches[0])
    }
    if ($entry.ResultCode -eq 4){
        $cond = $true
        foreach ($c in $UpdateHistory){
            if ($c.UpdateIdentity.updateID -eq $entry.UpdateIdentity.updateID -and $c.ResultCode -eq 2){
                $cond = $false
            }
        }
        if($cond){
            $FailedUpdates += $entry
        }
    }
}

$OutputUpdates = ($FailedUpdates.kb) | Sort-Object -Unique
$OutputResult = ""

if ($OutputUpdates.count -ne 0){
    foreach ($list in $OutputUpdates){
        $OutputResult += $list + " "
    }
    return $OutputResult
}
else{
    return "No Failed Updates"
}
