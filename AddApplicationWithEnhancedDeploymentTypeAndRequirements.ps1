
 
$SiteServer = "degpwa59.deluxe.com"
$SiteCode = "DLX"
$GetIdentification = [WmiClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_Identification"
$ScopeID = "ScopeId_" + $GetIdentification.GetSiteID().SiteID -replace "{","" -replace "}",""
$ContentSourcePath = "\\dompwv01f\dappuat\Google Talk 1.0.0.104"
$ApplicationTitle = "TestApp"
$ApplicationVersion = 1.0
$ApplicationSoftwareVersion = "1.0"
$ApplicationLanguage = (Get-Culture).Name
$ApplicationDescription = "Test description"
$ApplicationPublisher = "TestCorp"
$DeploymentInstallCommandLine = "setup.exe"
$DeploymentUninstallCommandLine = "setup.exe /uninstall"

# Create unique ID for application and deployment type
$ApplicationID = "APP_" + [GUID]::NewGuid().ToString()
$DeploymentTypeID = "DEP_" + [GUID]::NewGuid().ToString()

$ObjectApplicationID = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.ObjectId($ScopeID,$ApplicationID)
$ObjectDeploymentTypeID = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.ObjectId($ScopeID,$DeploymentTypeID)
$ObjectApplication = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.Application($ObjectApplicationID)
$ObjectDeploymentType = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.DeploymentType($ObjectDeploymentTypeID,"Script")
 
# Add content to the Application
$ApplicationContent = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentImporter]::CreateContentFromFolder($ContentSourcePath)
$ApplicationContent.OnSlowNetwork = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentHandlingMode]::DoNothing
$ApplicationContent.OnFastNetwork = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentHandlingMode]::Download
 
# Application information
$ObjectDisplayInfo = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.AppDisplayInfo
$ObjectDisplayInfo.Language = $ApplicationLanguage
$ObjectDisplayInfo.Title = $ApplicationTitle
$ObjectDisplayInfo.Description = $ApplicationDescription
$ObjectApplication.DisplayInfo.Add($ObjectDisplayInfo)
$ObjectApplication.DisplayInfo.DefaultLanguage = $ApplicationLanguage
$ObjectApplication.Title = $ApplicationTitle
$ObjectApplication.Version = $ApplicationVersion
$ObjectApplication.SoftwareVersion = $ApplicationSoftwareVersion
$ObjectApplication.Description = $ApplicationDescription
$ObjectApplication.Publisher = $ApplicationPublisher
 
# DeploymentType configuration
$ObjectDeploymentType.Title = $ApplicationTitle
$ObjectDeploymentType.Version = $ApplicationVersion
$ObjectDeploymentType.Enabled = $true
$ObjectDeploymentType.Description = $ApplicationDescription
$ObjectDeploymentType.Installer.Contents.Add($ApplicationContent)
$ObjectDeploymentType.Installer.InstallCommandLine = $DeploymentInstallCommandLine
$ObjectDeploymentType.Installer.UninstallCommandLine = $DeploymentUninstallCommandLine
$ObjectDeploymentType.Installer.ProductCode = "{" + [GUID]::NewGuid().ToString() + "}"
$ObjectDeploymentType.Installer.ProductVersion = "1.0"
$ObjectDeploymentType.Installer.ExecutionContext = "System"
$ObjectDeploymentType.Installer.RequiresUserInteraction = $false
#$ObjectDeploymentType.Installer.RequiresElevatedRights = $true
$ObjectDeploymentType.Installer.DetectionMethod = [Microsoft.ConfigurationManagement.ApplicationManagement.DetectionMethod]::Enhanced

#build the enhanced detection method
$EnhancedDetectionMethod = new-object Microsoft.ConfigurationManagement.ApplicationManagement.EnhancedDetectionMethod
#update with correct product GUID
$MSISettingInstance = new-object Microsoft.ConfigurationManagement.DesiredConfigurationManagement.MSISettingInstance -ArgumentList ([GUID]::NewGuid().ToString(),$null)

#delete existing application if present
$preApp = Get-CMApplication -Name $ApplicationTitle
if($preApp){
    Remove-CMApplication -Name $ApplicationTitle -force   
}

#create settings reference
$refName = "SettingRef_" + [Guid]::NewGuid().ToString()  #create a new GUID
$logicalName = $MSISettingInstance.LogicalName #i.e. MSI_74dbdc2c-2331-49ce-8e77-37204365d0e7
$msiVersion = "1.0" #to be passed in
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

$expression = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.Expression -ArgumentList ($dataTypeIsEquals), $operands

$anno =  new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Annotation 
$anno.DisplayName = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.LocalizableString -ArgumentList "DisplayName", $logicalName, $null

$rule = new-object "Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Rule" -ArgumentList ( ("Rule_" + [Guid]::NewGuid().ToString()), [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::None, $anno, $expression)
$ObjectDeploymentType.Installer.EnhancedDetectionMethod = new-object Microsoft.ConfigurationManagement.ApplicationManagement.EnhancedDetectionMethod
$ObjectDeploymentType.Installer.EnhancedDetectionMethod.Settings.Add($MSISettingInstance)
$ObjectDeploymentType.Installer.EnhancedDetectionMethod.Rule = $rule

$T1 = "Windows/x64_Windows_7_SP1"
$T4 = "Windows/All_x64_Windows_Server_2008_R2"
$t0 = "Windows/x86_Embedded_Windows_7"

#add each scope as a requirement.
$scopes = $t1, $t4, $t0
foreach($scope in $scopes){
    #$rule = Create-SCCMGlobalConditionsRule "Global/OperatingSystem" "OneOF" @("Windows/All_x64_Windows_XP_Professional") .
    $Expoperator = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ExpressionOperators.ExpressionOperator]::OneOf
    $operands = new-object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.RuleExpression]]"
    $operands.Add("$scope")

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
    $ObjectDeploymentType.Requirements.Add($rule)      

}$ObjectApplication.DeploymentTypes.Add($ObjectDeploymentType)
 
# Serialize the Application
$ApplicationXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeToString($ObjectApplication)
$ApplicationClass = [WmiClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_Application"
$ObjectApplication = $ApplicationClass.CreateInstance()
$ObjectApplication.SDMPackageXML = $ApplicationXML
$Temp = $ObjectApplication.Put()
$ObjectApplication.Get()



#$app = Get-WmiObject -computername "degpwa59.deluxe.com" -namespace "Root\SMS\Site_DLX" -query "select * from SMS_Application"