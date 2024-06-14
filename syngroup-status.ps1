# Set subscription ID for Kraus Anderson Subscription
$subscriptionId = "3252c81c-74e5-4732-8124-0809376ddab8"

# Set resource group name for sync groups
$syncResourceGroupName = "ka-rg-inf-files"
import-module az
# Set Azure context to the specified subscription
Set-AzContext -SubscriptionId $subscriptionId -ErrorAction Stop

# Connect to Azure
Connect-AzAccount -ErrorAction Stop

# Get selected sync groups from the user
$selectedSyncGroups = @(get-azstoragesyncservice -ResourceGroupName ka-rg-inf-files | Get-AzStorageSyncGroup | Out-GridView -PassThru -Title "Select Sync Groups to Pause/Resume")

# Toggle the process for selected sync groups
foreach ($group in $selectedSyncGroups) {
    if ($group.SyncGroupStatus -eq 0) {
        # If sync status is running, pause the sync process
        Suspend-AzStorageSyncGroup -InputObject $group
        Write-Host "Sync group $($group.SyncGroupName) paused."
    } else {
        # If sync status is not running, resume the sync process
        Resume-AzStorageSyncGroup -InputObject $group
        Write-Host "Sync group $($group.SyncGroupName) resumed."
    }
}
