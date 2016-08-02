function Get-MsiDatabaseVersion {
    param (
        [IO.FileInfo] $FilePath
    )

    try {
        $windowsInstaller = New-Object -com WindowsInstaller.Installer

        $database = $windowsInstaller.GetType().InvokeMember(
                "OpenDatabase", "InvokeMethod", $Null, 
                $windowsInstaller, @($FilePath.FullName, 0)
            )

        $q = "SELECT Value FROM Property WHERE Property = 'ProductVersion'"
        $View = $database.GetType().InvokeMember(
                "OpenView", "InvokeMethod", $Null, $database, ($q)
            )

        $View.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $View, $Null)

        $record = $View.GetType().InvokeMember(
                "Fetch", "InvokeMethod", $Null, $View, $Null
            )

        $productVersion = $record.GetType().InvokeMember(
                "StringData", "GetProperty", $Null, $record, 1
            )

        return $productVersion

    } catch {
        throw "Failed to get MSI file version the error was: {0}." -f $_
    }
}

function Get-MsiDatabaseCode {
    param (
        [IO.FileInfo] $FilePath
    )

    try {
        $windowsInstaller = New-Object -com WindowsInstaller.Installer

        $database = $windowsInstaller.GetType().InvokeMember(
                "OpenDatabase", "InvokeMethod", $Null, 
                $windowsInstaller, @($FilePath.FullName, 0)
            )

        $q = "SELECT Value FROM Property WHERE Property = 'ProductCode'"
        $View = $database.GetType().InvokeMember(
                "OpenView", "InvokeMethod", $Null, $database, ($q)
            )

        $View.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $View, $Null)

        $record = $View.GetType().InvokeMember(
                "Fetch", "InvokeMethod", $Null, $View, $Null
            )

        $productVersion = $record.GetType().InvokeMember(
                "StringData", "GetProperty", $Null, $record, 1
            )

        return $productVersion

    } catch {
        throw "Failed to get MSI file version the error was: {0}." -f $_
    }
}

