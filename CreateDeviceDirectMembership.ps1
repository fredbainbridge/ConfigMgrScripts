$DeviceName = "t441192vm"
$CollectionID = "DLX00139"
$ResourceID = (Get-CMDevice -Name $DeviceName).ResourceID
Add-CMDeviceCollectionDirectMembershipRule -CollectionId $CollectionID -ResourceId $ResourceID

Add-Type -AssemblyName System.speech
$speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
$speak.Speak("I love Fred.  He is great!")
