# Import ConfigMgr Module
Import-Module ($env:SMS_ADMIN_UI_PATH.Substring(0,$env:SMS_ADMIN_UI_PATH.Length – 5) + '\ConfigurationManager.psd1') 

# - - - Settings - - -
$SiteCode = 'DLX:'

# Number of days in report
$DaysToShow = '-7'

# Mail settings
$smtpserver =  "smtp.deluxe.com"
$MailSubject = "ConfigMgr Week Report"
#$MailRecipients = "desktopengineering@deluxe.com" , "swdgroup@deluxe.com", "SBDCEngineering@deluxe.com"
$MailRecipients = "fred.bainbridge@deluxe.com"

$FromAddress = "CMReports@deluxe.com"

# Tempfile to store data
$msgfile = 'c:\temp\mailmessage.txt'

# - - - End Settings - - -

# Create file
New-Item $msgfile -ItemType file -Verbose -Force

Set-Location $SiteCode

$StartTime = (Get-Date)

# Get data from ConfigMgr

$NewApplications =      Get-CMApplication       | ? DateCreated -gt (get-date).AddDays($DaysToShow)      | Select LocalizedDisplayName,LastModifiedBy, DateCreated       | Sort-Object DateCreated
$ModifiedApplications = Get-CMApplication       | ? DateLastModified -gt (get-date).AddDays($DaysToShow) | Select LocalizedDisplayName,LastModifiedBy, DateLastModified  | Sort-Object DateLastModified
$NewCI =                Get-CMConfigurationItem | ? DateCreated -gt (get-date).AddDays($DaysToShow)      | Select LocalizedDisplayName,LastModifiedBy, DateCreated       | Sort-Object DateCreated
$ModifiedCI =           Get-CMConfigurationItem | ? DateLastModified -gt (get-date).AddDays($DaysToShow) | Select LocalizedDisplayName,LastModifiedBy, DateLastModified  | Sort-Object DateLastModified
$NewBaselines =         Get-CMBaseline          | ? DateCreated -gt (get-date).AddDays($DaysToShow)      | Select LocalizedDisplayName,LastModifiedBy, DateCreated       | Sort-Object DateCreated
$ModifiedBaselines =    Get-CMBaseline          | ? DateLastModified -gt (get-date).AddDays($DaysToShow) | Select LocalizedDisplayName,LastModifiedBy, DateLastModified  | Sort-Object DateLastModified
$DriverPackages =       Get-CMDriverPackage     | ? SourceDate -gt (get-date).AddDays($DaysToShow)       | Select Name,SourceDate                                        | Sort-Object SourceDate
$NewBoundarys =         Get-CMBoundary          | ? CreatedOn  -gt (Get-Date).AddDays($DaysToShow)       | Select DisplayName, ModifiedBy ,CreatedOn                     | Sort-Object CreatedOn
$ModifiedBoundarys =    Get-CMBoundary          | ? ModifiedOn -gt (Get-Date).AddDays($DaysToShow)       | Select DisplayName, ModifiedBy, ModifiedOn                    | Sort-Object ModifiedOn
$NewDeployments =       Get-CMDeployment        | ? CreationTime -gt (Get-Date).AddDays($DaysToShow)     | Select CollectionName,CreationTime,SoftwareName               | Sort-Object CreationTime
$Bootimages =           Get-CMBootImage         | ? SourceDate -gt (Get-Date).AddDays($DaysToShow)       | Select Name,Description,SourceDate                            | Sort-Object SourceDate
$Packages =             Get-CMPackage           | ? SourceDate -gt (get-date).AddDays($DaysToShow)       | Select Name,SourceDate                                        | Sort-Object SourceDate
$TaskSequences =        Get-CMTaskSequence      | ? SourceDate -gt (Get-Date).addDays(-7)                | select Name,SourceDate                                        | Sort-Object SourceDate
$EndTime = (Get-Date)

function New-Table (
$Title,
$Topic1,
$Topic2,
$Topic3

)
{
       Add-Content $msgfile "<h3>$Title</h3>"
       Add-Content $msgfile "<p><table cellspacing=""15"">"
       Add-Content $msgfile "<tr><th>$Topic1</th><th>$Topic2</th><th>$Topic3</th></tr>"
}
function New-TableRow (
$col1, 
$col2,
$col3

)
{
Add-Content $msgfile "<tr><td>$col1</td><td>$col2</td><td>$col3</td></tr>"
}
function New-TableEnd {
Add-Content $msgfile "</table></p>"}

if ($NewDeployments -ne $null ) {
    New-Table -Title "New Deployments" -Topic1 "SoftwareName" -Topic2 "Deployed to" -Topic3 "CreationTime"
    foreach ($app in $NewDeployments ) {New-TableRow -col1 $app.SoftwareName -col2 $app.CollectionName -col3 $app.CreationTime}
    New-TableEnd
 }

