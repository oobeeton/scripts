# Ensure Active Directory module is imported
Import-Module ActiveDirectory

# Get all domain controllers
$domainControllers = (Get-ADDomainController -Filter *).HostName

# Get all active domain users and present them in a grid view to the user for selection
$user = Get-ADUser -Filter 'Enabled -eq $true' | 
        Select-Object Name, SamAccountName, DistinguishedName | 
        Out-GridView -PassThru -Title "Select a user to compare"

# Exit if no user is selected
if (-not $user) {
    Write-Host "No user selected. Exiting..."
    exit
}

# Function to retrieve object metadata from a domain controller
function Get-ObjectMetadata {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DC,
        [Parameter(Mandatory=$true)]
        [string]$DN
    )

    repadmin /showobjmeta $DC $DN | Where-Object { $_ -notmatch "Object metadata" } | Out-String
}

# Data structure to capture discrepancies
$discrepancies = @()

# Retrieve object metadata from all domain controllers for the selected user
$metadataResults = @{}
foreach ($dc in $domainControllers) {
    $metadataResults[$dc] = Get-ObjectMetadata -DC $dc -DN $user.DistinguishedName
}

# Compare metadata results
foreach ($dc1 in $domainControllers) {
    foreach ($dc2 in $domainControllers) {
        if ($dc1 -ne $dc2) {
            $diffLines = Compare-Object ($metadataResults[$dc1] -split "`n") ($metadataResults[$dc2] -split "`n") 

            foreach ($diff in $diffLines) {
                $line = $diff.InputObject.Trim()
                if ($line -match "(?<attr>\w+)\s+ver\s+(?<ver>\d+)\s+originating\s+change\s+(?<time>.+?)\s+(?<originDC>\S+)") {
                    $discrepancies += [PSCustomObject]@{
                        Attribute = $matches['attr']
                        Version = $matches['ver']
                        Time = $matches['time']
                        OriginatingDC = $matches['originDC']
                        AffectedDCs = "$dc1, $dc2"
                    }
                }
            }
        }
    }
}

# Display discrepancies
if ($discrepancies.Count -eq 0) {
    Write-Host "No differences detected for user $($user.SamAccountName) across all domain controllers." -ForegroundColor Green
} else {
    Write-Host "Differences detected for user $($user.SamAccountName):" -ForegroundColor Red
    $discrepancies | Sort-Object Attribute, Version | Out-GridView -Title "Discrepancies Detected"
}
