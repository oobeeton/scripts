$folderPath = "C:\Users\$env:USERNAME\OneDrive - Kraus-Anderson\Documents\SCANS"
New-Item -ItemType Directory -Path $folderPath -ErrorAction Ignore | Out-Null
$acl = Get-Acl $folderPath
$permission = "Everyone","FullControl","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl -Path $folderPath -AclObject $acl