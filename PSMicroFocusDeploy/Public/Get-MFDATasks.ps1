<# 
 .Synopsis
  Get Approval Tasks.

 .Description
  xxx

 .Parameter A
  xxx.

 .Example
   # xxx
   Get-MFDATasks
#>
function Get-MFDATasks {
  param(
    $Url,
    $User,
    $Password
  )

  $Body = @{
  }

  $TasksUrl = $global:MFDAUrl + "/rest/approval/task/tasksForUserGroupedByApproval"
  Write-Debug "Retrieving tasks via $TasksUrl"

  $Headers = @{
      Authorization = Get-BasicAuthFromCreds $global:MFDACreds
  }
  Write-Debug $Headers

  [bool]$moreTasks = $True
  while ($moreTasks) {

    $Tasks = Invoke-RestMethod -Method Get -Uri $TasksUrl -Headers $Headers -Body $Body -ContentType 'application/json'
    
    If ($Tasks) {
      #Write-Host 'Select a [#] from the options below!' `n -ForegroundColor Black -BackgroundColor Green

      $i = 0 
      ForEach ($Task in $Tasks) {
        Write-Host "[$i] -> $($task.name) [$($task.type)]"
        Switch ($task.type) {
          "approval" {
            $requestDate = (Get-Date '1/1/1970').AddMilliseconds($task.applicationProcessRequest.submittedTime)
            Write-Host `t"Requested on: [$requestDate], by [$($task.applicationProcessRequest.userName)]"
            if ($task.applicationProcessRequest.snapshot) {
              Write-Host `t"Deploying snapshot: [$($task.applicationProcessRequest.snapshot.name)], to [$($task.applicationProcessRequest.environment.name)]"
            } else {
              $versions = $null
              ForEach ($version in $task.applicationProcessRequest.versions) {
                $versions = $versions + $version.component.name + ":" + $version.name + ", "
              }
              Write-Host `t"Deploying version(s); [$($versions)], to [$($task.applicationProcessRequest.environment.name)]"
            }  
            break;
          }
          "applicationTask" {
            $requestDate = (Get-Date '1/1/1970').AddMilliseconds($task.applicationProcessRequest.submittedTime)
            Write-Host `t"Requested on: [$requestDate], by [$($task.applicationProcessRequest.userName)]"
            Write-Host `t"Environment: [$($task.applicationProcessRequest.environment.name)]"
            break
          }
          "componentTask" {
            $requestDate = (Get-Date '1/1/1970').AddMilliseconds($task.componentProcessRequest.submittedTime)
            Write-Host `t"Requested on: [$requestDate], by [$($task.componentProcessRequest.userName)]"
            Write-Host `t"Deploying version: [$($task.componentProcessRequest.version.name)], to [$($task.componentProcessRequest.resource.name)]"
            break
          }
          default {
            Write-Host "unknown type $task.type"
            break;
          }
        }
        $i++
      }

      #Write-Host `n

      Try {
        [int]$taskSelection = Read-Host 'Which Task [#]? (any invalid option quits)' -ErrorAction SilentlyContinue
      }
      Catch {
        Write-Host "Invalid option, quitting!" -ForegroundColor Red -BackgroundColor DarkBlue
        Break
      }
      $taskAction = Read-Host "Approve or Reject [Approve]"
      if ($taskAction -eq '' -or $taskAction -eq $Null) { $taskAction = "Approve"}
      $taskComment = Read-Host 'Comment'
    
      Switch ($taskSelection) { 
        {$_ -le ($i - 1)} { 
          $ApprovalUrl = $global:MFDAUrl + "/rest/approval/task/$($Tasks[$_].id)/close"
          $ApprovalAction = "passed"
          Write-Debug $ApprovalUrl
          if ($Action.Substring(0,1).ToLower() -eq "r") { $ApprovalAction = "failed" }
          $Body = @{
            comment=$taskComment
            passFail=$ApprovalAction
          }
          $BodyJson = $Body | ConvertTo-Json
          $Tasks = Invoke-RestMethod -Method Put -Uri $ApprovalUrl -Headers $Headers -Body $BodyJson -ContentType 'application/json'
          Write-Host "Done."
        }
        Default {
          Write-Host "Invalid option, quitting!" -ForegroundColor Red -BackgroundColor DarkBlue
          Break
        }
      }  
    } else {
      $moreTasks = $False
    }  

  }
  #  ForEach-Object {[PSCustomObject]@{Id=$_.id; Name=$_.name; Type=$_.type; 
  #    AppName=$_.applicationProcessRequest.application.name; 
  #    AppProcessName=$_.applicationProcessRequest.applicationProcess.name;
  #    EnvironmentName=$_.applicationProcessRequest.environment.name}} | Format-Table
 
}
