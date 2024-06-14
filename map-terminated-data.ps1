$storageAccountName = "terminationdata"
$storageAccountKey = "t14xlOhJZTXoC2jxYAWGWT99fip6Gs+kunLYRgNrkIZcEZlrcO86Ye2nAy19YuvLIRFUwYrmB/at+AStlS90Gw=="
$sharePath = "\\terminationdata.file.core.windows.net\azterminateddata"

# Mapping the network drive
net use T: $sharePath /user:$storageAccountName $storageAccountKey /persistent:yes
