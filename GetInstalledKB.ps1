$Session = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session"))#,$Computer))
$UpdateSearcher = $Session.CreateUpdateSearcher()
$TotalHistoryCount = $UpdateSearcher.GetTotalHistoryCount()
$UpdateHistory = $UpdateSearcher.QueryHistory(0,$TotalHistoryCount)
$HistoryDays = -90

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
        if ($entry.ResultCode -eq 2){
            $InstalledUpdates += $entry
        }
        elseif ($entry.ResultCode -eq 3){
            $InstalledUpdates += $entry
        }
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

$OutputUpdates = ($InstalledUpdates.kb + $WMIKBs + $DISMKBNumbers) | Sort-Object -Unique

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
