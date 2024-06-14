# Ensure the required module is imported
Import-Module ActiveDirectory

# Retrieve all domain controllers
$domainControllers = Get-ADDomainController -Filter *

# Iterate over each domain controller
foreach ($dc in $domainControllers) {
    Write-Host "Checking replication for domain controller: $($dc.HostName)" -ForegroundColor Cyan

    # Check replication partners for the current domain controller
    $replicationData = Get-ADReplicationPartnerMetadata -Target $dc.HostName

    foreach ($replicationPartner in $replicationData) {
        $lastReplicationResult = $replicationPartner.LastReplicationResult

        # Check if the replication was successful
        if ($lastReplicationResult -eq 0) {
            Write-Host "Replication from $($replicationPartner.Partner) to $($dc.HostName) is successful. Last replication at $($replicationPartner.LastReplicationSuccess)."
        } else {
            Write-Host "Replication from $($replicationPartner.Partner) to $($dc.HostName) failed with error code: $lastReplicationResult" -ForegroundColor Red
        }
    }
}

Write-Host "Replication check completed."
