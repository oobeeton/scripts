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

        # Add each domain controller and its result as a separate entry
        foreach ($dc in $domainControllers) {
            $summary += [PSCustomObject]@{
                UserName = $user.SamAccountName
                DomainController = $dc
                AttributesTotal = $metadataResults[$dc]
                MaxAttributes = ($metadataResults.Values | Measure-Object -Maximum).Maximum
                MinAttributes = ($metadataResults.Values | Measure-Object -Minimum).Minimum
            }
        }
    }

    return $summary
}

function Get-ExpandedAttributeData {
    param (
        [Parameter(Mandatory=$true)]
        [string]$UserName
    )

    $user = Get-ADUser -Filter { SamAccountName -eq $UserName }
    $dcs = (Get-ADDomainController -Filter *).HostName

    $results = @()

    foreach ($dc in $dcs) {
        $metadata = repadmin /showobjmeta $dc $user.DistinguishedName | Where-Object { $_ -notmatch "Object metadata" }
        $results += $metadata
    }

    return $results
}

do {
    # Get all active domain users and present them in a grid view to the user for selection
    $users = Get-ADUser -Filter 'Enabled -eq $true' | 
             Select-Object Name, SamAccountName, DistinguishedName | 
             Out-GridView -Title "Select one or multiple users to compare" -OutputMode Multiple

    # If no user is selected, exit
    if (-not $users) {
        Write-Host "No user selected. Exiting..."
        exit
    }

    $results = Get-DistinctAttributes -Users $users

    # Display with colorized discrepancies
    $processedUsers = @()
    foreach ($result in $results) {
        if ($result.UserName -notin $processedUsers) {
            $processedUsers += $result.UserName
            if ($result.MaxAttributes -eq $result.MinAttributes) {
                Write-Host ("{0,-25} {1,-25}" -f $result.UserName, $result.AttributesTotal)
            } else {
                foreach ($dcResult in $results | Where-Object { $_.UserName -eq $result.UserName }) {
                    if ($dcResult.AttributesTotal -ne $dcResult.MaxAttributes) {
                        Write-Host ("{0,-25} {1,-25} {2,-15}" -f $dcResult.UserName, $dcResult.DomainController, $dcResult.AttributesTotal) -ForegroundColor Red
                    } else {
                        Write-Host ("{0,-25} {1,-25} {2,-15}" -f $dcResult.UserName, $dcResult.DomainController, $dcResult.AttributesTotal)
                    }
                }

                $choiceExpand = Read-Host "Discrepancy detected for $($result.UserName). Do you want to view expanded attribute data? (yes/no)"
                if ($choiceExpand -eq 'yes') {
                    $expandedData = Get-ExpandedAttributeData -UserName $result.UserName
                    $expandedData | Format-Table -AutoSize
                }
            }
        }
    }

    # Prompt to search again or exit
    $choice = Read-Host "Do you want to search again? (yes/no)"

} while ($choice -eq 'yes')

Write-Host "Exiting script."
