# Define the target directories to search for
$targetDirectories = @(
    "10 - CLOSEOUT\10-2 Documentation",
    "10 - CLOSEOUT\10-3 Punchlist",
    "02 - Owner\2-3 Owner Change Orders",
    "05 - Documents\5-0 Document Control Log",
    "05 - Documents\5-1 Current Drawings-Specs",
    "05 - Documents\5-2 Issued Documents",
    "05 - Documents\5-3 RFIs",
    "05 - Documents\5-4 Submittals",
    "05 - Documents\5-5 LEED Submittals",
    "05 - Documents\5-7 Constructability Reviews",
    "09 - FIELD OPERATIONS\9-1 Permits",
    "09 - FIELD OPERATIONS\9-9 Field Photos",
    "00 - Project Directory"
)

# Set the current path for the directory scan
$scanPath = "E:\Projects\B-ACTIVE PROJECTS"

# Initialize an array to hold the results
$results = @()

# Ensure that verbose logging is turned on
$VerbosePreference = 'Continue'

# Get all directories in the specified scan path
$rootDirectories = Get-ChildItem -Path $scanPath -Directory

# Iterate through each root directory
foreach ($rootDir in $rootDirectories) {
    # Check each target directory
    foreach ($targetDir in $targetDirectories) {
        # Construct the full path for the target directory
        $fullPath = Join-Path -Path $rootDir.FullName -ChildPath $targetDir

        # Log the full path before checking its existence
        Write-Verbose "Preparing to check path: $fullPath" -Verbose

        # Initialize the status variables
        $exists = "No"
        $isEmpty = $true
        $itemCount = 0

        # Check if the directory exists
        if (Test-Path $fullPath) {
            Write-Verbose "Path confirmed to exist: $fullPath" -Verbose
            $exists = "Yes"
            # Retrieve items to determine if the directory is empty and to count them
            $items = Get-ChildItem -Path $fullPath -Force
            # Log what Get-ChildItem returned
            Write-Verbose "Items found: $($items.Count)" -Verbose
            $itemCount = $items.Count
            $isEmpty = $itemCount -eq 0
        } else {
            Write-Verbose "Path NOT found: $fullPath" -Verbose
        }

        # Create a custom object with the directory check results
        $result = [PSCustomObject]@{
            DirectoryPath = $fullPath
            Exists = $exists
            IsEmpty = if($isEmpty) { "Empty" } else { "Contains Items" }
            ItemCount = $itemCount
        }

        # Add the result to the results array
        $results += $result
    }
}

# Display the results in a grid view for immediate review
$results | Out-GridView -Title "Directory Check Results"

# Optional: Export the results to a CSV file for record-keeping
$outputCsvPath = "C:\SCRIPTS\directory-check-results.csv"
$results | Export-Csv -Path $outputCsvPath -NoTypeInformation

Write-Output "Directory check results have been exported to $outputCsvPath"
