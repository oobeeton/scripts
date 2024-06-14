# Import the Active Directory module
Import-Module ActiveDirectory

# List directories from E: drive
$directories = Get-ChildItem -Path "E:\users" -Directory

# Import usernames from CSV and convert them into an array of strings
$usernames = Import-Csv -Path "C:\scripts\usernames3.csv" | ForEach-Object { $_.Name }

# Filter directories to match the usernames from the CSV
$matchedDirectories = $directories | Where-Object { $usernames -contains $_.Name }

# Present the filtered list in GridView and wait for selection
$selectedDirectories = $matchedDirectories | Select-Object Name, FullName | Out-GridView -Title "Select Directories to Lockdown" -PassThru

# Exit if no selection is made
if ($selectedDirectories -eq $null) {
    Write-Host "No directories selected. Exiting script."
    exit
}

foreach ($selectedDirectory in $selectedDirectories) {
    # Deduce the username from the directory name
    $directoryName = $selectedDirectory.Name

    # Assuming the username validation with AD is still required
    $user = Get-ADUser -Filter { SamAccountName -eq $directoryName } -ErrorAction SilentlyContinue

    # Check if a corresponding AD user exists
    if ($user -eq $null) {
        Write-Host "No AD user found for directory: $directoryName. Skipping this directory."
        continue
    }

    # Get the current ACL of the selected folder
    $acl = Get-Acl $selectedDirectory.FullName

    # Remove existing permissions for the user
    $existingPermissions = $acl.Access | Where-Object { $_.IdentityReference -eq $user.SamAccountName }
    foreach ($permission in $existingPermissions) {
        $acl.RemoveAccessRule($permission)
    }

# Define new permissions
$permissionReadExecute = "ReadAndExecute"
$inheritanceFlag = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
$propagationFlag = [System.Security.AccessControl.PropagationFlags]::None
$allowRule = New-Object System.Security.AccessControl.FileSystemAccessRule($user.SamAccountName, $permissionReadExecute, $inheritanceFlag, $propagationFlag, "Allow")

# Create an explicit deny rule for "Write" permissions
$specificDenyPermissions = [System.Security.AccessControl.FileSystemRights]"Write"
$denyRule = New-Object System.Security.AccessControl.FileSystemAccessRule($user.SamAccountName, $specificDenyPermissions, $inheritanceFlag, $propagationFlag, "Deny")

# First, add the deny rule to ensure it takes precedence
$acl.AddAccessRule($denyRule)

# Then, add the allow rule
$acl.AddAccessRule($allowRule)

# Apply ACL changes recursively to the directory
Set-Acl -Path $selectedDirectory.FullName -Acl $acl
Write-Host "Lockdown complete for directory: $($selectedDirectory.FullName)"
}
