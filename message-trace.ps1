# Define the date range (today)
$startDate = (Get-Date).Date
$endDate = $startDate.AddDays(1)

# Get all message traces for today that failed
$failedMessages = Get-MessageTrace -SenderAddress "Kelsey.Vaszily@krausanderson.com" -StartDate $startDate -EndDate $endDate | Where-Object { $_.Status -ne "Delivered" }

# Collect results
$results = @()

# Loop through each failed message and get detailed information
$failedMessages | ForEach-Object {
    $messageId = $_.MessageId
    $recipientAddress = $_.RecipientAddress
    $details = Get-MessageTraceDetail -MessageTraceId $_.MessageTraceId -RecipientAddress $recipientAddress

    # Parse XML from the Data field to extract SmtpResponse
    $xmlData = [xml]$details.Data
    $smtpResponses = @()
    foreach ($mep in $xmlData.root.MEP) {
        if ($mep.Name -eq "CustomData" -and $mep.Blob -match "SmtpResponse:([^,]+)") {
            $smtpResponses += $matches[1]
        }
    }

    $results += [PSCustomObject]@{
        Received = $_.Received
        RecipientAddress = $recipientAddress
        Status = $_.Status
        MessageId = $messageId
        Event = $details.Event
        Detail = $details.Detail
        SmtpResponses = ($smtpResponses -join "; ")
    }
}

# Display the final report in Out-GridView
$results | Out-GridView
