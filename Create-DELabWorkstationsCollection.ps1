<#
D9K1WDP1
D2T9R9Y1
D55PRBY1
D7RGGWZ1
D9XD8H02
D3WXFTY1
DG35MNX1
DG68SBW1
D6T440P1
DCCRNGV1
D305YBS1
DB6N4TY1
D5P4D5L1
D5V61ZC1
D7B4R9F1
DJKJFTJ1
#>
<# onenote:///\\deluxe.com\fileshare\Data\ITInfArch\Desktop%20Technologies\OneNote%20Notebooks\Desktop%20Engineering\Administrative.one#DE%20LAB%20DEVICES&section-id={490E7571-1639-42AF-B74B-77103AAB3BD8}&page-id={101CC341-EF97-4D63-9E8A-632FE173745E}&end #>

#DELab Collection Creation
$sitecode = "DLX"
$siteserver = "degpwa59.deluxe.com"

import-module 'C:\Program Files (x86)\ConfigMgrConsole\bin\ConfigurationManager.psd1' -force
if ((get-psdrive $sitecode -erroraction SilentlyContinue | measure).Count -ne 1) 
{
    new-psdrive -Name "DLX" -PSProvider "AdminUI.PS.Provider\CMSite" -Root "DEGDWA59.Deluxe.com"
    set-location $sitecode`:
}

$CollectionName = "DE - Lab Workstation Devices"
$LimitingCollection = "All Windows Workstation Systems"

if(-not (Get-CMDeviceCollection -Name $CollectionName))
{
    if($LimitingCollectionID = (Get-CMDeviceCollection -Name $LimitingCollection -Verbose).CollectionID)
    {        
        New-CMDeviceCollection -Name $CollectionName -LimitingCollectionId $LimitingCollectionID
    }
}

get-content C:\temp\DeLabDevices.txt | ForEach-Object {
    if(($ResourceID = (Get-CMDevice -Name $PSItem).ResourceID))
    {
        Add-CMDeviceCollectionDirectMembershipRule -CollectionName $CollectionName -ResourceId $ResourceID 
    }
}