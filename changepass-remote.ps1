Invoke-Command -ComputerName LHVJTSQ3 -ScriptBlock {
    Set-LocalUser -Name "kaadmin" -Password (ConvertTo-SecureString -AsPlainText "DizzyAlongDrug319-" -Force)
} -Credential (Get-Credential)