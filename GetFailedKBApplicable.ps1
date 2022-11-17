$timeout = 105 ## seconds

#script block for background job
$FailedUpdates = {
    $LogFilePath = "C:\Temp\ws1"
    if (!(Test-Path -Path $LogFilePath))
    {
        New-Item -Path $LogFilePath -ItemType Directory | Out-Null
    }
    
    $Logfile = $LogFilePath+"\failedUpdates.log"
    
    Function Log([string]$level, [string]$logstring)
    {
        $rightSide = [string]::join("   ", ($level, $logstring))
    
        $date = Get-Date -Format g
        $logEntry = [string]::join("    ", ($date, $rightSide)) 
        Add-content $Logfile -value $logEntry
    }

    $Session = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session"))#,$Computer))
    $UpdateSearcher = $Session.CreateUpdateSearcher()
    $updateSearcher.Online = $false
    $TotalHistoryCount = $UpdateSearcher.GetTotalHistoryCount()
    if($TotalHistoryCount -eq 0){$TotalHistoryCount = 1}
    $UpdateHistory = $UpdateSearcher.QueryHistory(0,$TotalHistoryCount)

    $Criteria = "IsHidden=0 and IsInstalled=0 and IsAssigned=1"

    $retrycount = 3
    $a = 0
    do{
        $a++
        $trigger = $true
        try{
            $SearchResult = $UpdateSearcher.Search($Criteria).Updates
        }catch{
            Log "Error" "$($_.Exception)"
            $trigger = $false
            if ($a -ge $retrycount) {return "Update Search Failed"}
        }
    }Until ($a -ge $retrycount -or $trigger)

    $FailedUpdates = @()

    if($SearchResult.count -ne 0){
        foreach ($entry in $SearchResult){
            $cond=$false
            foreach ($record in $UpdateHistory){
                if($record.Date -gt (Get-Date).AddDays(-2) -and $entry.Identity.updateID -eq $record.UpdateIdentity.updateID -and $record.ResultCode -eq 4){
                    $cond = $true
                }
            }
            if($cond){
                $FailedUpdates += "KB" + $entry.KBArticleIDs
            }
        }
    
        $OutputResult = ""
    
        if($FailedUpdates.count -ne 0){
            foreach ($list in $FailedUpdates){
                $OutputResult += $list + " "
            }
            return $OutputResult
        }
        return "No Failed Applicable Updates"
    }
    else{
        return "No Missing Updates"
    }
}

#start the background job
$job = Start-Job -ScriptBlock $FailedUpdates

#retrieve job data after timeout
if ((Wait-Job $job -Timeout $timeout) -ne $null) {
    #get current job result
    Receive-Job $job
}

else{
    #force removing the job after timeout
    Remove-Job -force $job

    #return timeout if no result returned before
    return "action timed out"
}
