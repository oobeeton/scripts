# Define the credential and folder details
$targetResource = "mplsprt.krausanderson.com" # Server name
$targetUser = "mwscan@krausanderson.com"
$targetPassword = "sc@nKA123!" # Consider using a more secure method for password handling
$oneDrivePath = [Environment]::GetFolderPath("MyDocuments") + "\SCANS"
$shareName = "SCANS"

# Function to normalize the SMB share name to handle case sensitivity
function Get-CorrectCasedShareName {
    param (
        [string]$ShareName
    )
    $allShares = Get-SmbShare -ErrorAction SilentlyContinue | Where-Object { $_.Name -ieq $ShareName }
    if ($allShares) {
        return $allShares.Name
    } else {
        return $null
    }
}

# Function to get the current configuration summary
function Get-ConfigurationSummary {
    Write-Host "--- Current Configuration ---"

    # Check for CMDKEY credentials
    $existingCredentials = cmdkey /list | Out-String
    $credentialStatus = if ($existingCredentials -match $targetResource -and $existingCredentials -match $targetUser) {"[VERIFIED]"} else {"[MISSING]"}
    Write-Host ("CMDKEY Credential for $($targetUser)@$($targetResource): $($credentialStatus)") -ForegroundColor $([String]::Equals($credentialStatus, "[VERIFIED]", [StringComparison]::OrdinalIgnoreCase) ? "Green" : "Red")

    # Check if Scans folder exists
    $folderStatus = if (Test-Path -Path $oneDrivePath) {"[VERIFIED]"} else {"[MISSING]"}
    Write-Host ("Scans Folder at $($oneDrivePath): $($folderStatus)") -ForegroundColor $([String]::Equals($folderStatus, "[VERIFIED]", [StringComparison]::OrdinalIgnoreCase) ? "Green" : "Red")

    # Check SMB Share status and display the associated directory
    $normalizedShareName = Get-CorrectCasedShareName -ShareName $shareName
    if ($normalizedShareName) {
        $share = Get-SmbShare -Name $normalizedShareName -ErrorAction SilentlyContinue
        Write-Host ("SMB Share '$normalizedShareName' exists and is connected to: $($share.Path)") -ForegroundColor "Green"
    } else {
        Write-Host ("SMB Share '$shareName': [MISSING]") -ForegroundColor "Red"
    }

    Write-Host "================================="
}


# Function to ensure the Scans folder exists and set NTFS permissions
function Ensure-ScansFolderAndPermissions {
    if (-not (Test-Path -Path $oneDrivePath)) {
        New-Item -Path $oneDrivePath -ItemType Directory | Out-Null
        Write-Host "Scans folder created at $oneDrivePath"
    }

    # Correctly formatted icacls command
    & icacls $oneDrivePath /grant 'Everyone:(OI)(CI)F' /T /C /Q
    Write-Host "Set NTFS permission: Full Control to Everyone for $oneDrivePath"
}

# Function to add Windows Credential
function Add-Credential {
    cmdkey /add:$targetResource /user:$targetUser /pass:$targetPassword
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Windows Credential successfully added: $targetUser@$targetResource" -ForegroundColor Green
    } else {
        Write-Host "Failed to add Windows Credential. Error code: $LASTEXITCODE" -ForegroundColor Red
    }
}

# Function to remove Windows Credential
function Remove-Credential {
    cmdkey /delete:$targetResource > $null
    Write-Host "Credential for $targetUser@$targetResource removed" -ForegroundColor Cyan
}

# Function to ensure SMB Share exists and set permissions
function Ensure-SMBShare {
    if (-not (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue)) {
        New-SmbShare -Name $shareName -Path $oneDrivePath -FullAccess Everyone
        Write-Host "SMB Share '$shareName' created with full access permissions to Everyone." -ForegroundColor Green
    } else {
        Write-Host "SMB Share '$shareName' already exists." -ForegroundColor Yellow
    }
}

# Function to remove SMB Share safely
function Remove-SMBShareSafely {
    param (
        [string]$ShareName
    )

    # Normalize the share name to match the actual case used on the system
    $correctCasedShareName = Get-CorrectCasedShareName -ShareName $ShareName

    if ($correctCasedShareName) {
        Write-Host "Attempting to remove SMB Share: '$correctCasedShareName'..."
        Remove-SmbShare -Name $correctCasedShareName -Force -Confirm:$false
        Write-Host "SMB Share '$correctCasedShareName' removed successfully." -ForegroundColor Cyan
    } else {
        Write-Host "SMB Share '$ShareName' does not exist or has already been removed. No action needed." -ForegroundColor Yellow
    }
}

# Function to close SMB connections before removing the share
function Close-SMBConnections {
    param (
        [string]$ShareName
    )

    # Get the open files for the share
    $openFiles = Get-SmbOpenFile | Where-Object { $_.ShareName -eq $ShareName }

    # Close each open file
    foreach ($file in $openFiles) {
        Close-SmbOpenFile -FileId $file.FileId -Force
        Write-Host "Closed open file: $($file.Path)"
    }

    # Get the sessions for the share
    $sessions = Get-SmbSession | Where-Object { $_.Dialect -ne "3.1.1" }

    # Close each session
    foreach ($session in $sessions) {
        Close-SmbSession -SessionId $session.SessionId -Force
        Write-Host "Closed SMB session from client: $($session.ClientComputerName)"
    }
}

# Main function to control the script flow
function Main {
    do {
        Get-ConfigurationSummary
        Write-Host "How would you like to proceed?"
        Write-Host "[1] Setup Scan-to-Folder"
        Write-Host "[2] Remove Scan-to-Folder"
        Write-Host "[3] Exit"
        $choice = Read-Host "Enter your choice"

        switch ($choice) {
            "1" {
                Add-Credential
                Ensure-ScansFolderAndPermissions
                Ensure-SMBShare
                Write-Host "Setup completed." -ForegroundColor Green
            }
            "2" {
                Remove-Credential
                $normalizedShareName = Get-CorrectCasedShareName -ShareName "Scans"
                if ($normalizedShareName) {
                    Close-SMBConnections -ShareName $normalizedShareName
                    Remove-SMBShareSafely -ShareName $normalizedShareName
                } else {
                    Write-Host "Share 'Scans' not found or already removed." -ForegroundColor Yellow
                }
            }
            "3" {
                Write-Host "Exiting script..." -ForegroundColor Yellow
                break
            }
            default {
                Write-Host "Invalid option, please try again." -ForegroundColor Red
            }
        }
    } while ($choice -ne "3")
}

# Invoke the main function to start the script
Main
