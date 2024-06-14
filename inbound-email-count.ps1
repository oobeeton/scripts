# Ensure the Exchange Online Management module is installed
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber
}

# Import the Exchange Online Management module
Import-Module ExchangeOnlineManagement

# Connect to Exchange Online
#$UserCredential = Get-Credential
#Connect-ExchangeOnline -UserPrincipalName $UserCredential.UserName -Password $UserCredential.GetNetworkCredential().Password

# Define the start and end time for today's date
$startDate = (Get-Date).Date
$endDate = $startDate.AddDays(1)

# Get the message trace for today's date
$messageTraces = Get-MessageTrace -StartDate $startDate -EndDate $endDate

# Group by recipient address and count the number of emails
$emailCounts = $messageTraces | Group-Object -Property RecipientAddress | Select-Object Name, @{Name="EmailCount";Expression={$_.Count}}

# Ensure the output directory exists
$outputDir = "C:\Scripts\Output"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory
}

# Export the results to a CSV file
$outputPath = "$outputDir\EmailCounts_Today.csv"
$emailCounts | Export-Csv -Path $outputPath -NoTypeInformation

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false

Write-Host "Email count report has been generated and saved to $outputPath"
