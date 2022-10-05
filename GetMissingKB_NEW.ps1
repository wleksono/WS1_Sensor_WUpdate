$Session = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session"))#,$Computer))
$UpdateSearcher = $Session.CreateUpdateSearcher()

$Criteria = "IsHidden=0 and IsInstalled=0 and IsAssigned=1"

try{
    $SearchResult = $UpdateSearcher.Search($Criteria).Updates
}
catch{
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
