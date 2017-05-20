#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#pragma compile(inputboxres, true)
#include <Crypt.au3>
#include <WinAPIShPath.au3>

#include <MsgBoxConstants.au3>

#include "Includes\Config.au3"
#include "Includes\Loading GUI.au3"
#include "Includes\Wake On LAN.au3"
#include "Includes\Updater.au3"
If @Compiled Then _Update(FileGetVersion(@AutoItExe), "https://raw.githubusercontent.com/Gianfranco753/Parsec-Shortcut/master/Version", "https://raw.githubusercontent.com/Gianfranco753/Parsec-Shortcut/master/build/Parsec Shortcut.exe")

;Define some global variables
Global $sLoadingText

;Crypto stuff
_Crypt_Startup() ;Start the Crypt functions
$g_hKey = _Crypt_DeriveKey('keykeykey', $CALG_RC4) ;Generate a key (this password should be keep a secret, the pass in the compiled is different)
OnAutoItExitRegister("_CloseCrypt") ;Program the cleaning of the crypt library on program exit
Func _CloseCrypt()
	;Close, destroy and clean all the Crypt functions
	_Crypt_DestroyKey($g_hKey)
	_Crypt_Shutdown()
EndFunc   ;==>_CloseCrypt

#Region Config
$aCmdLine = _WinAPI_CommandLineToArgv($CmdLineRaw) ;Read arguments
;Load the configuration, the function _ReadConfig is defined on Includes\Config.au3
$sConfigFile = _SearchCmdLine("-config") ;The config file is where all this data is read/written, use one for every computer you want to control
If $sConfigFile = '' Then $sConfigFile = "Config.ini" ;If no config file is especified, use the default
;All this Regex could be better, but works for now.
;Read variables about the server, Parsec user and timeouts, read Includes\Config.au3 for a definition on every parameter in _ReadConfig
$sServerName = _ReadConfig($sConfigFile, "Server", "Name", "Enter the server name (as appear in Parsec servers list)", "[A-Za-z]{1}[0-9A-Za-z]{0,14}", "The computer name needs to start with a letter and could be maximun 15 characters")
$sServerMAC = _ReadConfig($sConfigFile, "Server", "MAC", "Enter the server MAC address (The server on the LAN that you want to wake)", "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})|([0-9A-Fa-f]{12})", "The MAC form is six groups of two hexadecimal digits, separated by hyphens (-) or colons (:)")
$sServerIP = _ReadConfig($sConfigFile, "Server", "IP", "Enter the IP address of the server that you want to wake (to verify when the server wake up)", "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$")
$sCorreo = _ReadConfig($sConfigFile, "Parsec", "User", "Enter your Parsec email", '(?:[a-z0-9!#$%&' & "'" & '*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&' & "'" & '*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])')
$sPass = _ReadConfig($sConfigFile, "Parsec", "Password", "Enter your Parsec password", Default, Default, Default, True)
$MaxPingTimeout = _ReadConfig($sConfigFile, "Timeout", "Ping", "Enter the timeout for waiting server wake up (with WoL) in miliseconds", "^[1-9]\d*$", "The number needs to be a positive, whole number.", 10000, False, False)
;Needs to change description of (2), idk
$MaxParsecTimeout = _ReadConfig($sConfigFile, "Timeout", "Parsec", "Enter the timeout for waiting server connection to Parsec in miliseconds (1)", "^[1-9]\d*$", "The number needs to be a positive, whole number.", 60000, False, False)
$iServerConnectingTime = _ReadConfig($sConfigFile, "Server", "ConnectingTime", "Enter the timeout for waiting server connection to Parsec in miliseconds (2)", "^[1-9]\d*$", "The number needs to be a positive, whole number.", 10000, False, False)
$iPortOpener = _ReadConfig($sConfigFile, "Opener", "Port", "Enter the port for the opener server, if not needed, enter 0", "^[1-9]\d*$", "The number needs to be a positive, whole number.", 7999, Default, False)
$sPassOpener = _ReadConfig($sConfigFile, "Opener", "Password", "Enter the password for the opener server", Default, Default, Default, True)
;only store password of parse.tv if the user allows it and it's not in config file
$iRandom = Random(10000, 99999, 1) ;Use a random to minimize the posibility that a user name is computer ERROR and the program doesn't recognize it
If IniRead($sConfigFile, "Parsec", "User", "ERROR" & $iRandom & "ERROR") = "ERROR" & $iRandom & "ERROR" Or IniRead($sConfigFile, "Parsec", "Password", "ERROR" & $iRandom & "ERROR") = "ERROR" & $iRandom & "ERROR" Then
	If MsgBox($MB_YESNO + $MB_ICONQUESTION, "", "Do you want to remember your parsec user and pass?") = $IDYES Then ;Ask if user wants to save user and pass to config file
		IniWrite($sConfigFile, "Parsec", "User", $sCorreo) ;Write user to config file
		$bEncrypted = _Crypt_EncryptData($sPass, $g_hKey, $CALG_USERKEY) ;Encrypt password
		IniWrite($sConfigFile, "Parsec", "Password", $bEncrypted) ;Write encrypted password to config file
	EndIf
