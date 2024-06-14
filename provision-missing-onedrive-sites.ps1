# Variables
$tenantId = "183a8d00-a3e2-443e-8074-20451397d0be"
$clientId = "ce1a5153-302f-469c-917b-ee00d62ef8c7"
$clientSecret = "Fu68Q~SZf9MPJlnSmUCcLFFLyTSMhCHeq4XGmdzp"


# Connect to Microsoft Graph
$credential = New-Object Microsoft.Graph.PowerShell.Authentication.Models.MsalClientCredential -ArgumentList $clientId, $clientSecret
Connect-MgGraph -ClientId $clientId -TenantId $tenantId -Credential $credential -Scopes "AuditLog.Read.All"

# Connect to SharePoint Online
$adminUrl = "https://krausanderson-admin.sharepoint.com/"
$spCredential = Get-Credential
Connect-SPOService -Url $adminUrl -Credential $spCredential



# Get all Azure AD users
$users = Get-AzureADUser -All $true

# Filter for users with any assigned license
$licensedUsers = $users | Where-Object { $_.AssignedLicenses -ne $null -and $_.AssignedLicenses.Count -gt 0 }

# List to hold eligible users
$eligibleUsers = @()

# Current date for comparison
$currentDate = Get-Date

# Check each licensed user
foreach ($user in $licensedUsers) {
    $personalSiteUrl = "https://krausanderson-admin.sharepoint.com/" + $user.UserPrincipalName.Replace("@","_")
    $userCreationDate = $user.CreatedDateTime
    # Get User Sign-In Logs
    #$userSignInLogs = Get-MgAuditLogSignIn -Filter "userId eq '$($user.Id)' and createdDateTime ge $currentDate.AddMonths(-1)" -Top 1

    # Check if user was created in the last month and has no existing OneDrive site
    if ($userCreationDate -gt $currentDate.AddMonths(-1)) {
        try {
            $site = Get-SPOSite -Identity $personalSiteUrl -ErrorAction Stop
        } catch {
            # Site doesn't exist - Add user to the list with additional info
            $eligibleUsers += [PSCustomObject]@{
                UserPrincipalName = $user.UserPrincipalName
                CreatedDate = $userCreationDate
                #SignInCount = $userSignInLogs.Count
            }
        }
    }
}

# Display in GridView and allow selection
$selectedUsers = $eligibleUsers | Out-GridView -Title "Select Users for OneDrive Provisioning" -OutputMode Multiple

# Provision OneDrive sites for selected users
if ($selectedUsers.Count -gt 0) {
    $selectedUserEmails = $selectedUsers.UserPrincipalName
    Request-SPOPersonalSite -UserEmails $selectedUserEmails
    Write-Host "OneDrive sites requested for the following users:" -ForegroundColor Green
    Write-Host ($selectedUserEmails -join ", ")
} else {
    Write-Host "No users selected for OneDrive provisioning." -ForegroundColor Yellow
}

# Disconnect the SharePoint Online session
Disconnect-SPOService
