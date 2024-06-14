$sharePath = "\\localhost\scans"

function ShareExists {
    param (
        [string]$sharePath
    )
    $shareExists = Test-Path $sharePath
    return $shareExists
}

if (ShareExists -sharePath $sharePath) {
    exit 0  # Share exists
} else {
    exit 1  # Share does not exist
}
