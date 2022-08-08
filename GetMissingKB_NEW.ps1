$testnet = Test-NetConnection -ComputerName www.catalog.update.microsoft.com -CommonTCPPort HTTP
if($testnet.TcpTestSucceeded -eq "True"){}Else{return "No Connection"}

$Session = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session"))#,$Computer))
$UpdateSearcher = $Session.CreateUpdateSearcher()

$Criteria = "IsHidden=0 and IsInstalled=0 and IsAssigned=1"
$SearchResult = $UpdateSearcher.Search($Criteria).Updates

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