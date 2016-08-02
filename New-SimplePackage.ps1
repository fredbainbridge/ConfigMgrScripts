import-module 'C:\Program Files (x86)\ConfigMgrConsole\bin\ConfigurationManager.psd1' -force
if ((get-psdrive DLX -erroraction SilentlyContinue | measure).Count -ne 1) {
new-psdrive -Name "DLX" -PSProvider "AdminUI.PS.Provider\CMSite" -Root "DEGDWA59.Deluxe.com"
}

function Add-SimplePackage{
    [CmdletBinding()]
    param(
        [string[]]$Packages,
        [string]$PackageNamePrefix="OSD",
        [string]$MediaLibPath="\\deluxe.com\fileshare\Data\MediaLib\1PCK Applications\1BaseApps",
        [string]$SiteCode = "DLX"
    )
     
    #get packages to be created -
    foreach($package in $packages){
        cd "$SiteCode`:"       
        $packageName = "$PackageNamePrefix - $package"
        if(Get-CMPackage -Name $packageName){ 
            Write-Verbose "Package already exists, skipping"
        } #end package exist if
        else
        {
            $expectedLocation = "$MediaLibPath\$package\MSI"
            $installerLocation = "$expectedLocation+\INST.VBS"
            set-location $env:SystemDrive
            if(Test-Path $expectedLocation){
                if(test-path $installerLocation){
                    cd "$SiteCode`:"
                    New-CMPackage -Name $packageName -Description "Created from Add-SimplePackage" -Path $expectedLocation 

                    #67109024 -> this is what pkgsource should be set to.  
                    #create program
                    
                
                    New-CMProgram -PackageName $packageName -StandardProgramName "INST" -RunType Hidden -ProgramRunType WhetherOrNotUserIsLoggedOn -RunMode RunWithAdministrativeRights -CommandLine "INST.VBS"
                } #end if test installerlocation
                else{
                    Write-Verbose "Unable to find INST.VBS"
                }
            } #end if test expectedlocation
            else{
                Write-Verbose "Cannot find medialib path, skipping"
            } #end else for test expectedLocation
            
            
           #New-CMPackage -
        } #end package exist else
    } #end foreach package
}



#content location, program

Add-SimplePackage -Packages "Microsoft UE-V 2.0.319.0 with HotFix 1" -Verbose