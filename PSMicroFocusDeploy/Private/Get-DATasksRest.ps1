Function Get-DATasksRest() {
    Try {
        #For DA 6.1.5 and earlier
        #$tasksURL = $global:MFDAUrl + "/rest/approval/task/tasksForUser?orderField=startDate&pageNumber=1&rowsPerPage=99999&sortType=asc"
        #For DA 6.2+
        $tasksUrl = $global:MFDAUrl + "/rest/approval/task/tasksForUserGroupedByApproval"
        Write-Verbose "Retrieving tasks via $tasksUrl"
        
        $headers = @{
            Authorization = Get-BasicAuthFromCreds $global:MFDACreds
			DirectSsoInteraction = "true"
        }
        Write-Debug $headers

        $body = @{
        }

        $restTasks = Invoke-RestMethod -Method Get -Uri $tasksUrl -Headers $headers -Body $body -ContentType "application/json"
        return $restTasks
    }    
    Catch {
        Write-Error "Error retrieving tass via $approvalUrl"
    }    
}