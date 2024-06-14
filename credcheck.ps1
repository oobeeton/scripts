$cred = "mwscan@krausanderson.com"

if ((cmdkey /list | Out-String) -match $cred) {
    # If the credential exists, exit with zero
    exit 0
} else {
    # Exit with non-zero exit code to trigger remediation
    exit 1
}
