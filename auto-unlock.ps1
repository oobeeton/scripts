# One-liner:
# while ($true) { $lockedOutUsers = Search-ADAccount -LockedOut | Get-ADUser -Properties * | Where-Object { $_.Enabled -eq $true }; if ($lockedOutUsers -ne $null -and $lockedOutUsers.Count -gt 0) { foreach ($user in $lockedOutUsers) { Unlock-ADAccount -Identity $user.SamAccountName; Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $($user.SamAccountName) was unlocked" } } Start-Sleep -Seconds 15 }

# Continuous loop to check for locked-out Active Directory accounts
while ($true) {
    # Search for locked-out AD accounts and retrieve their properties
    $lockedOutUsers = Search-ADAccount -LockedOut | Get-ADUser -Properties * | Where-Object { $_.Enabled -eq $true }

    # If there are locked-out users
    if ($lockedOutUsers -ne $null -and $lockedOutUsers.Count -gt 0) {
        # Loop through each locked-out user
        foreach ($user in $lockedOutUsers) {
            # Unlock the AD account
            Unlock-ADAccount -Identity $user.SamAccountName
            # Output the unlocking event with a timestamp
            Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $($user.SamAccountName) was unlocked"
        }
    }

    # Pause for 15 seconds before checking again
    Start-Sleep -Seconds 15
}

# Optional section to set up the one-liner as a scheduled task that exports to Event Viewer
# Define the action as the one-liner script without Start-Sleep
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -Command "while ($true) { $lockedOutUsers = Search-ADAccount -LockedOut | Get-ADUser -Properties * | Where-Object { $_.Enabled -eq $true }; if ($lockedOutUsers -ne $null -and $lockedOutUsers.Count -gt 0) { foreach ($user in $lockedOutUsers) { Unlock-ADAccount -Identity $user.SamAccountName; Write-EventLog -LogName Application -Source \"AD Account Unlocker\" -EntryType Information -EventId 1 -Message \"$(Get-Date -Format ''yyyy-MM-dd HH:mm:ss'') - $($user.SamAccountName) was unlocked\" } } break }"'

# Define the trigger to run the task every 15 minutes
$trigger = New-ScheduledTaskTrigger -RepeatInterval (New-TimeSpan -Minutes 15) -Once -At (Get-Date)

# Register the scheduled task
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "UnlockADAccounts" -Description "Unlocks locked-out AD accounts and logs the events to the Event Viewer." -User "SYSTEM" -RunLevel Highest