if ($NewApplications -ne $null ) {
    New-Table -Title "New Applications" -Topic1 "LocalizedDisplayName" -Topic2 "LastModifiedBy" -Topic3 "DateCreated"
    foreach ($app in $NewApplications ) {New-TableRow -col1 $app.LocalizedDisplayName -col2 $app.LastModifiedBy -col3 $app.DateCreated}
    New-TableEnd
 }

if ($ModifiedApplications -ne $null ) {
    New-Table -Title "Modified Applications" -Topic1 "LocalizedDisplayName" -Topic2 "LastModifiedBy" -Topic3 "DateLastModified"
    foreach ($app in $ModifiedApplications ) {New-TableRow -col1 $app.LocalizedDisplayName -col2 $app.LastModifiedBy -col3 $app.DateLastModified}
    New-TableEnd
 }

if ($Packages -ne $null ) {
    New-Table -Title "New/Modified Packages" -Topic1 "Name" -Topic2 "SourceDate"
    foreach ($app in $Packages ) {New-TableRow -col1 $app.Name -col2 $app.SourceDate}
    New-TableEnd
 }
 
if ($Packages -ne $null ) {
    New-Table -Title "New Task Sequences" -Topic1 "Name" -Topic2 "SourceDate"
    foreach ($app in $TaskSequences ) {New-TableRow -col1 $app.Name -col2 $app.SourceDate}
    New-TableEnd
 
}
if ($DriverPackages -ne $null ) {
    New-Table -Title "New/Modified Driver Packages" -Topic1 "Name" -Topic2 "SourceDate"
    foreach ($app in $DriverPackages ) {New-TableRow -col1 $app.Name -col2 $app.SourceDate}
    New-TableEnd
 }

if ($NewCI -ne $null ) {
    New-Table -Title "New CI's" -Topic1 "LocalizedDisplayName" -Topic2 "LastModifiedBy" -Topic3 "DateCreated"
    foreach ($app in $NewCI ) {New-TableRow -col1 $app.LocalizedDisplayName -col2 $app.LastModifiedBy -col3 $app.DateCreated}
    New-TableEnd
 }

if ($ModifiedCI -ne $null ) {
    New-Table -Title "Modified CI's" -Topic1 "LocalizedDisplayName" -Topic2 "LastModifiedBy" -Topic3 "DateLastModified"
    foreach ($app in $ModifiedCI ) {New-TableRow -col1 $app.LocalizedDisplayName -col2 $app.LastModifiedBy -col3 $app.DateLastModified}
    New-TableEnd
 }

if ($NewBaselines -ne $null ) {
    New-Table -Title "New Baselines's" -Topic1 "LocalizedDisplayName" -Topic2 "LastModifiedBy" -Topic3 "DateCreated"
    foreach ($app in $NewBaselines ) {New-TableRow -col1 $app.LocalizedDisplayName -col2 $app.LastModifiedBy -col3 $app.DateCreated}
    New-TableEnd
 }

if ($ModifiedBaselines -ne $null ) {
    New-Table -Title "Modified Baselines" -Topic1 "LocalizedDisplayName" -Topic2 "LastModifiedBy" -Topic3 "DateLastModified"
    foreach ($app in $ModifiedBaselines ) {New-TableRow -col1 $app.LocalizedDisplayName -col2 $app.LastModifiedBy -col3 $app.DateLastModified}
    New-TableEnd
 }

if ($NewBoundarys -ne $null ) {
    New-Table -Title "New Boundarys" -Topic1 "DisplayName" -Topic2 "ModifiedBy" -Topic3 "CreatedOn"
    foreach ($app in $NewBoundarys ) {New-TableRow -col1 $app.DisplayName -col2 $app.ModifiedBy -col3 $app.CreatedOn}
    New-TableEnd
 }

if ($ModifiedBoundarys -ne $null ) {
    New-Table -Title "Modified Boundarys" -Topic1 "DisplayName" -Topic2 "ModifiedBy" -Topic3 "ModifiedOn"
    foreach ($app in $ModifiedBoundarys ) {New-TableRow -col1 $app.DisplayName -col2 $app.ModifiedBy -col3 $app.ModifiedOn}
    New-TableEnd
 }

if ($Bootimages -ne $null ) {
    New-Table -Title "New/Modified Boot Images" -Topic1 "Name" -Topic2 "Description" -Topic3 "SourceDate"
    foreach ($app in $Bootimages ) {New-TableRow -col1 $app.Name -col2 $app.Description -col3 $app.SourceDate}
    New-TableEnd
 }
 

Add-Content $msgfile "<p>Data collected in $(($EndTime-$StartTime).totalseconds) seconds</p>"
$mailbody = Get-Content $msgfile

Send-MailMessage -Body "$mailbody" -From $FromAddress -to $MailRecipients -SmtpServer $smtpserver -Subject $MailSubject -BodyAsHtml 
# Delete tempfile 
Remove-Item $msgfile