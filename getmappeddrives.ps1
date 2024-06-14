# Define the directory containing the GPO XML files
$xmlDirectory = "C:\scripts\gpos"
$csvFilePath = "MappedDrivesReport2.csv"

# Function to parse each GPO XML file for mapped drives
function Get-MappedDrivesFromXml {
    param (
        [string]$xmlPath
    )

    $xml = [xml](Get-Content -Path $xmlPath)

    # Add the namespaces from the XML
    $namespaceManager = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $namespaceManager.AddNamespace("q1", "http://www.microsoft.com/GroupPolicy/Settings/DriveMaps")
    $namespaceManager.AddNamespace("gp", "http://www.microsoft.com/GroupPolicy/Settings")
    $namespaceManager.AddNamespace("types", "http://www.microsoft.com/GroupPolicy/Types")

    $mappedDrives = @()
    $trusteePermissions = @()

    # Ensure we are correctly identifying the nodes
    $driveMaps = $xml.SelectNodes('//gp:ExtensionData/gp:Extension/q1:DriveMapSettings/q1:Drive', $namespaceManager)
    $somPath = $xml.SelectSingleNode('//gp:LinksTo/gp:SOMPath', $namespaceManager)?.InnerText
    $permissions = $xml.SelectNodes('//types:TrusteePermissions/types:Trustee/types:Name', $namespaceManager)

    if ($permissions -ne $null) {
        foreach ($permission in $permissions) {
            $trusteePermissions += $permission.InnerText
        }
    }

    if ($driveMaps -ne $null -and $driveMaps.Count -gt 0) {
        foreach ($driveMap in $driveMaps) {
            $driveLetter = $driveMap.SelectSingleNode('q1:Properties/@letter', $namespaceManager)?.Value
            $sharePath = $driveMap.SelectSingleNode('q1:Properties/@path', $namespaceManager)?.Value
            $label = $driveMap.SelectSingleNode('q1:Properties/@label', $namespaceManager)?.Value

            if ($driveLetter -and $sharePath) {
                $mappedDrives += [pscustomobject]@{
                    DriveLetter = $driveLetter
                    SharePath   = $sharePath
                    Label       = $label
                    SOMPath     = $somPath
                    TrusteePermissions = ($trusteePermissions -join ', ')
                }
            }
        }
    }

    return $mappedDrives
}

# Create the CSV file with headers if it doesn't exist
if (-not (Test-Path $csvFilePath)) {
    $null = @(
        [pscustomobject]@{
            GPOName     = ""
            DriveLetter = ""
            SharePath   = ""
            Label       = ""
            SOMPath     = ""
            TrusteePermissions = ""
        }
    ) | Export-Csv -Path $csvFilePath -NoTypeInformation
}

# Process each XML file in the directory
foreach ($xmlFile in Get-ChildItem -Path $xmlDirectory -Filter *.xml) {
    $gpoName = $xmlFile.BaseName

    $mappedDrives = Get-MappedDrivesFromXml -xmlPath $xmlFile.FullName

    if ($mappedDrives.Count -gt 0) {
        foreach ($drive in $mappedDrives) {
            $entry = [pscustomobject]@{
                GPOName     = $gpoName
                DriveLetter = $drive.DriveLetter
                SharePath   = $drive.SharePath
                Label       = $drive.Label
                SOMPath     = $drive.SOMPath
                TrusteePermissions = $drive.TrusteePermissions
            }

            # Append the entry to the CSV file
            $entry | Export-Csv -Path $csvFilePath -Append -NoTypeInformation
        }
    }
}

"Report has been generated and saved to $csvFilePath"
