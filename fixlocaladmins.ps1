
Function Convert-AzureAdObjectIdToSid {
    <#
    .SYNOPSIS
    Convert an Azure AD Object ID to SID
     
    .DESCRIPTION
    Converts an Azure AD Object ID to a SID.
    Author: Oliver Kieselbach (oliverkieselbach.com)
    The script is provided "AS IS" with no warranties.
     
    .PARAMETER ObjectID
    The Object ID to convert
    #>
    
        param([String] $ObjectId)
    
        $bytes = [Guid]::Parse($ObjectId).ToByteArray()
        $array = New-Object 'UInt32[]' 4
    
        [Buffer]::BlockCopy($bytes, 0, $array, 0, 16)
        $sid = "S-1-12-1-$array".Replace(' ', '-')
    
        return $sid
    }
    
#$objectId = "c4366e41-9793-4aa5-b559-237d3cb60a33"
#$objectId = "3d21e7cd-4842-4a7c-9470-76f38034a89c"
$objectId = "b734a4d2-f01e-4ed3-b551-06b9233f19d8"

$SID = Convert-AzureAdObjectIdToSid -ObjectId $objectId
Write-Output $SID