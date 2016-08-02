#must have config mgr client installed. 
#this is meant for powershell x86

import-module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1' -force
if ((get-psdrive DLX -erroraction SilentlyContinue | measure).Count -ne 1) {
new-psdrive -Name "DLX" -PSProvider "AdminUI.PS.Provider\CMSite" -Root "DEGPWA59.Deluxe.com"
}

#get the package ID you are looking for.

cd DLX:

$packageName = "PROD - We"
$DPGroups = Get-CMDistributionPointGroup
$applications = Get-CMApplication | where-object {$_.LocalizedDisplayName -like "*$packageName*"}
foreach($app in $applications)
{
    Write-Host $app.LocalizedDisplayName
    $PackageId = $application.PackageID
    foreach($DPgroup in $DPGroups)
    {
        $DistributionPointGroup = $dpGroup.name
        $DPGroupQuery = Get-WmiObject -ComputerName DEGPWA59 -Namespace "Root\SMS\Site_DLX" -Class SMS_DistributionPointGroup -Filter "Name='$DistributionPointGroup'"
        $DPGroupQuery.AddPackages($PackageID) | out-null
        $dpgroupName = $dpgroup.name
        write-host "Distributed to $DPgroupname"
    }
}