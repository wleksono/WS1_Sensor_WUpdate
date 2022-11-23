﻿$timeout = 105 ## seconds

#script block for background job
$CheckUpdates = {
    $LogFilePath = "C:\Temp\ws1"
    if (!(Test-Path -Path $LogFilePath))
    {
        New-Item -Path $LogFilePath -ItemType Directory | Out-Null
    }
    
    $Logfile = $LogFilePath+"\checkUpdates.log"
    
    Function Log([string]$level, [string]$logstring)
    {
        $rightSide = [string]::join("   ", ($level, $logstring))
    
        $date = Get-Date -Format g
        $logEntry = [string]::join("    ", ($date, $rightSide)) 
        Add-content $Logfile -value $logEntry
    }

    Function Get-LocalTime($UTCTime) {
        $strCurrentTimeZone = (Get-WmiObject win32_timezone).StandardName
        $TZ = [System.TimeZoneInfo]::FindSystemTimeZoneById($strCurrentTimeZone)
        Return [System.TimeZoneInfo]::ConvertTimeFromUtc($UTCTime, $TZ)
    }

    $Sysinfo = New-Object -ComObject Microsoft.Update.SystemInfo
    $pending = $Sysinfo.RebootRequired
    if ($pending){return "Pending Reboot"}

    $testnet = Test-NetConnection -ComputerName www.catalog.update.microsoft.com -CommonTCPPort HTTP

    $lastCheck = Get-LocalTime $(New-Object -ComObject Microsoft.Update.AutoUpdate).Results.LastSearchSuccessDate

    $Session = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session"))#,$Computer))
    $UpdateSearcher = $Session.CreateUpdateSearcher()
    if (((Get-Date) - $lastCheck).days -eq 0 -or $testnet.TcpTestSucceeded -ne "True"){$UpdateSearcher.Online = $false}
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
            if ($a -ge ($retrycount-1)) {$UpdateSearcher.Online = $false}
            if ($a -ge $retrycount) {return "Update Search Failed"}
        }
    }Until ($a -ge $retrycount -or $trigger)
    
    $FailedUpdates = @()
        
    if($SearchResult.count -ne 0){
        foreach ($entry in $SearchResult){
            $cond=$false
            foreach ($record in $UpdateHistory){
                if($record.Date -gt (Get-Date).AddDays(-2) -and $entry.Identity.updateID -eq $record.UpdateIdentity.updateID -and $record.ResultCode -eq 4){
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
}

#start the background job
$job = Start-Job -ScriptBlock $CheckUpdates

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