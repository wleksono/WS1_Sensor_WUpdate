$Sysinfo = New-Object -ComObject Microsoft.Update.SystemInfo
$pending = $Sysinfo.RebootRequired
if ($pending){
	try{
	    shutdown.exe /r /f /t 120
	}
	catch{
	    exit 1
	}
	exit 2
}

$Session = [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session"))#,$Computer))
$UpdateSearcher = $Session.CreateUpdateSearcher()

$Criteria = "IsHidden=0 and IsInstalled=0 and IsAssigned=1"

try{
    $SearchResult = $UpdateSearcher.Search($Criteria).Updates
}
catch{
    exit 1
}

if($SearchResult.count -ne 0){
    foreach ($entry in $SearchResult){
	    if ($entry.isDownloaded -eq $false){		
		    $updateSession = New-Object -ComObject 'Microsoft.Update.Session'
		    $updatesToDownload = New-Object -ComObject 'Microsoft.Update.UpdateColl'
		    $updatesToDownload.Add($entry) | Out-Null
            $downloader = $updateSession.CreateUpdateDownloader()
            $downloader.Updates = $updatesToDownload
		    try{
        	    $downloadResult = $downloader.Download()
		    }
		    catch{
		        "Download failed"
		    }
		    if ($downloadResult.ResultCode -eq 2) {
			    $updatesToInstall = New-Object -ComObject 'Microsoft.Update.UpdateColl'
			    $updatesToInstall.Add($entry) | Out-Null
			
			    $installer = New-Object -ComObject 'Microsoft.Update.Installer'
			    $installer.Updates = $updatesToInstall        
			    try{
			        $installResult = $installer.Install()
			    }
			    catch{
                    "Install Failed"
			    }
			    Clear-Variable updatesToInstall -Force -ErrorAction SilentlyContinue
		    }
		    Clear-Variable updatesToDownload -Force -ErrorAction SilentlyContinue
	    }
	    else{
		    $updatesToInstall = New-Object -ComObject 'Microsoft.Update.UpdateColl'
		    $updatesToInstall.Add($entry) | Out-Null 

            $installer = New-Object -ComObject 'Microsoft.Update.Installer'
            $installer.Updates = $updatesToInstall        
		    try{
        	    $installResult = $installer.Install()
		    }
		    catch{
                "Install Failed"
		    }
		    Clear-Variable updatesToInstall -Force -ErrorAction SilentlyContinue
	    }
    }
    $Sysinfo = New-Object -ComObject Microsoft.Update.SystemInfo
    $pending = $Sysinfo.RebootRequired
    if ($pending) {
        try{
	        shutdown.exe /r /f /t 120
        }
        catch{
            exit 1
        }
    }
}
exit
