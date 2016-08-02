$SiteCode = 'DLX'
$Computer = 'DEGPWA59'
$FolderName = '1_IMAGE'
$CollectionName = "DEV - Windows OS Build and Capture"

Import-Module (Join-Path (Split-Path $env:SMS_ADMIN_UI_PATH –parent) ConfigurationManager.psd1)

set-location ${SiteCode}:

$FolderObj = Get-WmiObject -Class SMS_ObjectContainerNode -Namespace "Root\SMS\Site_$SiteCode" -filter “Name='$FolderName' AND ObjectType=2” -ComputerName $Computer| foreach { $_.ContainerNodeID }

$count = 0
$CollectionVariables = @([WmiClass]"\\DEGPWA59\ROOT\SMS\SITE_DLX:SMS_CollectionVariable")
Get-WmiObject -Class SMS_ObjectContainerItem -Namespace Root\SMS\Site_$SiteCode -filter “ContainerNodeID='$FolderObj'” -ComputerName $Computer| ForEach-Object {
    $packageID = $_.InstanceKey
    #setpackage to install without deployment
    #$p = [WMIClass]"\\degpwa59\ROOT\SMS\SITE_DLX:SMS_Program"
    #$package = $p.createInstance()
    #$package.PackageID = $packageID
    #$package.site = "DLX"

    #$package.get()
    #$package = Get-CMPackage -Id $packageID
    Get-CMPackage -ID $_.InstanceKey | foreach { $_.Name }
    #create collection variables
    $collectionID = Get-CMDeviceCollection -Name $CollectionName | foreach{$_.CollectionID}
    $count++
    $VariableName = "APP" + ("{0:D3}" -f $count)
    
    $cv = [WmiClass]"\\DEGPWA59\ROOT\SMS\SITE_DLX:SMS_CollectionVariable"
    $collectionVariable = $cv.createinstance()    
    
    $collectionVariable.Name = $VariableName
    $collectionVariable.Value = $packageID + ":" + "Install"

    $CollectionVariables += $CollectionVariable
    
}

#update the collections variables on the specified collection.
$pc_class = [WmiClass]""
$pc_class.psbase.Path ="\\degpwa59\ROOT\SMS\SITE_DLX:SMS_CollectionSettings"
$CollectionObject = $pc_class.createInstance()

$CollectionObject.CollectionID = $collectionID
$CollectionObject.SourceSite = $SiteCode

$CollectionObject.Get()

$CollectionObject.CollectionVariables = $CollectionVariables

$CollectionObject.Put()