$timeout = 120 ## seconds

#script block for background job
$InstalledUpdates = {
    $LogFilePath = "C:\Temp\ws1"
    if (!(Test-Path -Path $LogFilePath))
    {
        New-Item -Path $LogFilePath -ItemType Directory | Out-Null
    }
    
    $Logfile = $LogFilePath+"\installedUpdates.log"
    
    Function Log([string]$level, [string]$logstring)
    {
        $rightSide = [string]::join("   ", ($level, $logstring))
    
        $date = Get-Date -Format g
        $logEntry = [string]::join("    ", ($date, $rightSide)) 
        Add-content $Logfile -value $logEntry
    }

    $Session = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session"))#,$Computer))
    $UpdateSearcher = $Session.CreateUpdateSearcher()

    $Criteria = "IsHidden=0 and IsInstalled=1"

    try{
        $SearchResult = $UpdateSearcher.Search($Criteria).Updates
    }
    catch{
        Log "Error" "$($_.Exception)"
        return "Update Search Failed"
    }

    $HistoryDays = -28

    $InstalledUpdates = @()

    foreach ($entry in $SearchResult){
        if($entry.LastDeploymentChangeTime -gt (Get-Date).AddDays($HistoryDays)) {
            $InstalledUpdates += "KB" + $entry.KBArticleIDs
        }
    }

    #Get Windows Updates from WMI
    $WMIKBs = Get-WmiObject win32_quickfixengineering | ?{($_.InstalledOn -gt (Get-Date).AddDays($HistoryDays)) } | Select-Object HotFixID -ExpandProperty HotFixID

    #Get Windows Updates from DISM
    $DISMKBList = Get-WindowsPackage -online | ?{$_.InstallTime -gt (Get-Date).AddDays($HistoryDays)} | findstr KB 
  
    $pattern = '(?<=KB).+?(?=~)'
    if($DISMKBList){
        $DISMKBNumber = [regex]::Matches($DISMKBList, $pattern).Value
    }

    $DISMKBNumbers = @()
    ForEach ($Number in $DISMKBNumber) {
        $DISMKBNumbers += "KB$($Number)"
    }

    $OutputUpdates = ($InstalledUpdates + $WMIKBs + $DISMKBNumbers) | Sort-Object -Unique

    $OutputResult = ""

    if ($OutputUpdates.count -ne 0){
        foreach ($list in $OutputUpdates){
            $OutputResult += $list + " "
        }
        return $OutputResult
    }
    else{
        return "No Updates Installed"
    }
}

#start the background job
$job = Start-Job -ScriptBlock $InstalledUpdates

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
