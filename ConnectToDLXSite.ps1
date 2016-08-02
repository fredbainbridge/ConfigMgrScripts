#must have config mgr client installed. 
#this is meant for powershell x86
$sitecode = "DLX"
$siteserver = "degpwa59.deluxe.com"

import-module 'C:\Program Files (x86)\ConfigMgrConsole\bin\ConfigurationManager.psd1' -force
if ((get-psdrive $sitecode -erroraction SilentlyContinue | measure).Count -ne 1) {
    new-psdrive -Name "DLX" -PSProvider "AdminUI.PS.Provider\CMSite" -Root "DEGDWA59.Deluxe.com"
    set-location $sitecode`:
}