function New-DLXCM2012Application{
  <#
  .SYNOPSIS
  This will add an application to a ConfigMgr 2012 installation
  .DESCRIPTION
  You can specify a medialib location or application tracking item
  .EXAMPLE
  New-DLXCM2012Application -some stuff
  .EXAMPLE
  New-DLXCM2012Application -some other stuff
  .PARAMETER computername
  The computer name to query. Just one.
  .PARAMETER logname
  The name of a file to write failed computer names to. Defaults to errors.txt.
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true)]
    [string]$Name,
    [Parameter(Mandatory=$false)]
    [string]$SiteCode = "DLX",
    [Parameter(Mandatory=$false,
    ValueFromPipeline=$false)]
    [string]$SiteServer = "DEGPWA59.Deluxe.com",
    [Parameter(Mandatory=$false)]
    [string]$UseAppTracking = $true,
    [Parameter(Mandatory=$false)]
    [string]$ApplicationTrackingURI = "http://inside.deluxe.com/it/home/infrastructure-and-operations/client/DeskArchEng/_vti_bin/Lists.asmx?wsdl",
    [Parameter(Mandatory=$false)]
    [string]$ApplicationTrackingListName = "Application Tracking"
  )

  begin
  {
    #Connect to the Site Server
    if(!(Get-Module ConfigurationManager)){
        import-module 'C:\Program Files (x86)\ConfigMgrConsole\bin\ConfigurationManager.psd1' -force
    }
    if ((get-psdrive DLX -erroraction SilentlyContinue | measure).Count -ne 1) {
        new-psdrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer
    }
    set-location $sitecode`:\
  }

  process
  {
    #get categories
    $CMCategories = Get-CMCategory -CategoryType AppCategories |select-object LocalizedCategoryInstanceName

    if($UseAppTracking){
        #connect to webservice
        $service = New-WebServiceProxy -Uri $ApplicationTrackingURI  -Namespace SpWs -UseDefaultCredential
        #This sets up the XML to use the webservice aka builds the sharepoint query
        $xmlDoc = new-object System.Xml.XmlDocument            
        $query = $xmlDoc.CreateElement("Query")            
        $viewFields = $xmlDoc.CreateElement("ViewFields")            
        $viewFields.set_InnerXML('<FieldRef Name="ID"/><FieldRef Name="Title"/><FieldRef Name="Demand_x0020_Status"/><FieldRef Name="Distribution_x0020_Scope_x0020__"/><FieldRef Name="AppCategory"/><FieldRef Name="Media_x0020_Lib_x0020_code_x0020"/><FieldRef Name="Application_x0020_Package_x0020_"/><FieldRef Name="DAPP_x0020_DEV_x0020_code_x0020_"/><FieldRef Name="Distribution_x0020_Scope_x0020__"/><FieldRef Name="Vendor"/><FieldRef Name="Sft_x0020_Ver"/>')      
        $queryOptions = $xmlDoc.CreateElement("QueryOptions")            
        #clean for ampersands
        $name = $name.replace("&", "&amp;")
        write-verbose "Retreiving from App Tracking - $name"
        $query.set_InnerXml("<Where><Eq><FieldRef Name='Title'/><Value Type='Text'>$name</Value></Eq></Where>")
        $rowLimit = "2"
        $returnedApps = $service.GetListItems($ApplicationTrackingListName, "", $query, $viewFields, $rowLimit, $queryOptions, "")
        $today = get-date
        #are the correct number of applications(1) returned? 
        if($returnedApps.data.ItemCount -eq 1){        
            #gather deployment type details
            $AppTrackingLink = $ApplicationTrackingURI.replace("_vti_bin/Lists.asmx?wsdl","ApplTracking/DispForm.aspx?ID=") + $returnedApps.data.row.ows_ID ; Write-Verbose "Application Tracking link - $AppTrackingLink"
            Write-Verbose "SiteCode - $SiteCode"; Write-Verbose "SiteServer - $SiteServer" 
            #$GetIdentification = [WmiClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_Identification"
            #$ScopeID = "ScopeId_" + $GetIdentification.GetSiteID().SiteID -replace "{","" -replace "}",""
            
            $ApplicationSourcePath = $returnedApps.data.row.ows_Media_x0020_Lib_x0020_code_x0020; Write-Verbose "MediaLib Path - $ApplicationSourcePath"
            $ApplicationPublisher = $returnedApps.data.row.ows_Vendor; Write-Verbose "Publisher - $ApplicationPublisher"
            if($returnedApps.data.row.ows_Demand_x0020_Status -eq "3 Deploy"){
                $TitlePrefix = "PROD - "
            }
            if($returnedApps.data.row.ows_Demand_x0020_Status.toupper() -eq "2.5 SWD/SBDC"){
                $TitlePrefix = "PILOT - "
            }
            if($returnedApps.data.row.ows_Demand_x0020_Status.toupper() -eq "2.1.5 UAT PREP"){
                $TitlePrefix = "UAT - "
            }
            $ApplicationStatus = $returnedApps.data.row.ows_Demand_x0020_Status; write-verbose "Status - $ApplicationStatus"
            write-verbose "Title Prefix - $TitlePrefix"
            $ApplicationTitleNoPreFix = $returnedApps.data.row.ows_Title
            $ApplicationTitle = $TitlePrefix + $returnedApps.data.row.ows_Title; Write-Verbose "Title - $ApplicationTitle"
            $ApplicationVersion = $returnedApps.data.row.ows_Sft_x0020_Ver; Write-Verbose "Version - $ApplicationVersion"
            $ApplicationLanguage = (Get-Culture).Name
            $ApplicationDescription = "Imported from app tracking, $today"
            if(-not $returnedApps.data.row.ows_Application_x0020_Package_x0020_) {
                Write-Verbose "Application Package type not defined in sharepoint application tracking. Exitng..."
            }
            else{
                $ApplicationType = [string]($returnedApps.data.row.ows_Application_x0020_Package_x0020_).replace(";#",","); Write-Verbose "Application Type $ApplicationType"
                $ApplicationCategory = [string]($returnedApps.data.row.ows_AppCategory)
                $ApplicationScope = [string]$returnedApps.data.row.ows_Distribution_x0020_Scope_x0020__.replace(";#"," ").trim().replace(" ",","); write-Verbose "Application Scope - $ApplicationScope"
            
                #the following are discovered and defined below
                $DeploymentInstallCommandLine=""; $DeploymentUninstallCommandLine=""; $DeploymentInstallUseEnhanced = $true; $DeploymentProductGuid; $DeploymentProductVersion;
                #clean applicationType
                if($ApplicationType -eq ",MSI,WISE,"){ #remove WISE from the deployment type.
                    write-verbose "Remove Wise application type"
                    $ApplicationType = "MSI"
                }
                $applicationType = $applicationType.replace(",","")
                      
                if($ApplicationType -eq "MSI"){ #Find installer and uninstaller
                    if($ApplicationStatus.toupper() -eq "2.1.5 UAT PREP"){
                        $MSIInstallerPath = "\\dompwv01f\dappuat\$ApplicationTitleNoPreFix\MSI\"
                    }
                    else{
                    $MSIInstallerPath = "$ApplicationSourcePath\MSI\"
                }
                    #check for this stupid entry and replace the \ with ""
                                    if($MSIInstallerPath -eq "\\deluxe.com\fileshare\Data\MediaLib\1PCK Applications\3BusinessApps\2BAUApps\IBM AS/400 Client Access Express for Windows 4.4\MSI\") { 
                    $MSIInstallerPath = $MSIInstallerPath.Replace("/","")
                    Write-Verbose "Found bad As/400 entry, fixing medialib path -"
                    write-verbose "$MSIInstallerPath"                   
                }
                    write-verbose "Looking for *.vbs, *.bat in $MSIInstallerPath"
                    set-location c:
                    $vbsFiles = Get-ChildItem -Path $MSIInstallerPath* -Include *.vbs,*.bat
                    $options = @()
                    $instFound = $false; $uninstFound = $false; $count=0;
                
                    foreach($vbsFile in $vbsFiles){
                        $vbsFilename = $vbsfile.name
                                if($vbsFilename.tolower() -eq "inst.vbs"){
                        $instFound = $true
                    }
                                if($vbsFilename.tolower() -eq "uninst.vbs"){
                        $uninstFound = $true
                    }
                        $count++
                        $option = new-object System.Management.Automation.Host.ChoiceDescription $vbsFileName,$vbsFilename
                        write-verbose "Found option $vbsFileName"
                        $options+=($option)
                    }
                    if($count -eq 2 -and $instFound -and $uninstFound){
                        write-verbose "Automatically selecting installers"
                        $DeploymentInstallCommandLine = "inst.vbs"; Write-Verbose "Install Command - $DeploymentInstallCommandLine"
                        $DeploymentUninstallCommandLine = "uninst.vbs"; Write-Verbose "Uninstall Command - $DeploymentUnInstallCommandLine"
                    }
                    else{
                        if($options.Count -eq 0) {
                            write-verbose "No Installer files found."
                            #found no MSI, manual intervention needed
                            $title = "Define installer?"
                            $Message = "No install files found, define installers?"
                            $yes = new-object System.Management.Automation.Host.ChoiceDescription "&Yes", "Use MSI detection methods"
                            $no = new-object  System.Management.Automation.Host.ChoiceDescription "&No", "Do not use MSI detection methods"
                            $optionsYN = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
                            $results = $host.ui.PromptForChoice($title, $message, $optionsYN, 0) 
                            switch($result)
                            {
                                0{
                                    $DeploymentInstallCommandLine = read-host -Prompt "Enter Install Command: "
                                    $DeploymentUninstallCommandLine = read-host -Prompt "Enter Uninstall Command: "
                                }
                                1{
                                    $DeploymentInstallCommandLine = ""
                                    $DeploymentUninstallCommandLine = ""
                                }
                            }
                        }
                        write-verbose "Prompting for installer"
                        $title = "Select Installer File"
                        $message = "Select the INSTALLER file for this deployment type"
                        $result = $host.ui.PromptForChoice($title, $message, $options, 0)
                        $optionName = $options[$result].Label
                        $DeploymentInstallCommandLine = $optionName; Write-Verbose "Install Command - $DeploymentInstallCommandLine"
                        write-verbose "Prompting for uninstaller"
                        $title = "Select Uninstaller"
                        $message = "Select the UNINSTALLER file for this deployment type"
                        $result = $host.ui.PromptForChoice($title, $message, $options, 0)
                        $optionName = $options[$result].Label
                        $DeploymentUninstallCommandLine = $optionName; Write-Verbose "Uninstall Command - $DeploymentUnInstallCommandLine"
                    }

                    #get product code, find msi files
                    $msiFiles = Get-ChildItem -Path $MSIInstallerPath -Filter *.msi
                    $options = @()
                    $count = 0
                    foreach($msiFile in $msiFiles){
                        $MSIfilePath = $msiFile.fullname
                        $MSIfileName = $msiFile.name
                        write-verbose "Found MSI file - $MSIfilepath"
                
                        $count++
                        $option = new-object System.Management.Automation.Host.ChoiceDescription $MSIFileName,$MSIFilename
                        $options+=($option)
                    } #end each MSI file found
                    if($options.Length -eq 1)
                    {
                        $MSIfilePath = $msiFiles[0].fullname
                        Write-Verbose "Found only 1 MSI, Setting product GUID and Version"
                        $code = Get-MsiDatabaseCode -FilePath $MSIfilePath
                        $version = Get-MsiDatabaseVersion -FilePath $MSIfilePath
                        $DeploymentProductGuid = $code[1]
                        $DeploymentProductVersion = $version[1]
                        write-verbose "Product GUID - $DeploymentProductGuid"
                        Write-Verbose "Product Version - $DeploymentProductVersion"
                    }
                    if($count -eq 0){
                        #found no MSI, manual intervention needed
                        $title = "Use MSI Detection Method?"
                        $Message = "Use MSI Dection Method?"
                        $yes = new-object System.Management.Automation.Host.ChoiceDescription "&Yes", "Use MSI detection methods"
                        $no = new-object  System.Management.Automation.Host.ChoiceDescription "&No", "Do not use MSI detection methods"
                        $optionsYN = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
                        $results = $host.ui.PromptForChoice($title, $message, $optionsYN, 0) 
                        switch($optionsYN[$results].label)
                        {
                            "&Yes"{
                                $DeploymentProductGuid = read-host -Prompt "Enter Product GUID: "
                                $DeploymentProductVersion = read-host -Prompt "Enter Product Version: "
                            }
                            "&No"{$DeploymentInstallUseEnhanced = $false}
                        }
                    }
                    if($count -gt 1){
                        #found more than one MSI, intervention needed
                        $title = "Which MSI do you want to use?"
                        $Message = "Which MSI do you want to use?"
                        $manuallySpecify = new-object System.Management.Automation.Host.ChoiceDescription "Manually Specify", "Manually Specify"
                        $options+=($manuallySpecify)
                        $result = $host.UI.PromptForChoice($title, $message, $options, 0)
                        $selection = $options[$result].Label
                        write-verbose "$selection was chosen"
                    if($selection -ne "Manually Specify"){
                        foreach($msiFile in $msiFiles){
                            if($msiFile.Name -eq $selection){
                                $MSIfilePath = $msiFile.fullname
                                $code = Get-MsiDatabaseCode -FilePath $MSIfilePath
                                $version = Get-MsiDatabaseVersion -FilePath $MSIfilePath
                                $DeploymentProductGuid = $code[1]
                                $DeploymentProductVersion = $version[1]
                                write-verbose "Product GUID - $DeploymentProductGuid"
                                Write-Verbose "Product Version - $DeploymentProductVersion"
                            }
                        }
                    }  
                    else{
                        $DeploymentInstallUseEnhanced = $true
                        $DeploymentProductGuid = read-host -Prompt "Enter Product GUID: "
                        $DeploymentProductVersion = read-host -Prompt "Enter Product Version: "
                    }#end manual specify check               
                }
            } #END MSI Find installer and uninstaller and product code and version
            if($ApplicationType.toupper() -eq "APP-V"){
                if($ApplicationStatus.toupper() -eq "2.1.5 UAT PREP"){
                    $AppVInstallerPath = "\\dompwv01f\dappuat\$ApplicationTitleNoPreFix\App-V\$ApplicationTitleNoPreFix\"
                }
                else{
                    $AppVInstallerPath = "$ApplicationSourcePath\App-V\$ApplicationTitleNoPreFix\"
                }
                write-verbose "App-V installer path $AppVInstallerPath"
            }
            
            #test if the CM application already exists.
            Write-Verbose "Looking if application already exists."
            set-location $SiteCode`:\
            if(Get-CMApplication -Name $ApplicationTitle){
                write-verbose "The application already exists, not continuing."
            }
            else { 
                Write-Verbose "Application does not exist."
                #create the CM Application
                
                #Add-CMDeploymentType -ApplicationName <String> -AppvInstaller -AutoIdentifyFromInstallationFile -ForceForUnknownPublisher <Boolean> -InstallationFileLocation <String> [-AdministratorComment <String> ] [-AllowClientsToUseFallbackSourceLocationForContent <Boolean> ] [-DeploymentTypeName <String> ] [-Language <String[]> ] [-OnFastNetworkMode <OnFastNetworkMode> {RunFromNetwork | RunLocal} ] [-OnSlowNetworkMode <ContentHandlingMode> {DoNothing | Download | DownloadContentForStreaming} ] [-Confirm] [-WhatIf] [ <CommonParameters>]
                if($ApplicationType -eq "APP-V"){
                    #get appv xml doc
                    set-location c:\
                    if(Test-Path $AppVInstallerPath){
                        $xmlFiles = get-childitem -path $AppVInstallerPath -Filter *.xml
                                                        foreach($xmlFile in $xmlFiles){
                    if($xmlFile.name.tolower() -ne "report.xml"){
                        $AppVFile = $xmlfile.fullname
                    }
                }
                        write-verbose "Manifest file - $AppVFile"                    
                        set-location $sitecode`:\
                        New-CMApplication -ReleaseDate $today -AutoInstall $true -Publisher $ApplicationPublisher -Name $ApplicationTitle -SoftwareVersion $ApplicationVersion |out-null
                        Add-CMDeploymentType -ApplicationName $ApplicationTitle -AppvInstaller -InstallationFileLocation $appVfile -AutoIdentifyFromInstallationFile -ForceForUnknownPublisher $true -DeploymentTypeName "$ApplicationTitle App-V 4.6 Deployment" -OnSlowNetworkMode Download 
                    }
                else{
                    write-verbose "AppV path does not exist $AppVInstallerPath"
                    exit
                }
            } #end App-V Application Type.
            else{
                # Create unique ID for application and deployment type
                $ApplicationID = "APP_" + [GUID]::NewGuid().ToString(); Write-Verbose "Application ID - $ApplicationID"
                $DeploymentTypeID = "DEP_" + [GUID]::NewGuid().ToString(); Write-Verbose "Deployment ID - $DeploymentTypeID"
                $GetIdentification = [WmiClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_Identification"
                $ScopeID = "ScopeId_" + $GetIdentification.GetSiteID().SiteID -replace "{","" -replace "}",""; Write-Verbose "Scope ID - $ScopeID"
            
                $ObjectApplicationID = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.ObjectId($ScopeID,$ApplicationID)
                $ObjectDeploymentTypeID = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.ObjectId($ScopeID,$DeploymentTypeID)
                $ObjectApplication = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.Application($ObjectApplicationID)
                $ObjectDeploymentType = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.DeploymentType($ObjectDeploymentTypeID,"Script")
                
                # Add content to the Application
                $ApplicationContent = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentImporter]::CreateContentFromFolder($MSIInstallerPath)
                $ApplicationContent.OnSlowNetwork = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentHandlingMode]::DoNothing
                $ApplicationContent.OnFastNetwork = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentHandlingMode]::Download
               
                # Application information
                $ObjectDisplayInfo = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.AppDisplayInfo
                $ObjectDisplayInfo.Language = $ApplicationLanguage
                $ObjectDisplayInfo.Title = $ApplicationTitleNoPreFix
                $ObjectDisplayInfo.InfoUrl = $AppTrackingLink
                $ObjectDisplayInfo.InfoUrlText = "Application Information"
                $ObjectDisplayInfo.Description = $ApplicationDescription
                $ObjectDisplayInfo.Publisher = $ApplicationPublisher
                $ObjectDisplayInfo.Version = $ApplicationVersion
                $ObjectApplication.DisplayInfo.Add($ObjectDisplayInfo)
                $ObjectApplication.DisplayInfo.DefaultLanguage = $ApplicationLanguage
                $ObjectApplication.Title = $ApplicationTitle
                $ObjectApplication.Version = 1
                $ObjectApplication.SoftwareVersion = $ApplicationVersion
                $ObjectApplication.DownloadDelta = $true
                $ObjectApplication.Description = $ApplicationDescription
                $ObjectApplication.Publisher = $ApplicationPublisher
                

                # DeploymentType configuration
                $ObjectDeploymentType.Title = $ApplicationTitle
                $ObjectDeploymentType.Version = 1
                $ObjectDeploymentType.Enabled = $true
                $ObjectDeploymentType.Description = $ApplicationDescription
                $ObjectDeploymentType.Installer.Contents.Add($ApplicationContent)
                #get contentID, this is needed for the client to be able to download the files.
                #http://blog.lechar.nl/2012/04/11/application-wont-download-content/
                $ApplicationContentRef = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.ContentRef
                $ApplicationContentRef.ID = $ApplicationContent.ID
                $ObjectDeploymentType.Installer.InstallContent = $ApplicationContentRef
                $ObjectDeploymentType.Installer.InstallCommandLine = $DeploymentInstallCommandLine
                $ObjectDeploymentType.Installer.UninstallCommandLine = $DeploymentUninstallCommandLine
                #$ObjectDeploymentType.Installer.ProductCode = "{" + [GUID]::NewGuid().ToString() + "}"
                #$ObjectDeploymentType.Installer.ProductVersion = "1.0"
                $ObjectDeploymentType.Installer.ExecutionContext = "System"
                $ObjectDeploymentType.Installer.RequiresUserInteraction = $false
            
                Write-Verbose "Using enhanced detection method"
                $ObjectDeploymentType.Installer.DetectionMethod = [Microsoft.ConfigurationManagement.ApplicationManagement.DetectionMethod]::Enhanced
                #build the enhanced detection method
                $EnhancedDetectionMethod = new-object Microsoft.ConfigurationManagement.ApplicationManagement.EnhancedDetectionMethod
                #update with correct product GUID
                if(-not $DeploymentInstallUseEnhanced){
                    $DeploymentProductGuid = [Guid]::NewGuid().ToString();
                    $MSI = "NA"
                }
                $MSISettingInstance = new-object Microsoft.ConfigurationManagement.DesiredConfigurationManagement.MSISettingInstance -ArgumentList ($DeploymentProductGuid,$null)
                
                #create settings reference
                $refName = "SettingRef_" + [Guid]::NewGuid().ToString(); write-verbose "Settings Reference - $refName"  #create a new GUID
                $logicalName = $MSISettingInstance.LogicalName #i.e. MSI_74dbdc2c-2331-49ce-8e77-37204365d0e7
                $msiVersion = $DeploymentProductVersion
                $dataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Version #Object Type being compared against.
                $dataType2 = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ConfigurationItemSettingSourceType]::MSI
                $dataTypeVersion = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ConfigurationItemSettingMethodType]::Value
                $dataTypeIsEquals = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ExpressionOperators.ExpressionOperator]::IsEquals

                $SettingsReference = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.SettingReference -ArgumentList ($scopeID, $refName, 0, $logicalName, $dataType, $dataType2, $true, $dataTypeVersion,"ProductVersion")

                $SettingsConstant = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ConstantValue -ArgumentList ($msiVersion, [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Version)

                #unsure why this works, but it instantiates the correct object type
                $operands = new-object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ExpressionBase]]"

                $operands.add($SettingsReference)
                $operands.add($SettingsConstant)
                write-verbose "Adding operands to the detection method"
                $expression = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.Expression -ArgumentList ($dataTypeIsEquals), $operands

                $anno =  new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Annotation 
                $anno.DisplayName = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.LocalizableString -ArgumentList "DisplayName", $logicalName, $null

                $rule = new-object "Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Rule" -ArgumentList ( ("Rule_" + [Guid]::NewGuid().ToString()), [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::None, $anno, $expression)
                $ObjectDeploymentType.Installer.EnhancedDetectionMethod = new-object Microsoft.ConfigurationManagement.ApplicationManagement.EnhancedDetectionMethod
                $ObjectDeploymentType.Installer.EnhancedDetectionMethod.Settings.Add($MSISettingInstance)
                $ObjectDeploymentType.Installer.EnhancedDetectionMethod.Rule = $rule
                Write-Verbose "Enhanced Detection Rules Created"
                
                #set available requirements
                write-verbose "Adding OS requirements"
                $T1 = "Windows/x64_Windows_7_SP1"
                $T4 = "Windows/All_x64_Windows_Server_2008_R2"
                $T0 = "Windows/x86_Embedded_Windows_7"
                $OSRequirements = @();
                $T1T2T3NotFoundYet = $true
                foreach($scope in $ApplicationScope.Split(",")){
                    if("T1","T2","T3" -contains $scope -and $T1T2T3NotFoundYet){
                        $OSRequirements+=$t1
                        $T1T2T3NotFoundYet = $false
                        write-verbose "Found $t1 requirement"
                    }
                    if("T4","Comet 2008R2","Citrix-Offshore 2008R2"-contains  $scope){
                        $OSRequirements+=$t4
                        write-verbose "Found $t4 requirement"
                    }
                    if($scope -eq "T0"){
                        $OSRequirements+=$t0
                        write-verbose "Found $T0 requirement"
                    }

                }
            $operands = new-object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.RuleExpression]]"
            $Expoperator = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ExpressionOperators.ExpressionOperator]::OneOf
                            
            foreach($scope in $OSRequirements){
                #$rule = Create-SCCMGlobalConditionsRule "Global/OperatingSystem" "OneOF" @("Windows/All_x64_Windows_XP_Professional") .
                $operands.Add("$scope")
            }# end adding scope requirements.
                    
            #Creating the expression
            $arg = @( $Expoperator , 
                        $operands
                    )
            $expression = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.OperatingSystemExpression -ArgumentList $arg

            #Creating the rule
            $arg = @(
                ("Rule_" + [Guid]::NewGuid().ToString()), 
                [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::None, 
                $anno, 
                $expression
            )

            $rule = new-object "Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Rule" -ArgumentList $arg  


            # Add DeploymentType to Application
            write-verbose "Added Requirements"
            $ObjectDeploymentType.Requirements.Add($rule)      

            write-verbose "Deployment Type created"
            $ObjectApplication.DeploymentTypes.Add($ObjectDeploymentType)
            
            write-verbose "Deployment type added"
            # Serialize the Application
            $ApplicationXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeToString($ObjectApplication)
            $ApplicationClass = [WmiClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_Application"
            $ObjectApplication = $ApplicationClass.CreateInstance()
            write-verbose "Connected to $siteserver WMI repository"
            $ObjectApplication.SDMPackageXML = $ApplicationXML
            $Temp = $ObjectApplication.Put()
            $ObjectApplication.Get()
            write-verbose "Application Created"
            
            Set-CMApplication -Name $ApplicationTitle -AutoInstall $true | out-null
        }#end MSI section
        #determine CM Categories.
        $categories = @()
        foreach($scope in $ApplicationScope.Split(",")){
            switch ($scope){
                "T0"{$categories += "Tier0"}
                "T1"{$categories += "Tier1"}
                "T2"{$categories += "Tier2"}
                "T3"{$categories += "Tier3"}
                "T4"{$categories += "Tier4"}
                "Comet 2008R2"{$categories += "Comet-V2"}
            }
        }
        switch($ApplicationCategory){
            "BusinessApp" {$categories += "BusinessApp"}
            "CoreApp" {$categories += "CoreApp"}
            "ExtendedApp" {$categories += "ExtendedApp"}
            "BaseApp" {$categories += "BaseApp"}
        }
        write-verbose "Setting CM Application categories - $categories"
        Set-CMApplication -name $ApplicationTitle -AppCategories $categories

    } #end check if already exists
}
        } #END returnedapps.count = 1        
        else{
            #no results, or too many results
            write-verbose $returnedApps.data.ItemCount
            write-verbose "No results found? Maybe more than one"

        } # end check for number of returned apps
        return $ApplicationTitle
    } #end use app tracking
    
  }

  end
  {

  }
}

function DistributeApplication
{
    [CmdletBinding()]
    param(
        [string[]]$DPGroupNames = "Shoreview DP Group",
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


#working
#$appNames = "WSG ClientSync V3 R1","Cisco Anyconnect Secure Mobility Client 3.1.01065 - Start Before Login "
set-location c:\
#$appNames = get-content c:\temp\apps.txt
$appNames = "IBM Endpoint Manager Client for Windows 9.1.117.0"
$DPGroupNames = "Shoreview DP Group","Omaha DP Group"
#verbose is important if you want to see what is happening.
foreach ($appName in $appNames){
    New-DLXCM2012Application -Name "$appname" -UseAppTracking $true -Verbose
    $app = $null
    $app = Get-CMApplication -Name "PROD - $appname"
    $appName = $app.LocalizedDisplayName
    $PackageId = $app.PackageID
    if($app -and $PackageId){
        DistributeApplication -DPGroupName $DPGroupNames -PackageID $PackageId -Verbose 
    }
    else{
        Write-Verbose "No application created"
    }
}
set-location c:\




#deploy the new app to test collection
#Start-CMApplicationDeployment -CollectionName "WKS - LAB - Imported App Deployment" -name $appname -DeployAction Install -DeployPurpose Required -AvaliableDate 2014/5/21 -AvaliableTime 01:01 -DeadlineDate 2014/5/21 -DeadlineTime 01:02
<#
set-location DLX:\
$appName =  "PROD - IBM CICS Transaction Gateway 9.0.0.1"
Remove-CMApplication -Name $appName -Force
set-location c:\
#>