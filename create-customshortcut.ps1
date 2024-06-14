# Get the path to the current user's desktop
$desktopPath = [System.Environment]::GetFolderPath("Desktop")

# Define the destination path for the shortcut
$destination = Join-Path -Path $desktopPath -ChildPath "KAU-Shortcut.lnk"

# Define the content of the shortcut file
$shortcutContent = @"
[InternetShortcut]
URL=https://intranet.krausanderson.com"
IconFile=%SystemRoot%\system32\SHELL32.dll
IconIndex=0
"@

# Create the shortcut on the current user's desktop
$shortcutContent | Out-File -FilePath $destination -Encoding ASCII
