#Requires -Version 5

$CamundaServer = "LocalHost"
$CamundaRestEngineUri = "http://$($CamundaServer):8080/engine-rest/"

function Remove-CamundaProcessInstances {
    $ProcessInstances = Invoke-WebRequest -Uri $Uri | select -ExpandProperty content | ConvertFrom-Json

    foreach ($ProcessInstance in $ProcessInstances) {
        Invoke-WebRequest -Method Delete -Uri $($Uri + $ProcessInstance.id)
    }
}

function Remove-CamundaDeployments {
    $Uri = "http://localhost:8080/engine-rest/deployment/"
    $Deployments = Invoke-WebRequest -Uri $Uri | select -ExpandProperty content | ConvertFrom-Json

    foreach ($Deployment in $Deployments) {
        Invoke-WebRequest -Method Delete -Uri $($Uri + $Deployment.id + "?cascade=true")
    }
}

function Get-CamundaExternalTasksAndLock {
    param(
        $workerID,
        $maxTasks,
        $usePriority,
        $topics
    )
    
    $FetchAndLockJSONParameters = [pscustomobject][ordered]@{
        workerId = $workerID
        maxTasks = $maxTasks
        topics = $topics
    } | ConvertTo-Json -Depth 10

    Invoke-CamundaRestAPIFunction -MethodPath "/external-task/fetchAndLock" -MethodHttpVerb Post -Body $FetchAndLockJSONParameters
}

function New-CamundaTopic {
    param(
        [parameter(Mandatory)]$topicName,
        [parameter(Mandatory)]$lockDuration,
        [String[]]$VariableNames
    )
    $CamundaTopic = [pscustomobject][ordered]@{
        topicName = $topicName
        lockDuration = $lockDuration        
    } 
    if($VariableNames){
        $CamundaTopic | Add-Member -MemberType NoteProperty -Name variables -Value $VariableNames
    }
    $CamundaTopic
}

#function New-CamundaVariable {
#
#}

function Invoke-CamundaRestAPIFunction {
    param(
        $MethodPath,
        $MethodHttpVerb,
        $Body
    )
    Invoke-WebRequest -Uri $("http://cmagnuson-lt:8080/engine-rest" + $MethodPath) -Method $MethodHttpVerb -Body $Body -Verbose -ContentType "application/json" |
    select -ExpandProperty content |
    ConvertFrom-Json
}