EndIf
;Always store last server info in config file
IniWrite($sConfigFile, "Server", "Name", $sServerName)
IniWrite($sConfigFile, "Server", "MAC", $sServerMAC)
IniWrite($sConfigFile, "Server", "IP", $sServerIP)
IniWrite($sConfigFile, "Timeout", "Ping", $MaxPingTimeout)
IniWrite($sConfigFile, "Timeout", "Parsec", $MaxParsecTimeout)
IniWrite($sConfigFile, "Server", "ConnectingTime", $iServerConnectingTime)
IniWrite($sConfigFile, "Opener", "Port", $iPortOpener)
$bEncrypted = _Crypt_EncryptData($sPassOpener, $g_hKey, $CALG_USERKEY) ;Encrypt password
IniWrite($sConfigFile, "Opener", "Password", $bEncrypted)
;Derive a key for the opener password
$g_hOpenerKey = _Crypt_DeriveKey($sPassOpener, $CALG_RC4) ;Generate a key (this password should be keep a secret)
OnAutoItExitRegister("_DestroyOpenerPass") ;Program the cleaning of the crypt library on program exit
Func _DestroyOpenerPass()
	_Crypt_DestroyKey($g_hOpenerKey)
EndFunc   ;==>_CloseCrypt
#EndRegion Config

#include "GUI.au3" ;Include GUI only when whe have all the needed variables

#Region Wake on LAN
_MaxMinPerc(20, "Waking up " & $sServerName)
$bDidWoL = False
If Ping($sServerIP) = 0 Then ;Send WoL Magic Package only if Server isn't responding to pings
	$bDidWoL = True
	UDPStartup() ;Start UDP
	$connexion = UDPOpen(StringLeft($sServerIP, StringInStr($sServerIP, ".", 0, -1)) & "255", 7) ;This is the broadcast ip, it's the server ip but the last part is 255
	$res = UDPSend($connexion, GenerateMagicPacket($sServerMAC)) ;Send a Magic Packet, the function to generate the Magic Packet is in Includes\Wake On LAN.au3
	UDPCloseSocket($connexion) ;Close the connection
	UDPShutdown() ;Shutdown UDP
	$iPerc = 2
	;Wait por server waking up (or timeout)
	$hTimer = TimerInit()
	Do
		Sleep(10)
		$iPerc += ($iMaxPerc - 2) / ($MaxPingTimeout / 110)
		PlayAnim()
	Until Ping($sServerIP, 100) <> 0 Or TimerDiff($hTimer) > $MaxPingTimeout
	;If Timeout and server isn't responding to pings, assume that the server can't be waken up, alert the user and exit
	$iPerc = 20
	If Ping($sServerIP) = 0 Then
		_addBallError(1)
		MsgBox($MB_ICONERROR, "", "ERROR" & @CRLF & "MaxPingTimeout exceded, can't wake up the server with WoL" & @CRLF & "Exiting...")
		Exit
	EndIf
