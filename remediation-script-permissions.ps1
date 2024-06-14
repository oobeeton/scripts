# Define the credential details
$targetResource = "\\mplsprt.krausanderson.com"
$targetUser = "mwscan@krausanderson.com"
$targetPassword = "sc@nKA123!"

function Add-Credential {
    cmdkey /add:$targetResource /user:$targetUser /pass:$targetPassword
    Write-Host "Windows Credential successfully added: $targetUser@$targetResource"
}

function Check-AndAdd-Credential {
    $credentialExists = $false

    try {
        $existingCredentials = cmdkey /list | Select-String $targetResource
        if ($existingCredentials -and $existingCredentials.ToString().Contains($targetUser)) {
            $credentialExists = $true
        }
    } catch {
        Write-Host "An error occurred while checking for existing credentials."
    }

    if (-not $credentialExists) {
        Add-Credential
    } else {
        Write-Host "Windows Credential already present and working correctly: $targetUser@$targetResource"
    }
}

# Run the check and add function
Check-AndAdd-Credential
