# Define the credential details
$targetResource = "mplsprt.krausanderson.com" # Server name
$targetUser = "mwscan@krausanderson.com"
$targetPassword = "sc@nKA123!"

# Shared folder path
$sharedFolderPath = "\\localhost\scans"
$oneDrivePath = [Environment]::GetFolderPath("MyDocuments") + "\OneDrive\Scans"

# Expected permissions
$expectedPermissions = @(
    @{IdentityReference="Everyone"; FileSystemRights="FullControl"; AccessControlType="Allow"},
    @{IdentityReference="KRAUSANDERSON\Domain Users"; FileSystemRights="FullControl"; AccessControlType="Allow"},
    @{IdentityReference="KRAUSANDERSON\Domain Admins"; FileSystemRights="FullControl"; AccessControlType="Allow"},
    @{IdentityReference="KRAUSANDERSON\MWSCAN"; FileSystemRights="FullControl"; AccessControlType="Allow"},
    @{IdentityReference="mwscan"; FileSystemRights="FullControl"; AccessControlType="Allow"}
)

function Add-Credential {
    cmdkey /add:$targetResource /user:$targetUser /pass:$targetPassword
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Windows Credential successfully added: $targetUser@$targetResource" -ForegroundColor Green
    } else {
        Write-Host "Failed to add Windows Credential. Error code: $LASTEXITCODE" -ForegroundColor Red
    }
}

function Check-AndAdd-Credential {
    $credentialExists = $false

    Write-Host "Checking existing credentials for $targetResource..." -ForegroundColor Cyan
    try {
        $existingCredentials = cmdkey /list | Out-String
        if ($existingCredentials -match "$targetResource" -and $existingCredentials -match "$targetUser") {
            $credentialExists = $true
        }
    } catch {
        Write-Host "An error occurred while checking for existing credentials." -ForegroundColor Red
    }

    if (-not $credentialExists) {
        Write-Host "Adding missing credential..." -ForegroundColor Yellow
        Add-Credential
    } else {
        Write-Host "Credential already present and working correctly: $targetUser@$targetResource" -ForegroundColor Green
    }
}

function CheckAndRemediate-FolderPermission {
    param (
        [string]$Path,
        [array]$ExpectedPermissions
    )

    Write-Host "Checking and remediating folder permissions for $Path..." -ForegroundColor Cyan
    # ... [Rest of the function as in your original script]
}

function Ensure-ScansFolderExists {
    if (-not (Test-Path -Path $oneDrivePath)) {
        Write-Host "Creating Scans folder at $oneDrivePath..." -ForegroundColor Yellow
        New-Item -Path $oneDrivePath -ItemType Directory
        CheckAndRemediate-FolderPermission -Path $oneDrivePath -ExpectedPermissions $expectedPermissions
    } else {
        Write-Host "Scans folder already exists at $oneDrivePath" -ForegroundColor Green
    }
}

# Execution starts here
Check-AndAdd-Credential
Ensure-ScansFolderExists