EndIf
#EndRegion Wake on LAN
#Region Open program
_MaxMinPerc(40, "Sending open command to Opener")
$sToRun = _SearchCmdLine("-open")
$iPerc = 24
If $sToRun <> '' Then
	TCPStartup() ; Start the TCP service.
	; Assign a Local variable the socket and connect to a listening socket with the IP Address and Port specified.
	Local $iSocket = TCPConnect($sServerIP, $iPortOpener)
	$iPerc = 28
	If @error Then
		_addBallError(2)
		MsgBox($MB_ICONINFORMATION, "", "Client:" & @CRLF & "Could not connect to opener, Error code: " & @error & @CRLF & "The program will continue.", 5) ; The server is probably offline/port is not opened on the server.
	Else
		; Send the string "tata" to the server.
		TCPSend($iSocket, _Crypt_EncryptData($iProtocolVersion & @CR & "RUN" & $sToRun, $g_hOpenerKey, $CALG_USERKEY)) ;Encrypt password
		$iPerc = 32
		If @error Then
			_addBallError(2)
			MsgBox($MB_ICONINFORMATION, "", "Client:" & @CRLF & "Could not send the data to the opener, Error code: " & @error & @CRLF & "The program will continue.", 5)
		EndIf
		; Close the socket.
		TCPCloseSocket($iSocket)
		$iPerc = 36
	EndIf
	TCPShutdown() ; Close the TCP service.
EndIf
#EndRegion Open program

#Region Get user data
_MaxMinPerc(60, "Getting user info from Parsec.tv")
;Read cookies, cookies are stored encrypted
$cookies = IniRead($sConfigFile, "Parsec", "Cookie", "ERROR" & $iRandom & "ERROR") ;Read Cookies
If $cookies <> "ERROR" & $iRandom & "ERROR" Then $cookies = BinaryToString(_Crypt_DecryptData($cookies, $g_hKey, $CALG_USERKEY)) ;Decrypt Cookies
$sSessionId = IniRead($sConfigFile, "Parsec", "SessionId", "ERROR" & $iRandom & "ERROR") ;Read session_id
$iPerc = 64
;If no session_id is found, will try to login the user
If $sSessionId = "ERROR" & $iRandom & "ERROR" Then
	$oHTTP = ObjCreate("winhttp.winhttprequest.5.1")
	$oHTTP.Open("POST", "https://parsec.tv/ui/auth", False)
	$oHTTP.SetRequestHeader("Content-Type", "application/json; charset=UTF-8")
	$oHTTP.Send('{"email":"' & $sCorreo & '","password":"' & $sPass & '"}') ;Tell parsec team that this is a security problem, the password is sended in plain text!!!
	$iPerc = 68
	$userInfo = $oHTTP.ResponseText
	If $oHTTP.Status = 400 Then ;The server don't recognice the user or the password
		_addBallError(3)
		;Show the message from the server
		$aData = StringRegExp($userInfo, '"(.[^"]*)": ?"(.[^"]*)"', 4)
		$aPropiedades = $aData[0]
		MsgBox($MB_ICONERROR, $aPropiedades[1], $aPropiedades[2] & @CRLF & @CRLF & "Exiting...")
		;Delete user, pass and cookies from Config file
		IniDelete($sConfigFile, "Parsec")
		Exit
	EndIf
	$iPerc = 72
	;Get the cookies from the response, this will authenticate the user later
	$HeaderResponses = $oHTTP.GetAllResponseHeaders()
	$array = StringRegExp($HeaderResponses, 'Set-Cookie: (.+)\r\n', 3)
	$cookies = ''
	;Delete things that we don't need on the cookies
	For $i = 0 To UBound($array) - 1
		$cookies = $array[$i] & ';'
		$cookies = StringRegExpReplace($cookies, "( path| domain| expires)=[^;]+", "")
		$cookies = StringRegExpReplace($cookies, " HttpOnly", "")
		$cookies = StringRegExpReplace($cookies, "[;]{2,}", ";")
	Next
	$iPerc = 76
	;cookies is stored encripted
	$bEncrypted = _Crypt_EncryptData($cookies, $g_hKey, $CALG_USERKEY)
	IniWrite($sConfigFile, "Parsec", "Cookie", $bEncrypted) ;Write cookies in config file
	;Get the session_id from the user info of parsec.tv
	$aData = StringRegExp($userInfo, '"(.[^"]*)": ?"(.[^"]*)"', 4)
	For $i = 0 To UBound($aData) - 1
		$asPropiedades = $aData[$i]
		If $asPropiedades[1] = "session_id" Then
			$sSessionId = $asPropiedades[2]
			;session_id is stored encripted
			$bEncrypted = _Crypt_EncryptData($sSessionId, $g_hKey, $CALG_USERKEY)
			IniWrite($sConfigFile, "Parsec", "SessionId", $bEncrypted) ;Write session_id on config file
			ExitLoop
		EndIf
	Next
	$iPerc = 80
