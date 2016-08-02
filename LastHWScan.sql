declare @SMSSiteCode varchar(30);
set @SMSSiteCode = 'PS1';

SELECT DISTINCT SYS.Netbios_Name0, SYS.Operating_System_Name_and0,
  HWSCAN.LastHWScan, SWSCAN.LastScanDate, SWSCAN.LastCollectedFileScanDate, v_RA_System_SMSAssignedSites.SMS_Assigned_Sites0
FROM v_R_System SYS
LEFT JOIN v_GS_LastSoftwareScan SWSCAN on SYS.ResourceID = SWSCAN.ResourceID
LEFT JOIN v_GS_WORKSTATION_STATUS HWSCAN on SYS.ResourceID = HWSCAN.ResourceID left join v_RA_System_SMSAssignedSites on v_RA_System_SMSAssignedSites.ResourceID = SYS.ResourceID where v_RA_System_SMSAssignedSites.SMS_Assigned_Sites0 like @SMSSiteCode
order by LastHWScan desc