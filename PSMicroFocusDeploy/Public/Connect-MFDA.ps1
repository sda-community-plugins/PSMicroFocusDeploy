<# 
 .Synopsis
  Validate the connection to a Deployment Automation instance.

 .Description
  Using the supplied parameters validate the connetion to Deployment Automation.
  If no parameters are supplied then request them from the user. The User and
  Password parameters are then stored in a global Credential object ($MFDACreds)
  for use by subsequent functions.

 .Parameter Url
  Deployment Automation URL, e.g. http://servername:8080/da.

 .Parameter User
  The user to login to Deployment Automation.

 .Parameter Password
  The password of the user to login to Deployment Automation.

 .Example
   # Request parameters and validate connection.
   Connect-MFDA

 .Example
   # Validate connection using supplied parameters.
   Connect-MFDA -Url "http://servername:8080/da" -User admin -Password admin
#>

function Connect-MFDA {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true)]
        [string]$Url,

        [parameter(Mandatory=$false)]
        [string]$User,

        [parameter(Mandatory=$false)]
        [string]$Password  
    )
    PROCESS {
        if ($Url -eq $Null -or $Url -eq  '') {
            $global:MFDAUrl = Read-Host -Prompt "Deployment Automation URL"
        } else {
            $global:MFDAUrl = $Url
        }    

        if ($User -eq $Null -or $User -eq  '' -or $Password -eq $Null -or $Password -eq '') {
            $global:MFDACreds = Get-Credential -Message "Please enter your Deployment Automation login details"
        } else {
            $SecurePassword = ConvertTo-SecureString -String $Password -asPlainText -Force
            $global:MFDACreds = New-Object System.Management.Automation.PSCredential($User, $SecurePassword) 
        } 
        
        $LoginUrl = $global:MFDAUrl + "/rest/state"
        Write-Verbose "Validating login to $LoginUrl"

        #$Base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $global:MFDACreds.GetNetworkCredential().username,$global:MFDACreds.GetNetworkCredential().password)))
        $Headers = @{
            Authorization = Get-BasicAuthFromCreds $global:MFDACreds
        }
        Write-Debug $Headers

        Try {
            $DARequest = Invoke-WebRequest -Method Get -Uri $LoginUrl -Headers $Headers
        } Catch {
            $_.Exception.Response.StatusCode.Value__
        }
        if ($DARequest.StatusCode -eq 200) {
            if ($DARequest.StatusCode.Value__) {
                Write-Verbose $DARequest.StatusCode.Value__
            }
            Write-Verbose "Authentication OK"
        } else {
            if ($DARequest.StatusCode.Value__) {
                Write-Error -NoNewline $DARequest.StatusCode.Value__ 
            }    
            Write-Error "Authentication Failure"
        }
    }      

}
