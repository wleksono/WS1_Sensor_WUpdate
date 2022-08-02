$testnet = Test-NetConnection -ComputerName www.catalog.update.microsoft.com -CommonTCPPort HTTP
if($testnet.TcpTestSucceeded -eq "True"){}Else{return "No Connection"}


$Session = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session"))#,$Computer))
$UpdateSearcher = $Session.CreateUpdateSearcher()

$Criteria = "IsHidden=0 and IsInstalled=1"
$SearchResult = $UpdateSearcher.Search($Criteria).Updates

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