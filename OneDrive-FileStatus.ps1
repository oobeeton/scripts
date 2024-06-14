$tenantId = "183a8d00-a3e2-443e-8074-20451397d0be"
$clientId = "ce1a5153-302f-469c-917b-ee00d62ef8c7"
$clientSecret = "Fu68Q~SZf9MPJlnSmUCcLFFLyTSMhCHeq4XGmdzp"
$resource = "https://graph.microsoft.com"

$body = @{
    client_id     = $clientId
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $clientSecret
    grant_type    = "client_credentials"
}

$response = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -ContentType "application/x-www-form-urlencoded" -Body $body

$token = $response.access_token


# Import necessary module
Import-Module Microsoft.PowerShell.Utility

# Initialize an array to hold the results
$results = @()

# Function to make API requests
function Invoke-GraphRequest {
    param (
        [string]$Url,
        [string]$AccessToken
    )

    $headers = @{
        Authorization = "Bearer $AccessToken"
    }

    return (Invoke-RestMethod -Uri $Url -Headers $headers -Method Get)
}

# Set the base Graph API URL and your access token
$graphApiUrl = 'https://graph.microsoft.com/v1.0/'
$accessToken = $token  # This is the token you obtained

# Initialize log file
$logFile = "OneDrivePollingLog.txt"

# Get all users
$users = Invoke-GraphRequest -Url "${graphApiUrl}users" -AccessToken $accessToken

# Iterate through each user to find the targeted folder
foreach ($user in $users.value) {
    $userId = $user.id
    $oneDriveUrl = $user.mySite

    try {
        # Fetch the list of folders in the root of the Documents library
        $folders = Invoke-GraphRequest -Url "${graphApiUrl}users/$userId/drive/root:/Documents:/children" -AccessToken $accessToken
        $targetFolder = $folders.value | Where-Object { $_.name -like '*.*' }  # Folders with a period in the name

        foreach ($folder in $targetFolder) {
            $folderId = $folder.id
            $folderDetails = Invoke-GraphRequest -Url "${graphApiUrl}users/$userId/drive/items/$folderId" -AccessToken $accessToken
            $sizeInBytes = $folderDetails.size
            $totalCount = $folderDetails.childCount

            # Log the results
            $logMessage = "User: $($user.displayName), UPN: $($user.userPrincipalName), Targeted Folder Size: $sizeInBytes bytes, Total Count: $totalCount, OneDrive URL: $oneDriveUrl"
            Write-Host $logMessage
            Add-Content -Path $logFile -Value $logMessage

            $results += [PSCustomObject]@{
                DisplayName    = $user.displayName
                UPN            = $user.userPrincipalName
                TargetFolder   = $folder.name
                TotalSizeBytes = $sizeInBytes
                TotalCount     = $totalCount
                OneDriveURL    = $oneDriveUrl
            }
        }

        # Minimal rate limit: pause for 2 seconds before the next API call
        Start-Sleep -Seconds 2
        
    } catch {
        $errorMessage = "Failed to fetch data for user: $($user.displayName)"
        Write-Host $errorMessage
        Add-Content -Path $logFile -Value $errorMessage
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path "TargetedOneDriveFoldersSizes2.csv" -NoTypeInformation
