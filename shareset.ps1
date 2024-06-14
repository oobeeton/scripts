$expectedFolderPath = "C:\Users\$env:USERNAME\OneDrive - Kraus-Anderson\Documents\SCANS"
$shareName = "scans"

# Function to set the "Everyone" permission to "Allow" on a folder
function Set-Permissions {
    param (
        [string]$folderPath
    )
    $acl = Get-Acl $folderPath
    $permission = "Everyone","FullControl","Allow"
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl.SetAccessRule($accessRule)
    Set-Acl -Path $folderPath -AclObject $acl
}

# Check if the share is correctly mapped
if ((Get-WmiObject -Class Win32_Share -Filter "Name='$shareName'").Path -eq $expectedFolderPath) {
    # If the share is correctly mapped, fix the permissions
    Set-Permissions -folderPath $expectedFolderPath
} else {
    # If the share is not correctly mapped, delete and recreate the share and permissions
    Remove-SmbShare -Name $shareName -Force -ErrorAction Ignore
    New-SmbShare -Name $shareName -Path $expectedFolderPath -FullAccess Everyone
}
