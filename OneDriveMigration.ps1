Import-Module Sharegate	

#clear output window.
Clear-Host

#Adjust the path so that it points to the CSV file with columns DIRECTORY and ONEDRIVEURL.
$csvFile = "C:\PATHTOYOURCSV\OneDriveMigration.csv"
#The delimiter is the symbol your CSV uses to separate your column items.
$table = Import-Csv $csvFile -Delimiter ","
#Create a single connection, and then reuse the credentials from that connection in your script.
$dstsiteConnection = Connect-Site -Url "https://TENANT-admin.sharepoint.com/" -Browser
Set-Variable dstSite, dstList

foreach ($row in $table) {
    Clear-Variable dstSite
    Clear-Variable dstList
    #Uses credentials from above - this account must have site collection admin access to all OneDrive sites.
    $dstSite = Connect-Site -Url $row.ONEDRIVEURL -UseCredentialsFrom $dstsiteConnection
    $dstList = Get-List -Name Documents -Site $dstSite
    Write-Host "Copying" $row.DIRECTORY "to" $row.ONEDRIVEURL
    Import-Document -SourceFilePath $row.DIRECTORY -DestinationList $dstList
    #Removes your user account as site collection administrator on the OneDrive after its migration
    #Remove-SiteCollectionAdministrator -Site $dstSite
}