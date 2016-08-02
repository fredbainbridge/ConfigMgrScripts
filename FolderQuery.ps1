$SiteServer = "DEGPWA59.DELUXE.COM"
$SiteCode = "DLX"
$query = "SELECT * FROM SMS_FullCollectionMembership WHERE CollectionID='DLX00054'"
(get-wmiobject -ComputerName $siteserver -Namespace "root\sms\site_dlx" -query $query).ResourceID

            
            
