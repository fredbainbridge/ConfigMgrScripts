'tester
On Error Resume Next
set env = CreateObject("Microsoft.SMS.TSEnvironment")
'comment this line out before running in a ConfigMgr Task Sequence
'set env = CreateObject("Scripting.Dictionary")

set oTSProgressUI = CreateObject("Microsoft.SMS.TSProgressUI")
oTSProgressUI.CloseProgressDialog()

On Error GoTo 0

Dim Message 
Message = ""


if(env("_SMSTSBootUEFI") = "false") Then
	Message = "This device has been reconfigured to use UEFI but is currently in Legacy mode.  Please restart the task sequence." + vbCr + vbLf
End If
if(env("CORRECTPW") = "0") Then
	Message = "An unexpected system password was found on this device.  Please rectify this in the firmware and retry.  Cannot continue." + vbCr + vbLf
End If

MsgBox Message & chr(13) & chr(13) & "Press OK to continue.",0, "Warning"

Wscript.quit 1