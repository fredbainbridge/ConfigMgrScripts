<#
.Synopsis
    Get a sharepoint list object
.DESCRIPTION
    Using an existing sharepoint WSDL, create an instance of a webservice and then call the GetList function.
    Sharepoint view fields are based on the name of the column in a sharepoint list.
    SharePoint is case sensitive!
    Column names returned in the output are ows_[name], but when you pass them in they are just [name]
.EXAMPLE
    Get-SPList -URI "http://sharepointsite/sitename/_vti_bin/Lists.asmx?wsdl -SharePointListName "MySharePointList" -ColumnName "ID","Title","Vendor"
#>
function Get-SPList
{
    
    [CmdletBinding()]
    [OutputType([Object[]])]
    Param
    (
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false,
                   Position=0)]
        [string] $URI = "http://inside.deluxe.com/it/home/infrastructure-and-operations/client/DeskArchEng/_vti_bin/Lists.asmx?wsdl",
        [string] $SharePointListName = "Application Tracking",
        [string[]] $ColumnNames = [string[]]("ID","Title","Vendor"),
        [string] $QueryColumn = "Demand_x0020_Status",
        [string] $QueryValue = "2.1.5 UAT PREP"
    )

    Begin
    {
        #Maybe put some logging in here
    }
    Process
    {
        #Prepare the ViewFieldsXML
        $ColumnNames | ForEach-Object {
            $ViewFieldsXML = $ViewFieldsXML + "<FieldRef Name=`"$PSItem`"/>"
        }
        #get sharepoint web service connection
        $service = New-WebServiceProxy -Uri $URI  -Namespace SpWs -UseDefaultCredential
        
        #the status field is ows_Demand_x0020_Status
        #This sets up the XML to use the webservice.
        $xmlDoc = new-object System.Xml.XmlDocument            
        $query = $xmlDoc.CreateElement("Query")            
        $viewFields = $xmlDoc.CreateElement("ViewFields") 

        #define your view fields with the name of SharePoint columns.  
        $viewFields.set_InnerXML($ViewFieldsXML)      
        $queryOptions = $xmlDoc.CreateElement("QueryOptions")            
        $query.set_InnerXml("<Where><Eq><FieldRef Name='$QueryColumn'/><Value Type='Text'>$QueryValue</Value></Eq></Where>")             
        $rowLimit = "100"
        
        $ListItems = $service.GetListItems($SharePointListName, "", $query, $viewfields, $rowLimit, $queryOptions, "") 
        
        Write-Output $ListItems.Data.Row
    }
    End
    {
        #some logging here
    }
}


function Update-SPList
{
<#
.Synopsis
   Update a SharePoint List based on row ID
.DESCRIPTION
   Using a Hashtable with column / value pairs to update a sharepoint list item based on its rowID.    

.EXAMPLE
   Update-SharepointList -URI "http://sharepoint/site/_vti_bin/Lists.asmx?wsdl" -SharePointListName "YourListName" -RowID 101 -ColumnValuePairs $hashTable

#>
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false,
                   Position=0)]
        [string] $URI = "http://inside.deluxe.com/it/home/infrastructure-and-operations/client/DeskArchEng/_vti_bin/Lists.asmx?wsdl",
        [string] $SharePointListName = "Application Tracking",
        [Parameter(Mandatory=$true)]
        [string] $RowID,
        [Parameter(Mandatory=$true)]
        [Hashtable] $ColumnValuePairs

    )

    Begin
    {
    }
    Process
    {
        #get sharepoint web service connection
        $service = New-WebServiceProxy -Uri $URI  -Namespace SpWs -UseDefaultCredential
        $listView = $service.getlistandview($SharePointListName, "")            
        $strListID = $listview.childnodes.item(0).name            
        $strViewID = $listview.childnodes.item(1).name

        $xmlDoc = new-object system.xml.xmldocument 
                        
        $batchElement = $xmlDoc.createelement("Batch")
        $batchElement.setattribute("onerror", "continue")
        $batchElement.setattribute("listversion", "1")
        $batchElement.setattribute("viewname", $strViewID)

        #Prepare the XML
        $xml = "<Method ID='1' Cmd='Update'><Field Name = 'ID'>$rowID</Field>"
        $ColumnValuePairs.keys | ForEach-Object {
            $Value = $ColumnValuePairs[$PSItem]
            $xml = $xml + "<Field Name = '$PSitem'>$Value</Field>"          
        }
        $xml = $xml + "</Method>"

        $batchelement.InnerXml = $xml
        try {           
            $response = $service.updatelistitems($SharePointListName, $batchelement)             
            $response = $response.InnerText            
        }            
        catch {             
            Write-Verbose "Encountered an error while updating sharepoint the error is: $error"
        } 
        if($response -ne "0x00000000"){
            write-verbose "Something strange happened with the sharepoint update, an unexpected return code was encountered. Update may or may not have happened. Return Code: $response"
        }
    }
    End
    {
    }
}

#Example of usage.  This will take the first item returned and update the Vendor and Title of the record.  
#Modify to match your column names


#Get-SPList -QueryValue "2.1.5 UAT PREP"| ForEach-Object{
"2.1.5 UAT PREP","2.2 UAT", "2.5 SWD/SBDC"| foreach-object { 
    $status = $PSItem
    Get-SPList -QueryValue $PSItem | ForEach-Object{
        $AlreadyExists = $false
        $Title = $PSItem.ows_Title
        $TitleArray = ("PROD","UAT","PILOT") | foreach-object { 
            if(Get-CMApplication -Name ($PSItem+" - $Title")){
                $AlreadyExists = $true
                write-host ($PSItem+" - $Title - EXISTS")
            }
        }
        if(-not $AlreadyExists) {
            write-host ("$Status - $Title - DNE")
        }
    
    }
}

$rowID = $listItems[0].ows_ID
<#
$hashTable = @{};
$hashTable.add("Vendor","New Vendor")
$hashTable.add("Title", "New Title")

Update-SPList -RowID $rowID -ColumnValuePairs $hashTable -Verbose

#>