function DistributeApplication
{
    [CmdletBinding()]
    param(
        [string[]]$DPGroupNames = "Shoreview DP Group",
        [Parameter( Mandatory = $true )]
        [string]$PackageID,
        [string]$SiteServer = "NM-CM12",
        [string]$SiteCode = "PS1"
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
        $DPGroupQuery = Get-WmiObject -ComputerName $SiteServer -Namespace "Root\SMS\Site_$SiteCode" -Class SMS_DistributionPointGroup -Filter "Name='$dpgroupname'"
        $DPGroupQuery.AddPackages($PackageID) | out-null
        (Get-Wmiobject -Namespace "root\SMS\Site_$sitecode" -Class SMS_ContentPackage -filter "Name='$appName'").Commit() 
        write-verbose "Distributed to $DPgroupname"
    }
}

$sitecode = "DLX"
#Connect to the Site Server
if(!(Get-Module ConfigurationManager)){
    import-module 'C:\Program Files (x86)\ConfigMgrConsole\bin\ConfigurationManager.psd1' -force
}
if ((get-psdrive DLX -erroraction SilentlyContinue | measure).Count -ne 1) {
    new-psdrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer
}
set-location $sitecode`:\

#get available distribution groups
$DPS = @()
Get-CMDistributionPointGroup | foreach-object { $DPS +=  [string]$_.Name}  

#get all applications and distribute to all groups.
<#
get-cmapplication | foreach-object  { 
    $packageName = $_.LocalizedDisplayName
    write-host "Application:  $packageName"
    DistributeApplication -DPGroupNames $DPS -PackageID $_.PackageID -Verbose 
} 
#>

#distribute a single application
<#
get-cmapplication -name "PROD - Thomson AutoAudit 5.7" | foreach-object  { 
    $packageName = $_.LocalizedDisplayName
    write-host "Application:  $packageName"
    DistributeApplication -DPGroupNames $DPS -PackageID $_.PackageID -Verbose 
} 
#>


    