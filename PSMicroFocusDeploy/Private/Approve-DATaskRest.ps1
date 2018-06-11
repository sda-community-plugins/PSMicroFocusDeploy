Function Approve-DATaskRest($uuid, $comment="", $action="passed") {
    Try {
        $approvalUrl = $global:MFDAUrl + "/rest/approval/task/$($uuid)/close"
        Write-Verbose "Approving task via $approvalUrl"

        $headers = @{
            Authorization = Get-BasicAuthFromCreds $global:MFDACreds
        }
        Write-Debug $headers

        $body = @{
            comment=$comment
            passFail=$action
        }
        $bodyJson = $body | ConvertTo-Json
        Write-Debug $bodyJson

        Invoke-RestMethod -Method Put -Uri $approvalUrl -Headers $headers -Body $bodyJson -ContentType 'application/json'
    }
    Catch {
        Write-Error "Error approving task via $approvalUrl"
    }
}