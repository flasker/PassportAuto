#include <File.au3>
#include <GuiConstants.au3>

; Search for "pass.dat"; if not exists, create an empty file
; passwords saved as: www.url.com:::username:::password:::tabn1:::tabn2:::tabn3:::ifverify
; 3 file for chrome, firefox and IE; browsername + _pass.dat
Global $browsers = StringSplit("ch;ff;ie", ";")
For $i = 0 To UBound($browsers) - 1
	NewIfNone("./" & $browsers[$i] & "_pass.dat")
Next

; When hotkey pressed, get the window info and search in password array;
; if found, send username and password and enter;
; else ask for creating new term
; todo: check for verification code
HotKeySet("+p", "SendNamePass") ; shift-p

; stop code; only for test
HotKeySet("{ESC}", "Terminate")
Func Terminate()
    Exit
EndFunc

; start the loop
While 1
    Sleep(100)
WEnd

; Func_main functionP
; 1. get current page url; if none url, do normal shift-p
; 2. check if name and password input forms exist; if none, do normal shift-p
; 3. if current url in save file; if none, prompt to ask for setting new;
;    also send to page
; 4. get saved name and password and send them to page
Func SendNamePass()
	;; MsgBox(0, "test", "hotkey pressed")
	; check if web browser is currently active;
	; if not, send normal shift-p
	Local $browser
	; check browser and get file
	If WinActive("[CLASS:Chrome_WidgetWin_1]") Then
		$browser = "ch"
	ElseIf WinActive("[CLASS:MozillaWindowClass]") Then
		$browser = "ff"
	ElseIf WinActive("[CLASS:IEFrame]")) Then
		$browser = "ie"
	Else
		;; MsgBox(0, "test", "browser not active")
		HotKeySet("+p") ; unbind the hotkey
		Send("+p")
		HotKeySet("+p", "SendNamePass") ; bind again
		Return
	EndIf

	Global $passfile = "./" & $browser & "_pass.dat"
	; Open passfile to array
	Global $passArray = FileReadToArray($passfile)
	;; MsgBox(0, "pass num", UBound($passArray))
	;; _ArrayDisplay($passArray)

	; get current url
	Send("{F6}")
	Send("^c")
	Send("{F6}")
	Local $URL = ClipGet()

	; search url in passfile
	Local $infos = TraverseRun($passArray, "IfSubstring", $URL)
	If Not $infos Then ; not found, then create a new record
		;; MsgBox(0, "test", "create new record")
		$infos = NewTerm($URL)
	EndIf
	If $infos Then ; get username and password
		Local $infoArray = StringSplit($infos, ":::", $STR_ENTIRESPLIT)
		;; _ArrayDisplay($infoArray)
		Local $username = $infoArray[2]
		Local $password = $infoArray[3]
		Local $tabn1 = $infoArray[4]
		Local $tabn2 = $infoArray[5]
		Local $tabn3 = $infoArray[6]
		Local $ifverify = $infoArray[7]
	Else ; still nothing, then quit
		;; MsgBox(0, "test", "abort")
		Return
	EndIf

	Send("{SHIFTDOWN}{SHIFTUP}") ; incase shift is pressed
	; send tabs to focus username input field
	Send("{TAB " & $tabn1 & "}")
	; send username and password to input forms
	Send($username, $SEND_RAW)
	Send("{TAB " & $tabn2 & "}")
	Send($password, $SEND_RAW)
	Send("{TAB " & $tabn3 & "}")
	If ifverify = "0" Then
		Send("{ENTER}")
	EndIf
EndFunc

; Func_gui asks for new name and password
Func NewTerm($url)
	Local $cancelled = 0

	Local $newterm = GUICreate("Input", 240, 250)
	GUICtrlCreateLabel("Input username and password for URL: " & @CRLF & "  " & $url, 20, 20)

	; show url, input areas
	GUICtrlCreateLabel("", 15, 90, 210, 2, $SS_SUNKEN)
	GUICtrlCreateLabel("Username: ", 20, 100)
	Local $usernameCtrl = GUICtrlCreateInput("username", 20, 115, 200, 20)
	GUICtrlCreateLabel("Password: ", 20, 140)
	Local $passwordCtrl = GUICtrlCreateInput("password", 20, 155, 180, 20, BitOR($ES_PASSWORD, $ES_AUTOHSCROLL))
	Local $showHideButton = GUICtrlCreateButton("*", 200, 155, 20, 20)

	; buttons
	Local $okButton = GUICtrlCreateButton("OK", 40, 200, 55, 30)
	Local $cancelButton = GUICtrlCreateButton("CANCEL", 135, 200, 55, 30)

	GUISetState(@SW_SHOW, $newterm)

	$DefaultPassChar = GUICtrlSendMsg($passwordCtrl, $EM_GETPASSWORDCHAR, 0, 0)

	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $cancelButton
				;; MsgBox(0, "quit pressed", "quit")
				$cancelled = 1
				ExitLoop

			; show and hide password
			Case $GUI_EVENT_PRIMARYDOWN
				$cursorInfo = GUIGetCursorInfo($newterm)
				If $cursorInfo[4] = $showHideButton Then
					GUICtrlSendMsg($passwordCtrl, $EM_SETPASSWORDCHAR, 0, 0)
					GUICtrlSetState($passwordCtrl, $GUI_FOCUS)
				EndIf
			Case $GUI_EVENT_PRIMARYUP
				$cursorInfo = GUIGetCursorInfo($newterm)
				If $cursorInfo[4] = $showHideButton Then
					GUICtrlSendMsg($passwordCtrl, $EM_SETPASSWORDCHAR, $DefaultPassChar, 0)
					GUICtrlSetState($passwordCtrl, $GUI_FOCUS)
				EndIf

			; ok button
			Case $okButton
				;; MsgBox(0, "ok pressed", "ok")
				Local $infos = $url & ":::" & GUICtrlRead($usernameCtrl) & ":::" & GUICtrlRead($passwordCtrl)
				_ArrayAdd($passArray, $infos)
				;; _ArrayDisplay($passArray)
				_FileWriteFromArray($passfile, $passArray)
				ExitLoop
		EndSwitch
	WEnd

	GUIDelete($newterm)

	If Not $cancelled Then
		Return $infos
	EndIf

EndFunc

; Func_check if substring in string; return string if true
; default returns 0
Func IfSubstring($string, $substring)
	If StringInStr($string, $substring) Then
		Return $string
	EndIf
EndFunc

; Func_traverse given array and run callback for every element
; the callback must have return value
Func TraverseRun(Const $array0, Const $callback, $param1)
	For $i = 0 To UBound($array0) - 1
		Local $v = Call($callback, $array0[$i], $param1)
		If $v Then ; stop and return if callback returns some value
			Return $v
		EndIf
	Next
EndFunc

; Func_create new file if not exists
Func NewIfNone(Const $filename)
	Local $isFileExists = FileExists($filename)
	If Not $isFileExists Then
		Local $emptyArray[1]
		_FileCreate($filename)
		_FileWriteFromArray($filename, $emptyArray)
	EndIf
	Return $filename
EndFunc
