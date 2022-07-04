﻿$testnet = Test-NetConnection -ComputerName www.catalog.update.microsoft.com -CommonTCPPort HTTP
if($testnet.TcpTestSucceeded -eq "True"){}Else{return "No Connection"}

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
        foreach ($record in $UpdateHistory){
            if($entry.Identity.updateID -eq $record.Identity.updateID -and $record.ResultCode -eq 4){
                $FailedUpdates += $entry
            }
        }
    }
    $OutputResult=""
    if($FailedUpdates.kb){
        foreach ($list in $FailedUpdates){
            $OutputResult += $list.kb + " "
        }
    }
    return $OutputResult
}
else{
    return "No Missing Updates"
}