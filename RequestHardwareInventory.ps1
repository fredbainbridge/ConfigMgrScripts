$ComputerName = "M088964744953"
$MachinePolicy = "00000000-0000-0000-0000-000000000021"
$HardwareInventory = "00000000-0000-0000-0000-000000000001"
$SMSCli = [wmiclass] "\\$ComputerName\root\ccm:SMS_Client"
$SMSCli.TriggerSchedule("{$MachinePolicy}")