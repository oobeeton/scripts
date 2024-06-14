$vpnName = "ka-vnet-inf-hub-001" # Adjust this to match your VPN connection name
$vpnStatus = Get-VpnConnection -Name $vpnName | Select-Object -ExpandProperty ConnectionStatus
if ($vpnStatus -eq "Connected") {
    Write-Output "VPN is connected. let's map some drives."
} else {
    Write-Output "VPN is not connected. Exiting script."
    exit
}
