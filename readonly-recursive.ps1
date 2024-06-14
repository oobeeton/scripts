# Install and import the Active Directory module
Install-Module -Name ActiveDirectory -Force -SkipPublisherCheck
Import-Module -Name ActiveDirectory -Force

# Read the list of usernames from the CSV file
$usernames = Import-Csv -Path "C:\scripts\usernames.csv"

# Fetch AD users that match the usernames in the CSV
$adUsers = Get-ADUser -Filter { SamAccountName -eq $usernames.Name }

# Check if any matching AD users were found
if ($adUsers.Count -eq 0) {
    Write-Output "No matching AD users found for the usernames in the CSV. Exiting script."
    exit
}

do {
    # List directories from the E: drive
    $directories = Get-ChildItem -Path "E:\users" -Directory

    # Select directories to process
    $selectedDirectories = $directories | Out-GridView -OutputMode Multiple -Title "Select directories to process"

    if ($selectedDirectories.Count -eq 0) {
        Write-Output "No directories selected. Exiting script."
        break
    }

    foreach ($dir in $selectedDirectories) {
        if (Test-Path $dir.FullName) {
            $acl = Get-Acl $dir.FullName

            # Group permissions for each user
            $userPermissions = @{}
            foreach ($adUser in $adUsers) {
                $username = $adUser.SamAccountName
                $denyAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($username, "Write,Modify", "ContainerInherit,ObjectInherit", "None", "Deny")
                $allowAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($username, "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
                $userPermissions[$username] = @($allowAccessRule, $denyAccessRule)
            }

            # Apply grouped permissions to the ACL
            foreach ($user in $userPermissions.Keys) {
                foreach ($permission in $userPermissions[$user]) {
                    $acl.AddAccessRule($permission)
                }
                Write-Output "Lockdown complete for directory: $($dir.FullName) and user: $user. Read and Execute access granted, Modify and Write access denied."
            }

            Set-Acl -Path $dir.FullName -AclObject $acl

            # Handling long file paths
            Get-ChildItem -Path (Get-Item -Path $dir.FullName).FullName.Replace("\\?\", "") -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                $shortPath = [System.IO.Path]::GetFullPath($_.FullName)
                $itemAcl = Get-Acl $shortPath
                foreach ($permission in $userPermissions.Values) {
                    $itemAcl.AddAccessRule($permission)
                }
                Set-Acl -Path $shortPath -AclObject $itemAcl
            }
        } else {
            Write-Output "Directory not found: $($dir.FullName). Skipping directory."
        }
    }
} while ($selectedDirectories.Count -ne 0)