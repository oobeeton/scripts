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

# Retrieve object metadata from all domain controllers for the selected user
$metadataResults = @{}
foreach ($dc in $domainControllers) {
    $metadataResults[$dc] = Get-ObjectMetadata -DC $dc -DN $user.DistinguishedName
}

# Compare metadata results
$differencesDetected = $false
$baseDC = $domainControllers[0]
$baseMetadata = $metadataResults[$baseDC].Split("`n")

foreach ($dc in $domainControllers[1..($domainControllers.Count - 1)]) {
    $compareMetadata = $metadataResults[$dc].Split("`n")

    # Compare line by line
    $differentLines = Compare-Object $baseMetadata $compareMetadata | Where-Object SideIndicator -EQ '=>'

    if ($differentLines) {
        Write-Host "Differences detected between $baseDC and $dc for user $($user.SamAccountName):" -ForegroundColor Red
        $differentLines | ForEach-Object { Write-Host $_.InputObject }
        $differencesDetected = $true
    }
}

if (-not $differencesDetected) {
    Write-Host "No differences detected for user $($user.SamAccountName) across all domain controllers." -ForegroundColor Green
}
