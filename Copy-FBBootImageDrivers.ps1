#Copy drivers from one boot image to another
#This is useful for ADK upgrades.
Function Copy-FBBootImageDrivers {
[CmdletBinding()]
param (
    $SiteServer = "siteserver.domain.local",
    $SiteCode = "XXX",
    $SourceBootImageID = "XXX00163",
    [string[]]$DestinationBootImages =  "XXX0017E"
)

Import-Module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1') -Verbose:$false
Set-Location -Path $SiteCode`:

(Get-CMBootImage -Id $SourceBootImageID | select ReferencedDrivers).ReferencedDrivers.ID | ForEach-Object {  
    
    $DriverCI_ID = $PSItem
    write-verbose "Found driverID: $PSItem"

    $BootImages | ForEach-Object { #all the bootimages
        $BootImagePackageID = $PSITEM
        #Get the Boot image and the Driver
        $BootImageQuery = Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -Class SMS_BootImagePackage -Filter "PackageID='$BootImagePackageID'"
        $DriverQuery = Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -Class SMS_Driver -Filter "CI_ID='$DriverCI_ID'"
    
        $BootImageQuery.Get()
        $NewBootImageDriver = ([WMIClass]"\\$SiteServer\root\SMS\Site_$($SiteCode):SMS_Driver_Details").CreateInstance()
        $NewBootImageDriver.ID = $DriverCI_ID
        $NewBootImageDriver.SourcePath = $DriverQuery.ContentSourcePath
        
        #Add the driver details
        $BootImageQuery.ReferencedDrivers += $NewBootImageDriver.psobject.baseobject
        $BootImageQuery.Put()
        #$BootImageQuery.RefreshPkgSource()
    } 
}

$DestinationBootImages | ForEach-Object { #all the bootimages
    $BootImageQuery = Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -Class SMS_BootImagePackage -Filter "PackageID='$PSItem'"
    $BootImageQuery.RefreshPkgSource()
}
}