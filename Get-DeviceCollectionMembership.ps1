#must have config mgr client installed. 
#this is meant for powershell x86

$siteserver = "DEGDWA59.deluxe.com"

import-module 'C:\Program Files (x86)\ConfigMgrConsole\bin\ConfigurationManager.psd1' -force
if ((get-psdrive DLX -erroraction SilentlyContinue | measure).Count -ne 1) {
new-psdrive -Name "DLX" -PSProvider "AdminUI.PS.Provider\CMSite" -Root $siteserver
}
cd DLX:
write-host "Enter your hostname or search string.  i.e. %dapp-uat% or *dapp-uat*"
$machineQuery = read-host -Prompt "Hostname of the machine you want collection info on "
$machineQuery = $machineQuery.Replace("*","%")
$machines = gwmi -Namespace root\sms\site_DLX -query "SELECT * FROM SMS_R_SYSTEM WHERE name like '$machineQuery'" -ComputerName degpwa59
if($machines)
{
    #get all the collections - this gets all collections
    $collections = Get-CMDeviceCollection

    foreach($machine in $machines)
    {
        $hostname = $machine.name
        write-host $hostname -foreground Yellow
        foreach($coll in $collections)
        {
            $CollectionID = $coll.CollectionID
            $device = Get-CMDevice -CollectionId $CollectionId -Name $hostname 
            if($device)
            {
                $CollectionName = $coll.Name
                write-host $CollectionName -ForegroundColor Cyan
                $deployments = Get-CMDeployment -CollectionName $CollectionName
                if($deployments) { write-host "`tDeployments" -ForegroundColor Green}
                foreach ($deployment in $deployments)
                {
                    $softwareName = $deployment.SoftwareName
                    write-host `t$softwarename
                }
            }
        }
    }
}
else
{
    Write-host "Invalid hostname"
}

