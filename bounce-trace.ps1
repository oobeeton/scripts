# Define the date range (today)
$startDate = (Get-Date).Date
$endDate = $startDate.AddDays(1)

# Get all message traces for today where the status is Failed and the recipient is external and the sender is Kelsey Vaszily
$failedMessages = Get-MessageTrace -SenderAddress "Kelsey.Vaszily@krausanderson.com" -StartDate $startDate -EndDate $endDate | Where-Object {
    ($_.Status -eq "Failed") -and ($_.RecipientAddress -notlike "*@krausanderson.com")
}

# Collect results
$results = @()

# Loop through each failed message and get detailed information
$failedMessages | ForEach-Object {
    $messageId = $_.MessageId
    $recipientAddress = $_.RecipientAddress
    $details = Get-MessageTraceDetail -MessageTraceId $_.MessageTraceId -RecipientAddress $recipientAddress

    # Initialize the array for SMTP responses
    $smtpResponses = @()

    # Check if $details.Data is an array of XML documents
    if ($details.Data -is [System.Array]) {
        foreach ($data in $details.Data) {
            $xmlData = [xml]$data
            foreach ($mep in $xmlData.root.MEP) {
                if ($mep.Name -eq "CustomData" -and $mep.Blob -match "SmtpResponse:([^,]+)") {
                    $smtpResponses += $matches[1]
                }
            }
        }
    } else {
        # Handle case where $details.Data is a single XML document
        $xmlData = [xml]$details.Data
        foreach ($mep in $xmlData.root.MEP) {
            if ($mep.Name -eq "CustomData" -and $mep.Blob -match "SmtpResponse:([^,]+)") {
                $smtpResponses += $matches[1]
            }
        }
    }

    $results += [PSCustomObject]@{
        SentTime = $_.Received
        SenderAddress = $_.SenderAddress
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
