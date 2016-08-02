$SiteCode = "PS1"
$SiteServer = "Cm-pri.uwrf.edu"

$CollectionsToChange = (Get-WmiObject -Namespace "root\sms\site_$SiteCode" -Class "SMS_Collection" -ComputerName $SiteServer | Select Name, __PATH |Out-GridView -OutputMode Multiple) 

foreach ($collectionObj in $CollectionsToChange){
    try{
        $collection = [wmi]"$($collectionObj.__Path)"
        $collection.RefreshType = 2
        $IntervalClass = Get-WmiObject -List -Namespace "root\sms\site_$SiteCode" -Class "SMS_ST_RecurInterval" -ComputerName $SiteServer
        $Interval = $IntervalClass.CreateInstance()
        $Interval.HourSpan = 24 #Update after 12 hours
        $collection.RefreshSchedule = $Interval
        $collection.put()
        Write-Host -ForegroundColor green "$($collection.Name): $($collection.CollectionID)"
    } catch {
        Write-Host -ForegroundColor red "ERROR: $($collection.Name): $($collection.CollectionID): $($_.Exception.Message)"
    }
}