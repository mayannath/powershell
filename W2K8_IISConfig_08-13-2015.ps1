Set-ExecutionPolicy RemoteSigned -Force
$IISRoot = "D:\Website"
$IISWebLogs = "D:\Website\WebLogs"
$IISWebRoot = "D:\Website\Internet"
$IISFTPLogs = "D:\Website\FTPLogs"
$IISFTPRoot = "D:\Website\FTPRoot"
Import-Module ServerManager 
Add-WindowsFeature -Name Web-Common-Http,Web-Http-logging,Web-Custom-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-Http-Tracing,Web-Performance,Web-Filtering,Web-ASP-Net,Web-FTP-Server,Web-Mgmt-Console,Web-Scripting-Tools,Web-Mgmt-Service -IncludeAllSubFeature
Import-Module WebAdministration
New-Item -Path $IISRoot -type directory -Force -ErrorAction SilentlyContinue
New-Item -Path $IISWebLogs -type directory -Force -ErrorAction SilentlyContinue
New-Item -Path $IISWebRoot -type directory -Force -ErrorAction SilentlyContinue
New-Item -Path $IISFTPLogs -type directory -Force -ErrorAction SilentlyContinue
New-Item -Path $IISFTPRoot -type directory -Force -ErrorAction SilentlyContinue
$Command = "icacls $IISRoot /grant[r] BUILTIN\Administrators:(OI)(CI)F /inheritance:r"
cmd.exe /c $Command
$Command = "icacls $IISRoot /grant[r] SYSTEM:(OI)(CI)F"
cmd.exe /c $Command
$Command = "icacls $IISWebRoot /grant[r] BUILTIN\IIS_IUSRS:(OI)(CI)(RX)"
cmd.exe /c $Command
$Command = "icacls $IISWebRoot /grant[r] IUSR:(OI)(CI)(RX)"
cmd.exe /c $Command
$Command = "%windir%\system32\inetsrv\appcmd set config -section:system.applicationHost/sites -siteDefaults.logfile.directory:$IISWebLogs"
cmd.exe /c $Command
$Command = "%windir%\system32\inetsrv\appcmd set config -section:system.applicationHost/log -centralBinaryLogFile.directory:$IISWebLogs"
cmd.exe /c $Command
$Command = "%windir%\system32\inetsrv\appcmd set config -section:system.applicationHost/log -centralW3CLogFile.directory:$IISWebLogs"
cmd.exe /c $Command
        
Set-WebConfigurationProperty -Filter System.Applicationhost/Sites/SiteDefaults/logfile -Name LogExtFileFlags -Value "Date,Time,ClientIP,UserName,ServerIP,Method,UriStem,UriQuery,HttpStatus,Win32Status,TimeTaken,ServerPort,UserAgent,Referer,HttpSubStatus,SiteName,ComputerName,BytesSent,BytesRecv,ProtocolVersion,Cookie,Host"
Set-ItemProperty 'IIS:\Sites\Default Web Site' -name physicalPath -value $IISWebRoot
     
Set-WebConfigurationProperty -Filter System.Applicationhost/Sites/SiteDefaults/FTPServer/logfile -Name LogExtFileFlags -Value "Date,Time,ClientIP,UserName,SiteName,ComputerName,ServerIP,Method,UriStem,FtpStatus,Win32Status,BytesSent,BytesRecv,TimeTaken,ServerPort,Host,FtpSubStatus,Session,FullPath,Info,ClientPort"

New-WebFtpSite -Name "Default FTP Site" -Port "21" -Force
cmd /c \Windows\System32\inetsrv\appcmd set SITE "Default FTP Site" "-virtualDirectoryDefaults.physicalPath:D:\Website\FTPRoot"
     
Set-ItemProperty "IIS:\Sites\Default FTP Site" -Name ftpServer.security.ssl.controlChannelPolicy -Value 0
Set-ItemProperty "IIS:\Sites\Default FTP Site" -Name ftpServer.security.ssl.dataChannelPolicy -Value 0
Set-ItemProperty "IIS:\Sites\Default FTP Site" -Name ftpServer.security.authentication.basicAuthentication.enabled -Value $true
Set-WebConfiguration "/system.ftpServer/security/authorization" -value @{accessType="Allow";roles="";permissions="Read,Write";users="*"} -PSPath IIS:\ -location "Default FTP Site"
     
$SetFTPLog = "%windir%\system32\inetsrv\appcmd set config -section:system.applicationHost/sites -siteDefaults.ftpServer.logFile.directory:$IISFTPLogs"
cmd.exe /c $SetFTPLog
$SetFTPLog = "%windir%\system32\inetsrv\appcmd set config -section:system.applicationHost/sites -siteDefaults.ftpServer.logFile.period:Daily"
cmd.exe /c $SetFTPLog
$SetFTPLog = "%windir%\system32\inetsrv\appcmd set config -section:system.applicationHost/sites -siteDefaults.ftpServer.logFile.enabled:True"
cmd.exe /c $SetFTPLog
$LocalTime = "%windir%\system32\inetsrv\appcmd set config -section:system.applicationHost/sites -siteDefaults.ftpServer.logfile.LocalTimeRollover:True"
cmd.exe /c $LocalTime
 
Restart-WebItem "IIS:\Sites\Default FTP Site"

If (!(Test-Path "C:\inetpub\temp\apppools")) {New-Item -Path "C:\inetpub\temp\apppools" -type directory -Force -ErrorAction SilentlyContinue}
Copy-Item C:\inetpub\wwwroot\iis* -destination D:\Website\Internet
Copy-Item C:\inetpub\wwwroot\wel* -destination D:\Website\Internet
$Command = "IISRESET"
Invoke-Expression -Command $Command
