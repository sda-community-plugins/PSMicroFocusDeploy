<# 
 .Synopsis
  Action one or more approval or manual tasks that have been assigned to a specific user.

 .Description
  This function can be used to approve/complete ore or more approval or manual tasks. The
  tasks UUIDs can either be passed in or (in interactive mode) the user is prompted to 
  select a task and approve/reject it.

 .Parameter Tasks
  Comma separated list of task UUIDs.

 .Example
   # Approve a specific task
   Approve-MFDATasks -Tasks 28cce9c2-e503-4f9e-a16f-6ec14ebca646 -Action passed -Comment "OK"

  .Example
   # Enter interactive mode querying for tasks to approve
   Approve-MFDATasks -I
#>
function Approve-MFDATasks {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string[]]$Tasks,

    [parameter(Mandatory=$false)]
    [string]$Comment,

    [parameter(Mandatory=$false)]
    [ValidateSet('passed','failed')]
    [string]$Action,
    
    [parameter(Mandatory=$false)]
    [alias("I")]
    [switch]$Interactive,

    [parameter(Mandatory=$false)]
    [string]$Url,

    [parameter(Mandatory=$false)]
    [string]$User,

    [parameter(Mandatory=$false)]
    [string]$Password
      
  )
  PROCESS {
    if ($Url -eq $Null -or $Url -eq  '') {
      if ($global:MFDAUrl -eq $Null -or $global:MFDAUrl -eq '') {
        $global:MFDAUrl = Read-Host -Prompt "Deployment Automation URL"
      }  
    } else {
      $global:MFDAUrl = $url
    } 

    if ($User -eq $Null -or $User -eq  '' -or $Password -eq $Null -or $Password -eq '') {
      if ($global:MFDACreds -eq $Null) {
        $global:MFDACreds = Get-Credential -Message "Please enter your Deployment Automation login details"
      }  
    } else {
      $SecurePassword = ConvertTo-SecureString -String $Password -asPlainText -Force
      $global:MFDACreds = New-Object System.Management.Automation.PSCredential($User, $SecurePassword) 
    } 

    if ($Interactive) {

      Write-Verbose "Entering interactive mode.."

      [bool]$moreTasks = $True
      while ($moreTasks) {

        $restTasks = Get-DATasksRest

        If ($restTasks) {
          $taskCollection = @()
          $index = 1
          $taskId = $Null
          $taskName = $Null
          $taskType = $Null
          $requestedDate = $Null
          $requestedBy = $Null
          $versions = $Null
          $environment = $Null
          $description = $Null
          $commentRequired = $False

          ForEach ($task in $restTasks) {
            $taskId = $task.id
            $taskName = $task.name
            $taskType = $task.type
            Switch ($task.type) {
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
                $description = $task.applicationProcessRequest.description
                $commentRequired = $task.commentRequired
                break;
              }
              "applicationTask" {
                $requestedBy = $task.applicationProcessRequest.userName
                $requestedDate = (Get-Date '1/1/1970').AddMilliseconds($task.applicationProcessRequest.submittedTime)
                $environment = $task.applicationProcessRequest.environment.name
                $description = $task.applicationProcessRequest.description
                $commentRequired = $task.commentRequired
                break;
              }
              "componentTask" {
                $requestedBy = $task.componentProcessRequest.userName
                $requestedDate = (Get-Date '1/1/1970').AddMilliseconds($task.componentProcessRequest.submittedTime)
                $environment = $task.componentProcessRequest.resource.name
                $versions = $task.componentProcessRequest.version.name
                ForEach ($version in $task.componentProcessRequest.versions) {
                  $versions = $versions + $version.component.name + ":" + $version.name + ", "
                } 
                $description = $task.componentProcessRequest.description
                $commentRequired = $task.commentRequired
                break;
              }
			  "deploymentRunTask" {
                $requestedBy = $task.deploymentRunProcessRequest.userName
                $requestedDate = (Get-Date '1/1/1970').AddMilliseconds($task.deploymentRunProcessRequest.submittedTime)
				ForEach ($env in $task.deploymentRunProcessRequest.runTimeEnvironments) {
                  $environment = $environments + $env.name + ", "
                } 
                $description = $task.deploymentRunProcessRequest.description
                $commentRequired = $task.commentRequired
                break;
              }
              default {
                Write-Error "Unknown type $task.type!"
                break;
              }
            }
            $taskCollection += New-DATask -Index $index -Id $taskId -Name $taskName -Type $taskType -Description $description -CommentRequired $commentRequired -RequestedDate $requestedDate -RequestedBy $requestedBy -Versions $versions -Environment $environment 
            $index++
          }

          $taskCollection | Format-Table -Property @{n='[#]';e={$_.Index}},Name,Type,
            @{n='Requested';e={$_.RequestedDate}},@{n='By';e={$_.RequestedBy}},
            @{n='Snapshot/Version';e={$_.Versions}},@{n='Environment/Resource';e={$_.Environment}} -AutoSize -Wrap

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
          $thisTask | Format-List -Property @{n='Id';e={$_.Id}},Name,Type,Description,CommentRequired,
            @{n='Requested';e={$_.RequestedDate}},@{n='By';e={$_.RequestedBy}},
            @{n='Snapshot/Version';e={$_.Versions}},@{n='Environment/Resource';e={$_.Environment}}
          
          # Get the action to perform Accept/Reject or Cancel
          $approvalAction = "passed"
          $validAction = $False
          $cancelInput = $False
          while ($validAction -eq $False) {
            $inputAction = Read-Host "Approve, Reject or Cancel [Approve]"
            if ($inputAction -eq '' -or $inputAction -eq $Null -or $inputAction.ToLower() -eq "approve") { 
              $validAction = $True
            } elseif ($inputAction.ToLower() -eq "reject") {
              $approvalAction = "failed"
              $validAction = $True
            } elseif ($inputAction.ToLower() -eq "cancel") {
              $validAction = $True
              $cancelInput = $True
            } else {
              Write-Host "Invalid action!"
              $cancelInput = $False
            }
          }

          # Get the comment to apply  
          if ($cancelInput -eq $True) {
            # ignore
          } else {
            $taskComment = Read-Host "Comment [none]"
            Approve-DATaskRest -uuid $($thisTask.id) -comment $taskComment -action $ApprovalAction
          } 
          
          $validAction = $False
          while ($validAction -eq $False) {
            $inputAction = Read-Host "Continue or Quit [Continue]"
            if ($inputAction -eq '' -or $inputAction -eq $Null -or $inputAction.ToLower() -eq "continue") { 
              $validAction = $True
              $moreTasks = $True
            } elseif ($inputAction.ToLower() -eq "quit") {
              $validAction = $True
              $moreTasks = $False
            } else {
              Write-Host "Invalid action!"
            }
          }

        } else {
          Write-Host "You have no tasks outstanding."
          $moreTasks = $False
        }  

      }
    } else {
      if ($Tasks) {
        ForEach ($task in $Tasks) {
          if ($Action -eq $Null -or $Action -eq '') {
            Write-Error "No action supplied!"
            Exit 1
          }
          if ($Comment -eq $Null -or $Comment -eq '') {
            Write-Verbose "No comment supplied; assuming none required."
            $Comment = ""
          }
          Approve-DATaskRest -uuid $task -comment $Comment -action $Action 
        } 
      } else {
        Write-Verbose "No tasks supplied."
      }
         
    }  
  }   
 
}

# Create a new DA Task object
Function New-DATask ($Index='1',$Id ='',$Name='Name',$Type='approval',$Description='',$CommentRequired=$False,$RequestedDate='',$RequestedBy='',$Versions='',$Environment='')
{
   New-Object -TypeName psObject -Property @{Index=$index; Id=$id; Name=$name; Type=$type; Description=$description; CommentRequired=$commentRequired; RequestedDate=$requestedDate; RequestedBy=$requestedBy; Versions=$versions; Environment=$environment}
}
