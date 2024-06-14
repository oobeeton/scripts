# Define the variables
$storageAccountName = "kastinffilesld001"
$containerName = "intunelogs"  # Specify the container name you will be using
$blobName = "IntuneMappedDrivesLog.csv"
$logFilePath = "C:\Temp\IntuneMappedDrivesLog.csv"

# Ensure the directory exists
if (-not (Test-Path "C:\Temp")) {
    New-Item -ItemType Directory -Path "C:\Temp"
}

# Function to log mapped drives data
function Log-MappedDrives {
    $logEntries = @()

    # Get all mapped drives
    $mappedDrives = Get-CimInstance -ClassName Win32_MappedLogicalDisk

    foreach ($drive in $mappedDrives) {
        $logEntries += [PSCustomObject]@{
            Timestamp    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            DriveLetter  = $drive.DeviceID
            SharePath    = $drive.ProviderName
            Persistence  = $drive.Persistent
        }
    }

    # Export the log entries to a CSV file
    $logEntries | Export-Csv -Path $logFilePath -NoTypeInformation -Append -Force
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

# Upload the log file to Azure Blob Storage
$sasToken = "sp=rcwl&st=2024-06-12T21:50:52Z&se=2025-06-13T05:50:52Z&spr=https&sv=2022-11-02&sr=c&sig=Qgf%2FMV1zFTR7GwY4ut%2BRIAxnxCnttHw9pzJkK39h%2F4Q%3D"
$context = New-AzStorageContext -StorageAccountName $storageAccountName -SasToken $sasToken
$blobUri = "https://$storageAccountName.blob.core.windows.net/$containerName/$blobName?$sasToken"

# Suppress output and confirm prompts from Set-AzStorageBlobContent
try {
    $null = Set-AzStorageBlobContent -File $logFilePath -Container $containerName -Blob $blobName -Context $context -Force -Confirm:$false
} catch {
    Write-Error "Failed to upload the log file to Azure Blob Storage. Please check your SAS token permissions."
    exit 1
}

# Clean up the local log file
Remove-Item -Path $logFilePath -Force -ErrorAction SilentlyContinue

Write-Output "Log file uploaded to Azure Blob Storage and local file cleaned up."