Else ;If can read session_id
	;session_id is stored encripted
	$sSessionId = BinaryToString(_Crypt_DecryptData($sSessionId, $g_hKey, $CALG_USERKEY)) ;Read session_id from config file
EndIf
#EndRegion Get user data

#Region Get servers list and Wait for server on parsec
_MaxMinPerc(80, "Waiting for connection")
$sInstanceID = ''
;Give the server some time to connect to parsec only if we did the WoL
If $bDidWoL Then
	$hTimer = TimerInit()
	Do
		Sleep(100)
		$iPerc += ($iMaxPerc - $iMinPerc) / ($iServerConnectingTime / 100)
	Until TimerDiff($hTimer) > $iServerConnectingTime
Else ;If we didn't wake the server, get the server list from parsec.tv,
	$iPerc = 65
	$serversInfo = _RequestServerList($cookies)
	$iPerc = 70
	$sInstanceID = _AnalyzeServerList($serversInfo, $sServerName)
	If $sInstanceID <> '' Then $iPerc = 75
EndIf
_MaxMinPerc(100, "Getting servers list")
;Get the server list if we still don't know the instance_id, get the server list again, if $sServerName if there, get the instance_id, if not, get the list every 1 sec until $sServerName is on the list or Timeout
If $sInstanceID = '' Then
	$hTimer = TimerInit()
	$bFirst = True
	Do
		If Not $bFirst Then Sleep(1000) ;Wait 1 second if this is not the first request, this way we don't colapse the Parsec.tv servers
		$iPerc += ($iMaxPerc - $iMinPerc) / ($MaxParsecTimeout / 1000)
		$serversInfo = _RequestServerList($cookies)
		$sInstanceID = _AnalyzeServerList($serversInfo, $sServerName)
		$bFirst = False
	Until $sInstanceID <> '' Or TimerDiff($hTimer) > $MaxParsecTimeout
EndIf
;If we are outside the loop and there is not instance_id, the timeout was reached.
If $sInstanceID = '' Then
	_addBallError(5)
	MsgBox($MB_ICONERROR, '', "MaxParsecTimeout exceded, " & $sServerName & " isn't on servers list" & @CRLF & "Exiting...")
	Exit
EndIf
#EndRegion Get servers list and Wait for server on parsec
;This is a workaround for a bug (if the client.exe is running, the url doesn't work)
$aServerData = StringRegExp($serversInfo, '{(.[^{}]*)}', 3)
For $j = 0 To UBound($aServerData) - 1
	$sInstanceIDProp = -1
	$sNameProp = ''
	$aData = StringRegExp($aServerData[$j], '"(.[^"]*)": ?"(.[^"]*)"', 4)
	;Search for the name and instance_id
	For $i = 0 To UBound($aData) - 1
		$asPropiedades = $aData[$i]
		If $asPropiedades[1] = "name" Then
			$sNameProp = $asPropiedades[2]
		ElseIf $asPropiedades[1] = "instance_id" Then
			$sInstanceIDProp = $asPropiedades[2]
		EndIf
	Next
	;If the server name is the same that the server that we are waiting, we save the instance_id and continue
	If $sNameProp = @ComputerName Then
		$sLoadingText = "Closing Parsec client"
		ProcessClose("client.exe") ;Hope no other process is named client.exe
		ExitLoop
	EndIf
Next
_MaxMinPerc(100, "Parsec-ing to " & $sServerName & "!")
;With the instance_id and the session_id construct a parsec url
$sUrl = "parsec:server_instance_id=" & $sInstanceID & ":session_id=" & $sSessionId
;Check that Parsec client isn't running, can't open the url if the client is running (the url gives focus to Parsec client window, if it's on the tray, it doesn't did nothing.)
;Open the parsec url, this will lunch the client.exe in the same way it's launched by Parsec.tv
ShellExecute($sUrl)
;wait until the parsec client is showing the remote pc
WinWait("[Title:Parsec Game Window; Class:SDL_app]")
;close all, exit
Close()
