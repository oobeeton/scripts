# Variables
$tenantId = "183a8d00-a3e2-443e-8074-20451397d0be"
$clientId = "ce1a5153-302f-469c-917b-ee00d62ef8c7"
$clientSecret = "YourClientSecretHere"

# Connect to Microsoft Graph
$credential = New-Object Microsoft.Graph.PowerShell.Authentication.Models.MsalClientCredential -ArgumentList $clientId, $clientSecret
Connect-MgGraph -ClientId $clientId -TenantId $tenantId -Credential $credential -Scopes "Sites.Read.All", "User.Read.All"

# Connect to SharePoint Online
$adminUrl = "https://krausanderson-admin.sharepoint.com/"
$spCredential = Get-Credential
Connect-SPOService -Url $adminUrl -Credential $spCredential

# Get all users with OneDrive sites
$users = Get-MgUser -All $true | Where-Object { $_.Mail -ne $null }

# Prepare list to hold user OneDrive info
$userOneDriveInfo = @()

foreach ($user in $users) {
    $oneDriveUrl = "https://krausanderson-my.sharepoint.com/personal/" + $user.UserPrincipalName.Replace("@","_") + "/Documents"
    try {
        $oneDriveSite = Get-SPOSite -Identity $oneDriveUrl -ErrorAction Stop
        $scansFolderExists = $false
        $scansFolderCreatedDate = $null
        $lastAccessed = $oneDriveSite.LastContentModifiedDate

        # Check for SCANS folder
        $scansFolderPath = $oneDriveUrl + "/SCANS"
        try {
            $scansFolder = Get-SPOFolder -Site $oneDriveSite.Url -FolderUrl $scansFolderPath -ErrorAction Stop
            $scansFolderExists = $true
            $scansFolderCreatedDate = $scansFolder.TimeCreated
        } catch {
            $scansFolderExists = $false
        }

        $userOneDriveInfo += [PSCustomObject]@{
            UserPrincipalName = $user.UserPrincipalName
            OneDriveSite = $oneDriveSite.Url
            SCANSFolderExists = $scansFolderExists
            SCANSFolderCreatedDate = $scansFolderCreatedDate
            LastAccessed = $lastAccessed
        }
    } catch {
        # OneDrive site doesn't exist or can't be accessed
    }
}

# Display the information
$userOneDriveInfo | Format-Table -AutoSize

# Disconnect the SharePoint Online session
Disconnect-SPOService
