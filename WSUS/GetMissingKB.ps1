$timeout = 120 ## seconds

#script block for background job
$MissingUpdates = {
    $LogFilePath = "C:\Temp\ws1"
    if (!(Test-Path -Path $LogFilePath))
    {
        New-Item -Path $LogFilePath -ItemType Directory | Out-Null
    }
    
    $Logfile = $LogFilePath+"\missingUpdates.log"
    
    Function Log([string]$level, [string]$logstring)
    {
        $rightSide = [string]::join("   ", ($level, $logstring))
    
        $date = Get-Date -Format g
        $logEntry = [string]::join("    ", ($date, $rightSide)) 
        Add-content $Logfile -value $logEntry
    }

    $Session = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session"))#,$Computer))
    $UpdateSearcher = $Session.CreateUpdateSearcher()
    $updateSearcher.ServerSelection = "1"

    $Criteria = "IsHidden=0 and IsInstalled=0 and IsAssigned=1"

    try{
        $SearchResult = $UpdateSearcher.Search($Criteria).Updates
    }
    catch{
        Log "Error" "$($_.Exception)"
        return "Update Search Failed"
    }

    if($SearchResult.count -ne 0){
        $OutputResult=""
        foreach ($entry in $SearchResult){
            $OutputResult += "KB" + $entry.KBArticleIDs + " "
        }
        return $OutputResult
    }
    else{
        return "No Missing Updates"
    }
}

#start the background job
$job = Start-Job -ScriptBlock $MissingUpdates

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
