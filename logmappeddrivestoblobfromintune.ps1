# Define the variables
$storageAccountName = "kastinffilesld001"
$containerName = "intunelogs"  # Specify the container name you will be using
$blobName = "IntuneMappedDrivesLog.csv"
$localLogFilePath = "C:\Temp\$blobName"
$tempLogFilePath = "C:\Temp\TempIntuneMappedDrivesLog.csv"

# Ensure the directory exists
if (-not (Test-Path "C:\Temp")) {
    New-Item -ItemType Directory -Path "C:\Temp"
}

# Function to log mapped drives data
function Log-MappedDrives {
    $logEntries = @()

    # Determine the PowerShell version and select the appropriate method to get the UPN
    if ($PSVersionTable.PSVersion.Major -ge 3) {
        $upn = (Get-CimInstance -ClassName Win32_ComputerSystem).UserName
    } else {
        $upn = (Get-WmiObject -Class Win32_ComputerSystem).UserName
    }

    # Get the device name
    $deviceName = $env:COMPUTERNAME

    # Get all mapped drives from the registry
    $mappedDrives = Get-ItemProperty -Path "HKCU:\Network\*" | Select-Object -Property PSChildName, RemotePath

    foreach ($drive in $mappedDrives) {
        # Check if the drive is currently connected
        $connected = Test-Path ($drive.PSChildName + ":")

        $logEntries += [PSCustomObject]@{
            Timestamp   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            DriveLetter = $drive.PSChildName
            SharePath   = $drive.RemotePath
            Connected   = $connected
            UPN         = $upn
            DeviceName  = $deviceName
        }
    }

    # Export the log entries to a temporary CSV file
    $logEntries | Export-Csv -Path $tempLogFilePath -NoTypeInformation -Force
}

# Log the mapped drives
Log-MappedDrives

# Authenticate to Azure
$tenantId = "183a8d00-a3e2-443e-8074-20451397d0be"
$clientId = "ce1a5153-302f-469c-917b-ee00d62ef8c7"
$clientSecret = "~Vf8Q~lb6fYC~u2EzSxjtnZSHXeVtYlaWZ3KEa~w"

$secureClientSecret = ConvertTo-SecureString -String $clientSecret -AsPlainText -Force
$psCredential = New-Object System.Management.Automation.PSCredential ($clientId, $secureClientSecret)

# Suppress output from Connect-AzAccount
$null = Connect-AzAccount -ServicePrincipal -TenantId $tenantId -Credential $psCredential -ErrorAction Stop

# Download the existing log file from Azure Blob Storage if it exists
$sasToken = "sp=rcwl&st=2024-06-12T21:50:52Z&se=2025-06-13T05:50:52Z&spr=https&sv=2022-11-02&sr=c&sig=Qgf%2FMV1zFTR7GwY4ut%2BRIAxnxCnttHw9pzJkK39h%2F4Q%3D"
$context = New-AzStorageContext -StorageAccountName $storageAccountName -SasToken $sasToken
$blobUri = "https://$storageAccountName.blob.core.windows.net/$containerName/$blobName?$sasToken"

$blobExists = Get-AzStorageBlob -Container $containerName -Context $context | Where-Object { $_.Name -eq $blobName }

if ($blobExists) {
    Get-AzStorageBlobContent -Blob $blobName -Container $containerName -Destination $localLogFilePath -Context $context -Force

    # Import the existing log file
    $existingLog = Import-Csv $localLogFilePath

    # Check if any of the new entries already exist in the log file
    $newLogEntries = Import-Csv $tempLogFilePath | Where-Object {
        $existingLog -notcontains $_
    }

    # Append the new data to the existing log file if there are new entries
    if ($newLogEntries) {
        $newLogEntries | Export-Csv -Path $localLogFilePath -NoTypeInformation -Append -Force
    }
} else {
    # If the blob does not exist, rename the temp file to the final log file
    Rename-Item -Path $tempLogFilePath -NewName $localLogFilePath
}

# Upload the updated log file to Azure Blob Storage
try {
    $null = Set-AzStorageBlobContent -File $localLogFilePath -Container $containerName -Blob $blobName -Context $context -Force -Confirm:$false
} catch {
    exit 1
}

# Clean up the local files
Remove-Item -Path $localLogFilePath -Force -ErrorAction SilentlyContinue
Remove-Item -Path $tempLogFilePath -Force -ErrorAction SilentlyContinue
