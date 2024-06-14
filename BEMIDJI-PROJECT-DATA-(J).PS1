...

# Import the necessary module for the Remove-SmbMapping cmdlet
Import-Module -Name SmbShare

...

# Remove unassigned drives
if ($removeStaleDrives -and $null -ne $psDrives) {
    $diff = Compare-Object -ReferenceObject $driveMappingConfig -DifferenceObject $psDrives -Property "DriveLetter" -PassThru | Where-Object { $_.SideIndicator -eq "=>" }
    foreach ($unassignedDrive in $diff) {
        Write-Warning "Drive '$($unassignedDrive.DriveLetter)' has not been assigned - removing it..."
        Remove-SmbMapping -LocalPath "$($unassignedDrive.DriveLetter):" -Force -UpdateProfile
    }
}

...
