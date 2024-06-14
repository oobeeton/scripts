# Install AzureAD module if not already installed
if (-not (Get-Module -Name "AzureAD" -ErrorAction SilentlyContinue)) {
    Install-Module -Name "AzureAD" -Force -Scope CurrentUser
}

# Import AzureAD module
Import-Module AzureAD

# Connect to Azure AD
Connect-AzureAD

# Initialize an empty array to store unique users
$uniqueUsers = @()

# Get all users from Azure AD
$users = Get-AzureADUser -All $true | Where-Object {$_.AccountEnabled -eq $true}

# Loop through each user
foreach ($user in $users) {
    # Check if the user is already in the list
    $existingUser = $uniqueUsers | Where-Object {$_.JobTitle -eq $user.JobTitle -and $_.OfficeLocation -eq $user.OfficeLocation}
    
    # If the user is not already in the list, add them
    if (-not $existingUser) {
        $uniqueUsers += $user
    }
}

# Output the unique users
$uniqueUsers
