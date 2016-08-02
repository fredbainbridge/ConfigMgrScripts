#must have config mgr client installed. 
#this is meant for powershell x86

import-module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1' -force
if ((get-psdrive DLX -erroraction SilentlyContinue | measure).Count -ne 1) {
new-psdrive -Name "DLX" -PSProvider "AdminUI.PS.Provider\CMSite" -Root "DEGPWA59.Deluxe.com"
}

#get the package ID you are looking for.

cd DLX:

get-cmapplication | select-object localizeddisplayname, ci_uniqueid