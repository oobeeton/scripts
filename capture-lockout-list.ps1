# Variables
$StartDate = (Get-Date).AddDays(-7)
$LockoutEvents = @()

# Query each Domain Controller for lockout events
$DCs = Get-ADDomainController -Filter *
foreach ($DC in $DCs) {
    $events = Get-WinEvent -ComputerName $DC.HostName -FilterHashtable @{
        LogName = 'Security';
        Id = 4740;
        StartTime = $StartDate
    } | Select-Object TimeCreated, 
                      @{Name="User";Expression={$_.Properties[0].Value}}, 
                      @{Name="LockedOutFrom";Expression={$_.Properties[1].Value}}

    $LockoutEvents += $events
}

# Output Lockout Events
$LockoutEvents | Format-Table -AutoSize

# Query Azure AD for sign-in logs
$signins = Get-AzureADAuditSignInLogs -Filter "createdDateTime ge $(Get-Date -Date $StartDate -Format o)"
$azureLockoutEvents = $signins | Where-Object {$_.status.errorCode -eq 50053} | Select-Object userPrincipalName, createdDateTime, clientAppUsed, status

# Output Azure AD Sign-in Logs
$azureLockoutEvents | Format-Table -AutoSize
