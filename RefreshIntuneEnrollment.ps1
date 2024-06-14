$LogFile = "C:\Windows\Temp\IntuneEnrollmentRefresh.log"
$SuccessMarkerFile = "C:\Windows\Temp\IntuneEnrollmentRefresh.success"

# Function to log messages
function Log-Message {
    param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "$Timestamp - $Message"
}

# Function to check if the script has already succeeded
function Check-SuccessMarker {
    if (Test-Path -Path $SuccessMarkerFile) {
        Log-Message "Success marker found. Exiting script."
        exit
    }
}

# Attempt to restart the Intune Management Extension service and trigger check-in
function Refresh-IntuneEnrollment {
    try {
        Log-Message "Attempting to restart the Intune Management Extension service."
        Restart-Service -Name "IntuneManagementExtension" -ErrorAction Stop

        Log-Message "Service restarted successfully. Waiting for 10 seconds."
        Start-Sleep -Seconds 10

        Log-Message "Attempting to trigger device check-in."
        $TriggerCmd = {
            param (
                [string]$NamespacePath,
                [string]$ClassName,
                [string]$MethodName
            )

            $methodParams = (Get-WmiObject -Namespace $NamespacePath -Class $ClassName).PSBase.GetMethodParameters($MethodName)
            $null = (Get-WmiObject -Namespace $NamespacePath -Class $ClassName).PSBase.InvokeMethod($MethodName, $methodParams, $null)
        }

        Invoke-Command -ScriptBlock $TriggerCmd -ArgumentList "root\ccm", "SMS_Client", "TriggerSchedule"
        Log-Message "Device check-in triggered successfully."
        return $true
    } catch {
        Log-Message "Error: $_"
        return $false
    }
}

# Check if the script has already succeeded
Check-SuccessMarker

# Main script execution with retry logic
$MaxRetries = 3
$RetryCount = 0
$Success = $false

while (-not $Success -and $RetryCount -lt $MaxRetries) {
    $RetryCount++
    Log-Message "Attempt $RetryCount of $MaxRetries."
    $Success = Refresh-IntuneEnrollment

    if (-not $Success) {
        Log-Message "Retrying in 30 seconds."
        Start-Sleep -Seconds 30
    }
}

if ($Success) {
    Log-Message "Intune enrollment refresh completed successfully."
    # Create the success marker file
    New-Item -ItemType File -Path $SuccessMarkerFile -Force
} else {
    Log-Message "Failed to refresh Intune enrollment after $MaxRetries attempts."
}
