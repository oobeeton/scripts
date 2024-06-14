#Simplified Pre-provisioning script
#MUST RUN IN SHAREPOINT ONLINE MGMT SHELL
#Source:  http://www.thinkscape.com/Provision-OneDrive-For-Business-Personal-Sites/
#TO DO:  Log into the 365 Admin center and export the list of users to Excel, then create a comma-delimited cell that uses all emails.
Add-PSSnapin Microsoft.Sharepoint.Powershell

Connect-SPOService -Url https://krausanderson-admin.sharepoint.com/

#Get list of current OneDrive sites
Get-SPOSite -IncludePersonalSite $true -Limit all -Filter "Url -like '-my.sharepoint.com/personal/'" | select Url

#Can pass up to 200 usernames
Request-SPOPersonalSite -UserEmails "EMAIL" -NoWait

#NOTE: It says it can take up to 24 hours for the site to provision...check back via ShareGate after a day if they don't appear.
#Also had an issue sending multiple user emails with comma separator, the sites didn't create.  They did create when command ran with a single email.
