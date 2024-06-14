
# Define necessary variables
$tenantID = "183a8d00-a3e2-443e-8074-20451397d0be" # Replace with your actual tenant ID
$oneDrivePath = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
$logPath = "\\mplsfs01\logs\intune-powershellscripts.log"
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$hostname = $env:COMPUTERNAME

# Function to add Windows Credential for network share access, not directly related to OneDrive but included for completeness
function Add-Credential {
    $targetResource = "mplsprt.krausanderson.com" # Server name for cmdkey
    $targetUser = "mwscan@krausanderson.com" # Username for cmdkey
    $targetPassword = "sc@nKA123!" # Password for cmdkey - Consider securing this
    cmdkey /add:$targetResource /user:$targetUser /pass:$targetPassword
}

# Ensure the Scans folder exists and set NTFS permissions
$oneDrivePath = [Environment]::GetFolderPath("MyDocuments") + "\SCANS"
if (-not (Test-Path -Path $oneDrivePath)) {
    New-Item -Path $oneDrivePath -ItemType Directory | Out-Null
}
icacls $oneDrivePath /grant 'Everyone:(OI)(CI)F' /T /C /Q

# Configure registry for OneDrive silent account configuration
Set-ItemProperty -Path "HKCU:\Software\Microsoft\OneDrive" -Name "EnableADAL" -Value 1 -Type DWord
Set-ItemProperty -Path "HKCU:\Software\Microsoft\OneDrive\Accounts\Business1" -Name "TenantId" -Value $tenantID -Type String
Set-ItemProperty -Path "HKCU:\Software\Microsoft\OneDrive\Accounts\Business1" -Name "UserEmail" -Value "$username" -Type String # Assuming $username is the user's email
Set-ItemProperty -Path "HKCU:\Software\Microsoft\OneDrive\Accounts\Business1" -Name "SilentAccountConfig" -Value 1 -Type DWord

# Attempt to start OneDrive if not already running
if (-not (Get-Process OneDrive -ErrorAction SilentlyContinue)) {
    Start-Process $oneDrivePath
}

# Logging the actions
$logContent = "Date: $date, Username: $username, Hostname: $hostname, Action: OneDrive Configuration and Start, Silent Sync Status: Initiated"
Add-Content -Path $logPath -Value $logContent