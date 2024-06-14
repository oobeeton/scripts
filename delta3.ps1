# Ensure Active Directory module is imported
Import-Module ActiveDirectory

function Get-DistinctAttributes {
    param (
        [Parameter(Mandatory=$true)]
        [array]$Users
    )

    # Get all domain controllers
    $domainControllers = (Get-ADDomainController -Filter *).HostName

    # Data structure to capture discrepancies
    $summary = @()

    foreach ($user in $Users) {
        # Retrieve object metadata from all domain controllers for the selected user
        $metadataResults = @{}
        foreach ($dc in $domainControllers) {
            $metadataResults[$dc] = (repadmin /showobjmeta $dc $user.DistinguishedName | Where-Object { $_ -notmatch "Object metadata" }).Count
        }

        $isDiscrepant = ($metadataResults.Values | Get-Unique).Count -gt 1

        # Add each domain controller and its result as a separate entry
        foreach ($dc in $domainControllers) {
            $summary += [PSCustomObject]@{
                UserName = $user.SamAccountName
                DomainController = $dc
                AttributesTotal = $metadataResults[$dc]
                IsDiscrepant = $isDiscrepant
            }
        }
    }

    return $summary
}

do {
    # Get all active domain users that are likely synced with Azure AD and present them in a grid view to the user for selection
    $users = Get-ADUser -Filter 'Enabled -eq $true -and msDS-ConsistencyGuid -like "*"' | 
             Select-Object Name, SamAccountName, DistinguishedName | 
             Out-GridView -Title "Select one or multiple users to compare" -OutputMode Multiple

    # If no user is selected, exit
    if (-not $users) {
        Write-Host "No user selected. Exiting..."
        exit
    }

    $results = Get-DistinctAttributes -Users $users

    $discrepantResults = $results | Where-Object { $_.IsDiscrepant }
    $normalResults = $results | Where-Object { -not $_.IsDiscrepant }

    $normalResults | Format-Table -AutoSize

    if ($discrepantResults) {
        Write-Host "Discrepancies found:" -ForegroundColor Red
        $discrepantResults | Format-Table -AutoSize -Property UserName, DomainController, AttributesTotal | ForEach-Object {
            Write-Host $_ -ForegroundColor Red
        }
    }

    # Prompt to search again or exit
    $choice = Read-Host "Do you want to search again? (yes/no)"

} while ($choice -eq 'yes')

Write-Host "Exiting script."
