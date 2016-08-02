  <#
  
        .SYNOPSIS
            Creates a Global Condition rule of type [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Rule]. 
            This rule can be added as a requirement for an deployment type
 
        .DESCRIPTION
            This function will Create a rule for an global condition
              
        .PARAMETER GlobalCondition
            Name of the global condition you wanted to use
  
        .PARAMETER Operator
            Operator used to validate the rule. Accepted values are Equals,NotEquals,GreaterThan,LessThan,Between,GreaterEquals,LessEquals,BeginsWith,NotBeginsWith,EndsWith,NotEndsWith,Contains,NotContains,AllOf,OneOf,NoneOf,SetEquals
             
        .PARAMETER Value
            Value on which the rule should check. Use MB when data value is needed
 
        .PARAMETER SiteServerName
           Name of the SCCM Site server to check Global Conditions
  
        .EXAMPLE
            Create-SCCMGlobalConditionsRule "TotalPhysicalMemory" "GreaterEquals" 524288000 .
              
            Creates a rule where Total Phyiscal memory is greater than or equals to 500 MB
  
        .EXAMPLE
             
            Create-SCCMGlobalConditionsRule "CPU" "GreaterThan" 10000 .
             
            Creates a rule where the cpu speed is greater than 1 GHZ
  
 #>
 Function Create-SCCMGlobalConditionsRule($GlobalCondition,$Operator, $Value,$siteServerName){
    if($GlobalCondition.ModelName -eq $null){
        $GlobalCondition = Get-SCCMGlobalCondition $GlobalCondition $siteServerName
    }
 
    if($GlobalCondition -eq $null){
        Write-Error "Global condition not found"
    }
 
    $gcTmp =  $GlobalCondition.ModelName.Split("/")
    $gcScope = $gcTmp[0]
    $gcLogicalName = $gcTmp[1]
    $gcDataType = $GlobalCondition.DataType
    $gcExpressionDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::GetDataTypeFromTypeName($gcDataType)
    
    $arg = @($gcScope, 
              $gcLogicalName, 
              $gcExpressionDataType, 
              "$($gcLogicalName)_Setting_LogicalName", 
              ([Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ConfigurationItemSettingSourceType]::CIM) 
             )
    $reqSetting =  new-object  Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.GlobalSettingReference -ArgumentList  $arg
 
    $arg = @( $value,
               $gcExpressionDataType
             )
    $reqValue = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ConstantValue -ArgumentList $arg
 
 
 
 
    $operands = new-object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ExpressionBase]]"
    $operands.Add($reqSetting) | Out-Null
    $operands.Add($reqValue) | Out-Null
  
    $Expoperator =  Invoke-Expression [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ExpressionOperators.ExpressionOperator]::$operator
     
    if( $GlobalCondition.DataType -eq "OperatingSystem"){
     
        $operands = new-object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.RuleExpression]]"
        foreach( $os in $value){
            $operands.Add($os)
        }
        $arg = @( $Expoperator , 
            $operands
        )
        $expression = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.OperatingSystemExpression -ArgumentList $arg
     
    }else{
        $arg = @( $Expoperator , 
            $operands
        )
        $expression = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.Expression -ArgumentList $arg
     
    }
     
    $anno =  new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Annotation 
    $annodisplay = "$GlobalCondition.LocalizedDisplayName $operator $value"
    $arg = @(
                "DisplayName", 
                $annodisplay, 
                $null
            )
    $anno.DisplayName = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.LocalizableString -ArgumentList $arg
     
    $arg = @(
                 ("Rule_" + [Guid]::NewGuid().ToString()), 
                 [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::None, 
                 $anno, 
                 $expression
            )
    $rule = new-object "Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Rule" -ArgumentList $arg
 
 
    return $rule
 }
