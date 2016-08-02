$sitecode = "DLX"

function DistributeApplication
{
    [CmdletBinding()]
    param(
        [string[]]$DPGroupNames = "Omaha DP Group",
        [Parameter( Mandatory = $true )]
        [string]$PackageID
    )
    <# DP groups you can use
    Streetsboro DP Group                                                                                                                                                                                                  
    Maryville DP Group                                                                                                                                                                                                    
    Mountain Lakes DP Group                                                                                                                                                                                               
    Omaha DP Group                                                                                                                                                                                                        
    Lansdale DP Group                                                                                                                                                                                                     
    Groton DP Group                                                                                                                                                                                                       
    Midland DP Group                                                                                                                                                                                                      
    Antelope Valley DP Group                                                                                                                                                                                              
    Shoreview DP Group                                                                                                                                                                                                    
    Salt Lake DP Group                                                                                                                                                                                                    
    Colorado Springs DP Group                                                                                                                                                                                             
    Kansas City DP Group                                                                                                                                                                                                  
    Townsend DP Group 
    #>

    foreach($DPGroupName in $DPGroupNames){
        $DPGroupQuery = Get-WmiObject -ComputerName DEGPWA59 -Namespace "Root\SMS\Site_DLX" -Class SMS_DistributionPointGroup -Filter "Name='$dpgroupname'"
        $DPGroupQuery.AddPackages($PackageID) | out-null
        write-verbose "Distributed to $DPgroupname"
    }
}

#Connect to the Site Server
if(!(Get-Module ConfigurationManager)){
    import-module 'C:\Program Files (x86)\ConfigMgrConsole\bin\ConfigurationManager.psd1' -force
}
if ((get-psdrive DLX -erroraction SilentlyContinue | measure).Count -ne 1) {
    new-psdrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer
}

$sourceFolder = '\\deluxe.com\fileshare\Data\MediaLib\3Image Applications\VC Runtimes'
$exes = Get-ChildItem -Path $sourceFolder -Recurse -Filter *.exe
set-location $SiteCode`:\

if($exes.count -gt 0){
    foreach($exe in $exes){
        $packageName = $exe.DirectoryName.Substring($exe.DirectoryName.LastIndexOf('\')+1)
        $packagePath = $exe.DirectoryName
        $commandLine = $exe.Name + " /qn"
        new-cmPackage -Name $packageName -Description "DLX Image App" -Path $packagePath
        New-CMProgram -PackageName $packageName -StandardProgramName "Install" -CommandLine $commandLine -RunType Hidden -ProgramRunType WhetherOrNotUserIsLoggedOn 
        $packageID = (Get-CMPackage -Name $packageName | select PackageID).PackageID
        if($packageID){
            DistributeApplication -PackageID $PackageId -Verbose
        }
    #New-CMProgram -PackageName "test" -StandardProgramName SPM -CommandLine "RunMe" -WorkingDirectory "C:\temp" -RunType Hidden -ProgramRunType OnlyWhenNoUserIsLoggedOn -DiskSpaceRequirement 100 -DiskSpaceUnit GB -Duration 100 -DriveMo
    }
    
}