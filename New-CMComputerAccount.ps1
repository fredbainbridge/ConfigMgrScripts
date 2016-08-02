#example how to import machine account into a specific collection.
#thanks http://cm12sdk.net/?p=1078

Function New-CMComputerAccount
{
    [CmdletBinding()]
    Param(
         [Parameter(Mandatory=$True,HelpMessage="Please Enter Primary Server Site Server")]
                $SiteServer,
         [Parameter(Mandatory=$True,HelpMessage="Please Enter Primary Server Site code")]
                $SiteCode,
         [Parameter(Mandatory=$True,HelpMessage="Please Enter the Account name")]
                $ResourceName,
         [Parameter(Mandatory=$True,HelpMessage="Please Enter the Account MAC Address")]
                $MACAddress,
         [Parameter(Mandatory=$True,HelpMessage="Please Enter the collecton name")]
                $CollectionName,
         [Parameter(Mandatory=$False,HelpMessage="Refresh the collection membership after the device has been added")]
                $RefreshCollectionMembership=$False     
         )
 
 
    #Collection query
    $CollectionQuery = Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name='$CollectionName'"
 
    #New computer account information
    $WMIConnection = ([WMIClass]"\\$SiteServer\root\SMS\Site_$($SiteCode):SMS_Site")
        $NewEntry = $WMIConnection.psbase.GetMethodParameters("ImportMachineEntry")
        $NewEntry.MACAddress = $MACAddress
        $NewEntry.NetbiosName = $ResourceName
        $NewEntry.OverwriteExistingRecord = $True
    $Resource = $WMIConnection.psbase.InvokeMethod("ImportMachineEntry",$NewEntry,$null)
 
    #Create the Direct MemberShip Rule
    $NewRule = ([WMIClass]"\\$SiteServer\root\SMS\Site_$($SiteCode):SMS_CollectionRuleDirect").CreateInstance()
    $NewRule.ResourceClassName = "SMS_R_SYSTEM"
    $NewRule.ResourceID = $Resource.ResourceID
    $NewRule.Rulename = $ResourceName
 
    #Add the newly created machine to collection
    $CollectionQuery.AddMemberShipRule($NewRule)
    if($RefreshCollectionMembership){
        $CollectionQuery.RequestRefresh();
    }
}
<#
#import accounts

$macs = Import-Csv C:\temp\MacAddresses.csv  #(the format must be 11:22:33:44:55:66)
$counter = 0

foreach($mac in $macs){
    $counter++
    $mac = $mac.MAC
    New-CMComputerAccount -SiteServer "DEGPWA59.deluxe.com" -SiteCode "DLX" -ResourceName "grotonT620$counter" -MACAddress $mac -CollectionName "PROD - GROTON - Windows 7 x86 SP1 Embedded" -Verbose
}
#>
#Connect to the Site Server
$SiteCode = "DLX"
if(!(Get-Module ConfigurationManager)){
    import-module 'C:\Program Files (x86)\ConfigMgrConsole\bin\ConfigurationManager.psd1' -force
}
if ((get-psdrive DLX -erroraction SilentlyContinue | measure).Count -ne 1) {
    new-psdrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer
}
#stand alone usage

set-location $sitecode`:\
$MAC = "00:15:5D:65:59:3E" #SCCM12TST1
$MAC = $MAC.Replace("-",":")
$ResourceName = "DSVDWA906"
#$ResourceName = "DESQLDB01"

$CollectionName = "SBDC - Managed Servers (New Server Build)"
#$CollectionName = "PROD - Windows OS Build and Capture"
#$CollectionName = "WKS - LAB - SCCM12 Clients"
$SiteServer = "DEGPWA59.deluxe.com"
if(Get-CMDevice -Name $ResourceName){
    Remove-CMDevice -DeviceName $ResourceName -verbose
}
New-CMComputerAccount -SiteServer $SiteServer -SiteCode $SiteCode -ResourceName $ResourceName -MACAddress $MAC -CollectionName $CollectionName -RefreshCollectionMembership $true -Verbose