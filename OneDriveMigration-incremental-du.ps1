# Import Sharegate module
Import-Module Sharegate
$copysettings = New-CopySettings -OnContentItemExists IncrementalUpdate
# Define CSV file path
$csvFile = "C:\scripts\OneDriveMigration-du.csv"

# Clear output window
Clear-Host

# Import CSV into table variable
$table = Import-Csv $csvFile -Delimiter ","
#$totalRows = $table.Count

# Function to calculate progress
#Function Calculate-Progress ($current, $total) {
#    return [math]::Round(($current / $total) * 100, 2)
#}

# Show Out-GridView for row selection
#$selectedRows = $table | Out-GridView -Title "Select Rows to Process" -OutputMode Multiple

# Update totalRows based on selection
#$totalRows = $selectedRows.Count

# Initialize summary collection
#$counter = 0
#$completedRows = @()

# Create a single connection, and then reuse the credentials from that connection in your script.
$dstsiteConnection = Connect-Site -Url "https://krausanderson-admin.sharepoint.com/" -Browser
Set-Variable dstSite, dstList

# Loop through each selected row
foreach ($row in $table) {
#    $counter++
#    $startTime = Get-Date
    Clear-Variable dstSite
    Clear-Variable dstList
    
        # Display completed rows
        #$completedRows | Format-Table -Property Directory, FileCount, TimeTaken
        Write-Host "Copying" $row.DIRECTORY "to" $row.ONEDRIVEURL
        # Count the number of files in the source directory recursively
        #$fileCount = (Get-ChildItem -Path $row.DIRECTORY -File -Recurse).Count

        # Connect to OneDrive site and get Document list
        $dstSite = Connect-Site -Url $row.ONEDRIVEURL -UseCredentialsFrom $dstsiteConnection
        $dstList = Get-List -Name "Documents" -Site $dstSite

        # Perform the migration
        Import-Document -SourceFilePath $row.DIRECTORY -DestinationList $dstList -CopySettings $copysettings

        # Calculate time taken for this row
#        $endTime = Get-Date
#        $elapsedTime = $endTime - $startTime
#        $elapsedTimeStr = "{0:D2}:{1:D2}" -f $elapsedTime.Minutes, $elapsedTime.Seconds

        # Add to completed rows
#        $completedRows += [PSCustomObject]@{
#            Directory = $row.DIRECTORY
#            FileCount = $fileCount
#            TimeTaken = $elapsedTimeStr
#}
}
