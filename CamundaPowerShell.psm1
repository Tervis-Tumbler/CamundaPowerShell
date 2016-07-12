#Requires -Version 5

$CamundaServer = "LocalHost"
$CamundaRestEngineUri = "http://$($CamundaServer):8080/engine-rest/"

Function Get-CamundaProcessInstanceList {
    param(
        $processInstanceIds,
        $businessKey,
        $caseInstanceId,
        $processDefinitionId,
        $processDefinitionKey,
        $deploymentId,
        $superProcessInstance,
        $subProcessInstance,
        $superCaseInstance,
        $subCaseInstance,
        $active,
        $suspended,
        $incidentId,
        $incidentType,
        $incidentMessage,
        $incidentMessageLike,
        $tenantIdIn,
        $withoutTenantId,
        $activityIdIn,
        $variables,
        $sortBy,
        $sortOrder,
        $firstResult,
        $maxResults
    )
    $QueryStringParameters = $PSBoundParameters.Keys |
    where {$_ -ne "CustomFields"} | 
    % { 
        "$_=$([Uri]::EscapeDataString($PSBoundParameters[$_]))"
    }

    Invoke-CamundaRestAPIFunction -MethodPath "/process-instance" -MethodHttpVerb GET
}

function Remove-CamundaProcessInstances {
    $ProcessInstances = Get-CamundaProcessInstanceList

    foreach ($ProcessInstance in $ProcessInstances) {
        Invoke-CamundaRestAPIFunction -MethodPath "/process-instance/$($ProcessInstance.id)" -MethodHttpVerb Delete
        #Invoke-WebRequest -Method Delete -Uri $($Uri + $ProcessInstance.id)
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

function Complete-CamundaExternalTask {
    param(
        $ExternalTaskID,
        $WorkerID,
        $Variables
    )
    
    $CompleteTaskJSONParameters = [pscustomobject][ordered]@{
        workerId = $WorkerID
        variables = $Variables
    } | ConvertTo-Json -Depth 10

    Invoke-CamundaRestAPIFunction -MethodPath "/external-task/$ExternalTaskID/complete" -MethodHttpVerb Post -Body $CompleteTaskJSONParameters
}

function New-CamundaVariable {
    [cmdletbinding(
        DefaultParameterSetName="Object"
    )]
    param(
        [parameter(Mandatory)]$Name,
        [parameter(Mandatory)]$Value,
        #https://docs.camunda.org/manual/7.5/user-guide/process-engine/variables/#supported-variable-values
        [ValidateSet("boolean","bytes","short","integer","long","double","date","string","null","file")]$Type,
        [Parameter(ParameterSetName="Object")]$ObjectTypeName,
        [Parameter(ParameterSetName="Object")]$SerializationDataFormat,
        [Parameter(ParameterSetName="File")]$Filename,
        [Parameter(ParameterSetName="File")]$Mimetype,
        [Parameter(ParameterSetName="File")]$Encoding
    )
    
    $Variable = [pscustomobject][ordered]@{
        $Name = [pscustomobject][ordered]@{ 
            value = $Value 
        }
    }
    $Variable.$Name | where {$Type} | Add-Member -MemberType NoteProperty -Name Type -Value $Type
    $Variable.$Name | where {$ObjectTypeName} | Add-Member -MemberType NoteProperty -Name ObjectTypeName -Value $ObjectTypeName
    $Variable.$Name | where {$SerializationDataFormat} | Add-Member -MemberType NoteProperty -Name SerializationDataFormat -Value $SerializationDataFormat
    $Variable.$Name | where {$Filename} | Add-Member -MemberType NoteProperty -Name Filename -Value $Filename
    $Variable.$Name | where {$Mimetype} | Add-Member -MemberType NoteProperty -Name Mimetype -Value $Mimetype
    $Variable.$Name | where {$Encoding} | Add-Member -MemberType NoteProperty -Name Encoding -Value $Encoding

    $Variable 
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

function Invoke-CamundaRestAPIFunction {
    param(
        [parameter(Mandatory)]$MethodPath,
        [parameter(Mandatory)]$MethodHttpVerb,
        $Body
    )
    Invoke-WebRequest -Uri $("http://cmagnuson-lt:8080/engine-rest" + $MethodPath) -Method $MethodHttpVerb -Body $Body -Verbose -ContentType "application/json" |
    select -ExpandProperty content |
    ConvertFrom-Json
}