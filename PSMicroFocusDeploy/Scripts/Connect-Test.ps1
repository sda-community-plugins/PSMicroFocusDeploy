###############################################################################
# Vorlage für Powershell Scripts
# Version 1.0 / 15.06.2011
# Andres Bohren / www.icewolf.ch / blog.icewolf.ch / info@icewolf.ch
###############################################################################
<#
.SYNOPSIS  
    A summary of what this script does  
    Appears in all basic, -detailed, -full, -examples  
.DESCRIPTION  
    A more in depth description of the script  
    Should give script developer more things to talk about       
    Becomes: "DETAILED DESCRIPTION"  
    Appears in basic, -full and -detailed  
.NOTES  
    Additional Notes, eg  
    File Name  : Get-AutoHelp.ps1  
    Author     : Thomas Lee - tfl@psp.co.uk  
    Appears in -full   
.LINK  
    A hyper link, eg  
    http://www.pshscripts.blogspot.com  
    Becomes: "RELATED LINKS"   
    Appears in basic and -Full  
.EXAMPLE  
    The first example - just text documentation  
    You should provide a way of calling the script, plus expected output  
    Appears in -detailed and -full  
.COMPONENT  
   Not sure how to specify or use  
   Does not appear in basic, -full, or -detailed  
   Should appear in -component  
.ROLE   
   Not sure How to specify or use  
   Does not appear in basic, -full, or -detailed  
   Should appear with -role  
.FUNCTIONALITY  
   Not sure How to specify or use  
   Does not appear in basic, -full, or -detailed  
   Should appear with -functionality  
.PARAMETER foo  
   The .Parameter area in the script is used to derive the contents of the PARAMETERS in Get-Help output which   
   documents the parameters in the param block. The section takes a value (in this case foo,  
   the name of the first actual parameter), and only appears if there is parameter of that name in the  
   params block. Having a section for a parameter that does not exist generate no extra output of this section  
   Appears in -det, -full (with more info than in -det) and -Parameter (need to specify the parameter name)  
.PARAMETER bar  
   Example of a parameter definition for a parameter that does not exist.  
   Does not appear at all.  
#>
###############################################################################
#Script Input Parameters
###############################################################################
param(
    [string]$Url = "http://localhost:8080/da",
    [string]$User = "admin",
    [string]$Password = ""
)

#############################################################################
# Function Connect-MFDA 
###############################################################################
Function Connect-MFDA {
    param(
        [string]$daUrl = "http://localhost:8080/da",
        [string]$daUser = "admin",
        [string]$daPassword = ""
    )

    $daUrl = $daUrl.TrimEnd('/')
    Write-Debug "DA Url is: $daUrl"
    Write-Debug "DA User is: $daUser"
    Write-Debug "DA Password is: $daPassword"

    # Allow the use of self-signed SSL certificates.
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $True }

    if ($daUrl -eq $Null -or $daUrl -eq  '') {
        $daUrl = Read-Host -Prompt "Deployment Automation URL"
    }   

    if ($daUser -eq $Null -or $daUser -eq  '') {
        $daUser = Read-Host -Prompt "User"
    }  

    if ($daPassword -eq $Null -or $daPassword -eq  '') {
        $daPassword = Read-Host -Prompt "Password"
    } 

    $daLoginUrl = $daUrl + "/rest/state"
    Write-Host "Validating login to $daLoginUrl"

    $basicAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $daUser,$daPassword)))
    Write-Debug $basicAuth
    $Headers = @{
        Authorization = "Basic $basicAuth"
    }

    Try {
        $daRequest = Invoke-WebRequest -Method Get -Uri $daLoginUrl -Headers $Headers
    } Catch {
        $_.Exception.Response.StatusCode.Value__
    }
    if ($dARequest.StatusCode -eq 200) {
        Write-Host -NoNewline $daRequest.StatusCode.Value__
        Write-Host "Authentication OK"
    } else {
        Write-Host -NoNewline $daRequest.StatusCode.Value__ 
        Write-Host "Authentication Failure"
    }
}

###############################################################################
# Start Script
###############################################################################
Connect-MFDA -daUrl $Url -daUser $User -daPassword $Password 