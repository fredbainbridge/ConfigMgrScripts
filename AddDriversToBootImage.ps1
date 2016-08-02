#import drivers ID into x64 boot image
$SiteServer = "educat-sccm-01.business.mpls.k12.mn.us"
$SiteCode = "MPS"
#$BootImages = "MPS00163", "MPS00164"
$BootImages =  "MPS00163"

$drivers = Get-Content .\DriverIDsX64.txt

Import-Module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1') -Verbose:$false
Set-Location -Path $SiteCode`:

$drivers | ForEach-Object {  #all the drivers
    
    $DriverCI_ID = $PSItem
    write-host $PSItem

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
$BootImageQuery.RefreshPkgSource()

