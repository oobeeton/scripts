# Get all GPOs in the specified domain
$AllGPOs = Get-GPO -All -Domain "krausanderson.com"

# Iterate over each GPO to fetch its settings
foreach ($GPO in $AllGPOs) {
    # Fetch the detailed GPO report
    $GPOReport = Get-GPOReport -Guid $GPO.Id -ReportType html -Domain "krausanderson.com"

    # Optionally, you could save each report to a separate XML file
    $filePath = "C:\scripts\GPOReports\" + $GPO.DisplayName + ".html"
    $GPOReport | Out-File -FilePath $filePath

    # Output the GPO name and its report path
    Write-Output "Report for GPO: $($GPO.DisplayName) is saved at $filePath"
}
