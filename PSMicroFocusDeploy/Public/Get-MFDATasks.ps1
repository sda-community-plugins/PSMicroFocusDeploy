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

  $TasksURL = $global:MFDAUrl + "/rest/approval/task/tasksForUser?orderField=startDate&pageNumber=1&rowsPerPage=99999&sortType=asc"
  #For DA 6.2+
  #$TasksUrl = $global:MFDAUrl + "/rest/approval/task/tasksForUserGroupedByApproval"
  Write-Debug "Retrieving tasks via $TasksUrl"

  $Headers = @{
      Authorization = Get-BasicAuthFromCreds $global:MFDACreds
  }
  Write-Debug $Headers

  [bool]$moreTasks = $True
  while ($moreTasks) {

    $Tasks = Invoke-RestMethod -Method Get -Uri $TasksUrl -Headers $Headers -Body $Body -ContentType "application/json"

    If ($Tasks) {
      $taskCollection = @()
      $index = 1
      $taskId = $Null
      $taskName = $Null
      $taskType = $Null
      $requestedDate = $Null
      $requestedBy = $Null
      $versions = $Null
      $environment = $Null

      ForEach ($Task in $Tasks) {
        $taskId = $Task.id
        $taskName = $Task.name
        $taskType = $Task.type
        Switch ($Task.type) {
          "approval" {
            $requestedBy = $task.applicationProcessRequest.userName
            $requestedDate = (Get-Date '1/1/1970').AddMilliseconds($task.applicationProcessRequest.submittedTime)
            $environment = $task.applicationProcessRequest.environment.name
            if ($task.applicationProcessRequest.snapshot) {
              $versions = $task.applicationProcessRequest.snapshot.name
            } else {
              ForEach ($version in $task.applicationProcessRequest.versions) {
                $versions = $versions + $version.component.name + ":" + $version.name + ", "
              }
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
        $taskCollection += New-Task -Index $index -Id $taskId -Name $taskName -Type $taskType -RequestedDate $requestedDate -RequestedBy $requestedBy -Versions $versions -Environment $environment 
        $index++
      }

      $taskCollection | Format-Table -Property @{n='[#]';e={$_.Index}},Name,Type,
        @{n='Requested';e={$_.RequestedDate}},@{n='By';e={$_.RequestedBy}},
        @{n='Snapshot/Version';e={$_.Versions}},Environment -AutoSize -Wrap

      Try {
        [int]$taskSelection = Read-Host 'Select Task [#]? (any invalid option quits)' -ErrorAction SilentlyContinue
      }
      Catch {
        Write-Host "Invalid option, quitting!" -ForegroundColor Red -BackgroundColor White
        Break
      }
      # check $taskSelection <= collection size
      if ($taskSelection > $taskCollection.size) {
        Write-Host "Invalid option, quitting!" -ForegroundColor Red -BackgroundColor White
        Break
      }

      $thisTask = $taskCollection | Select-Object -Index $($taskSelection-1)
      $taskUuid = $thisTask.id

      $thisTask | Format-List
      
      # Get the action to perform Accept/Reject or Cancel
      $ApprovalAction = "passed"
      $validAction = $False
      $cancelInput = $False
      while ($validAction -eq $False) {
        $inputAction = Read-Host "Approve, Reject or Cancel [Approve]"
        if ($inputAction -eq '' -or $inputAction -eq $Null -or $inputAction.ToLower() -eq "approve") { 
          $validAction = $True
        }
        if ($inputAction.ToLower() -eq "reject") {
          $ApprovalAction = "failed"
          $validAction = $True
        }
        if ($inputAction.ToLower() -eq "cancel") {
          $validAction = $True
          $cancelInput = $True
        }
      }

      # Get the comment to apply  
      if ($cancelInput -eq $True) {
        # ignore
      } else {
        $taskComment = Read-Host "Comment [none]"
        Try {
          $ApprovalUrl = $global:MFDAUrl + "/rest/approval/task/$($thisTask.id)/close"
          Write-Debug $ApprovalUrl
          $Body = @{
            comment=$taskComment
            passFail=$ApprovalAction
          }
          $BodyJson = $Body | ConvertTo-Json
          #$Tasks = Invoke-RestMethod -Method Put -Uri $ApprovalUrl -Headers $Headers -Body $BodyJson -ContentType 'application/json'
          Write-Host "Done."
        }
        Catch {

        }
      }  
    } else {
      $moreTasks = $False
    }  

  }
 
}

# Create a new DA Task object
Function New-Task ($Index='1',$Id ='',$Name='Name',$Type='approval',$RequestedDate='',$RequestedBy='',$Versions='',$Environment='')
{
   New-Object -TypeName psObject -Property @{Index=$index; Id=$id; Name=$name; Type=$type; RequestedDate=$requestedDate; RequestedBy=$requestedBy; Versions=$versions; Environment=$environment}
}
