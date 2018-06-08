function Get-BasicAuthFromCreds {
    param(
       $Creds
    )
    if ($Creds -eq $Null) {
        Write-Host "No credentials supplied"
        return ""
    }
    $Base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Creds.GetNetworkCredential().username,$Creds.GetNetworkCredential().password)))
    return "Basic $Base64AuthInfo"
}