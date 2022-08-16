$Session = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session"))#,$Computer))
$UpdateSearcher = $Session.CreateUpdateSearcher()
$TotalHistoryCount = $UpdateSearcher.GetTotalHistoryCount()
$UpdateHistory = $UpdateSearcher.QueryHistory(0,$TotalHistoryCount)
$HistoryDays = -28

$OutputUpdates = ""
$InstalledUpdates = @()

foreach ($entry in $UpdateHistory){
    if($entry.Date -gt (Get-Date).AddDays($HistoryDays)) {
        $Matches = $null
        $entry.Title -match "KB(\d+)" | Out-Null
        if ($Matches -eq $null){
            Add-Member -InputObject $entry -MemberType NoteProperty -Name KB -Value "KBNoID"
        }
        else{
            Add-Member -InputObject $entry -MemberType NoteProperty -Name KB -Value ($Matches[0])
        }
        if ($entry.kb -ne "KBNoID" -and $entry.ResultCode -eq 2){
            $InstalledUpdates += $entry
        }
        elseif ($entry.kb -ne "KBNoID" -and $entry.ResultCode -eq 3){
            $InstalledUpdates += $entry
        }
    }
}

foreach ($entry in $InstalledUpdates){
    $OutputUpdates += $entry.kb + " " + $entry.Date.toUniversalTime().toString("dd MMM yyy 'GMT'") + "/"
}

#Get Windows Updates from WMI
$WMICall = Get-WmiObject win32_quickfixengineering | ?{($_.InstalledOn -gt (Get-Date).AddDays($HistoryDays)) } | foreach {$_.HotfixID + " " + $_.InstalledON.toUniversalTime().toString("dd MMM yyy 'GMT'") + "/" }

foreach ($wmi in $WMICall){
    if ($wmi){
        $Outputupdates += $wmi
    }
}

#Get Windows Updates from DISM
$DISMKBList = Get-WindowsPackage -online | ?{$_.InstallTime -gt (Get-Date).AddDays($HistoryDays)}
 
$pattern = '(?<=KB).+?(?=~)'
foreach ($dism in $DISMKBList){
    $dismkb = [regex]::Matches($dism.PackageName, $pattern).Value
    if($dismkb){
        $Outputupdates += "KB$($dismkb)" + " " + $dism.InstallTime.toUniversalTime().toString("dd MMM yyy 'GMT'" + "/")
    }
}

if ($OutputUpdates -ne $null){
    Return $OutputUpdates
}
else{
    return "No Updates Installed"
}