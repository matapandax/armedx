param(
    [Parameter(Mandatory=$true)][string]$AzureSubscriptionName,
    [Parameter(Mandatory=$true)][string]$ResourceGroupName,
    [Parameter(Mandatory=$true)][string]$Location,
    
    [Parameter(Mandatory=$true)][string]$AadWebClientId,
    [Parameter(Mandatory=$true)][string]$AadWebClientAppKey="",
    [Parameter(Mandatory=$true)][string]$AadTenantId,

    [Parameter(Mandatory=$false)][string]$FullDeploymentArmTemplateFile="",
    [Parameter(Mandatory=$false)][string]$ParameterFile="",

    [Parameter(Mandatory=$false)][string]$clusterName="",
    [Parameter(Mandatory=$false)][string]$virtualMachineSize="",
    [Parameter(Mandatory=$false)][int]$diskSize,
   
    [Parameter(Mandatory=$true)][string]$adminUsername="",
    [Parameter(Mandatory=$true)][string]$adminPassword="",
   
    [Parameter(Mandatory=$false)][string]$cmsBaseURL="",
    [Parameter(Mandatory=$false)][string]$lmsBaseURL="",

    [Parameter(Mandatory=$false)][string]$installerGithubAccountName="",
    [Parameter(Mandatory=$false)][string]$installerGithubProjectName="",
    [Parameter(Mandatory=$false)][string]$installerGithubBranch="",

    [Parameter(Mandatory=$false)][string]$edxConfigurationGithubAccountName="",
    [Parameter(Mandatory=$false)][string]$edxConfigurationGithubProjectName="",
    [Parameter(Mandatory=$false)][string]$edxConfigurationGithubBranch=""

)


$azSecureApplicationKey = $AadWebClientAppKey | ConvertTo-SecureString -AsPlainText -Force
$azCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AadWebClientId, $azSecureApplicationKey
$isLoggedIn = [bool](Connect-AzAccount -Credential $azCredential -TenantId $AadTenantId -ServicePrincipal)

if($isLoggedIn){
    Select-AzSubscription -Subscription $AzureSubscriptionName
    Write-Host "Deploying Resource Group."
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location
    Write-Host "Deploying Template."

    $invocation = (Get-Variable MyInvocation).Value 
    $currentPath = Split-Path $invocation.MyCommand.Path 
    $parameterPath = "$($currentPath)\templates\stamp\parameters.json"

    if(-not $FullDeploymentArmTemplateFile) {
        $FullDeploymentArmTemplateFile = "$($currentPath)\templates\stamp\template.json"
    }

    if($ParameterFile) {
        $parameterPath = $ParameterFile
    }

    $parameters = Get-Content -Path $parameterPath | ConvertFrom-Json
   

    $armParameters = @{
        'clusterName'=(&{If($clusterName) {$clusterName} Else {$parameters.parameters.clusterName.value}})
        'location'=(&{If($Location) {$Location} Else {$parameters.parameters.location.value}})

        'virtualMachineSize'=(&{If($virtualMachineSize) {$virtualMachineSize} Else {$parameters.parameters.virtualMachineSize.value}})
        'diskSize'=(&{If($diskSize -gt 0) {$diskSize} Else {$parameters.parameters.diskSize.value}})

        'adminUsername'=(&{If($adminUsername) {$adminUsername} Else {$parameters.parameters.adminUsername.value}})
        'adminPassword'="$((&{If($adminPassword) {$adminPassword} Else {$parameters.parameters.adminPassword.value}}))"
        
        'installerGithubAccountName'=(&{If($installerGithubAccountName) {$installerGithubAccountName} Else {$parameters.parameters.installerGithubAccountName.value}})
        'installerGithubProjectName'=(&{If($installerGithubProjectName) {$installerGithubProjectName} Else {$parameters.parameters.installerGithubProjectName.value}})
        'installerGithubBranch'=(&{If($installerGithubBranch) {$installerGithubBranch} Else {$parameters.parameters.installerGithubBranch.value}})
        
        'edxConfigurationGithubAccountName'=(&{If($edxConfigurationGithubAccountName) {$edxConfigurationGithubAccountName} Else {$parameters.parameters.edxConfigurationGithubAccountName.value}})
        'edxConfigurationGithubProjectName'=(&{If($edxConfigurationGithubProjectName) {$edxConfigurationGithubProjectName} Else {$parameters.parameters.edxConfigurationGithubProjectName.value}})
        'edxConfigurationGithubBranch'=(&{If($edxConfigurationGithubBranch) {$edxConfigurationGithubBranch} Else {$parameters.parameters.edxConfigurationGithubBranch.value}})
    }

    New-AzResourceGroupDeployment `
        -Name "OpenEdXTemplate" `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $FullDeploymentArmTemplateFile `
        -TemplateParameterObject $armParameters
}
else {
    Write-Error "Invalid Access."
}
