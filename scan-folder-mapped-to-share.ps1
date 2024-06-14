# Define the expected local directory path and the UNC path of the share
$expectedFolderPath = "C:\Users\$env:USERNAME\OneDrive - Kraus-Anderson\Documents\SCANS"
$sharePath = "\\localhost\scans"

# Function to check if the share is mapped to the expected local folder
function Verify-ShareMapping {
    param (
        [string]$sharePath,
        [string]$expectedFolderPath
    )
    $shareInfo = Get-WmiObject -Class Win32_Share -Filter "Name='scans'" | Select-Object -ExpandProperty Path
    if ($shareInfo -eq $expectedFolderPath) {
        return $true
    } else {
        return $false
    }
}

# Ensure the expected folder exists
if (-not (Test-Path -Path $expectedFolderPath)) {
    New-Item -Path $expectedFolderPath -ItemType Directory -Force
    write-host "Folder created: $expectedFolderPath"
}

# Verify if the share is correctly mapped to the expected local folder
if (Verify-ShareMapping -sharePath $sharePath -expectedFolderPath $expectedFolderPath) {
    write-host "Scan share is correctly mapped to $expectedFolderPath"
    exit 0  # Success
} else {
    write-host "Scan share is not correctly mapped or does not exist."
    exit 1  # Failure
}
