function Check-ShareExists {
    param (
        [string]$SharePath
    )

    try {
        # Check if the share exists by attempting to access it
        if (Test-Path -Path $SharePath) {
            return $true
        } else {
            return $false
        }
    }
    catch {
        return $false
    }
}

function Check-LocalUserExists {
    param (
        [string]$Username
    )

    try {
        # Attempt to get the local user
        Get-LocalUser -Name $Username -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Check if 'mwscan' user exists and if '\\localhost\scans' share exists
$userExists = Check-LocalUserExists -Username "mwscan"
$shareExists = Check-ShareExists -SharePath "\\localhost\scans"

# If both user and share exist, return success, otherwise return failure
return $userExists -and $shareExists
