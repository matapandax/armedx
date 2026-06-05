# Open EdX Deployment on Azure
This project contains an **ARM Template** and some scripts used to deploy **Open EdX** platform on Azure.


#### Prerequisites :  
- *PowerShell 5 and above*
- *AZ Module*


#### List of resources that will be deployed
![Azure Resources](./docs/images/resources.png)


#### ARM Template Visualization
![Azure Resources](./docs/images/template_design.png)


## Deploy via PowerShell

1. **Update `utils/install/config/config.yml` for your LMS/CMS domain configuration**
2. **Copy `templates/stamp/parameters.azure.example.json` to `templates/stamp/parameters.local.json` and update the values**
3. **Run Deploy-ARM.ps1 in PowerShell**

        &"<Deply-ARM directory>\Deploy-ARM.ps1" `
            -AzureSubscriptionName "<Azure Subscription Name>" `
            -ResourceGroupName "<Resource Group>" `
            -Location "<Location>" `
            -AadWebClientId "<AAD Client ID>" `
            -AadWebClientAppKey "<AAD Client Key>" `
            -AadTenantId "<AAD Tenant ID>" `
            -ParameterFile "<Parameters File Path>" `
            -FullDeploymentArmTemplateFile "<ARM Template File Path>" `
            -clusterName "<root name or resources>" `
            -virtualMachineSize "<Virtual Machine Size>" `
            -diskSize <Disk Size> `
            -adminUsername "<VM Username>" `
            -adminPassword "<VM Password>" `
            -installerGithubAccountName "<Installer Github account name>" `
            -installerGithubProjectName "<Installer Github project name>" `
            -installerGithubBranch "<Installer Github branch>" `
            -edxConfigurationGithubAccountName "<Configuration Github account name>" `
            -edxConfigurationGithubProjectName "<Configuration Github project name>" `
            -edxConfigurationGithubBranch "<Configuration Github branch>"
**Deploy-ARM.ps1 Parameters**
| Parameter name                        | Type  | Mandatory | Default Value                 |
|---------------------------------------|-------|-----------|-------------------------------|
|`-AzureSubscriptionName`               |string |true       |                               |
|`-ResourceGroupName`                   |string |true       |enialrash                      |
|`-Location`                            |string |true       |southeastasia                  |
|`-AadWebClientId`                      |string |true       |                               |
|`-AadWebClientAppKey`                  |string |true       |                               |
|`-AadTenantId`                         |string |true       |                               |
|`-FullDeploymentArmTemplateFile`       |string |false      |templates/stamp/template.json  |
|`-ParameterFile`                       |string |false      |templates/stamp/parameters.json|
|`-clusterName`                         |string |false      |edxicei                        |
|`-virtualMachineSize`                  |string |false      |Standard_D3_v2                 |
|`-diskSize`                            |int    |false      |50                             |
|`-adminUsername`                       |string |true       |azureuser                      |
|`-adminPassword`                       |string |true       |                               |
|`-installerGithubAccountName`          |string |false      |edx                            |
|`-installerGithubProjectName`          |string |false      |configuration                  |
|`-installerGithubBranch`               |string |false      |open-release/lilac.master      |
|`-edxConfigurationGithubAccountName`   |string |false      |edx                            |
|`-edxConfigurationGithubProjectName`   |string |false      |configuration                  |
|`-edxConfigurationGithubBranch`        |string |false      |open-release/lilac.master      |

See the Indonesian Azure install guide in [docs/azure-install.md](./docs/azure-install.md).
For native Koa (`open-release/koa.master`), use [docs/azure-openedx-koa.md](./docs/azure-openedx-koa.md).
For SSH clone based native Koa, use [docs/architecture-ssh-koa.md](./docs/architecture-ssh-koa.md).

**Check out Azure Virtual Machines Sizes [here][vmsizes].**

Deployment of azure resources takes a minute to complete. <br/>
Open EdX installation takes almost 2 hours to finished. <br/>
To check the status of installation
1. Login to Virtual Machine via ssh
2. Execute the following command
   
        sudo su
        cd ~
        tail -f install.out
3. After the installation is finished check out the URL of CMS and LMS<br/>
    >**CMS**: `http://<clustername>-cms-tm.trafficmanager.net`<br/>
    >**LMS**: `http://<clustername>-lms-tm.trafficmanager.net`



[//]: # (These are reference links)


   [vmsizes]: <https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-general?toc=/azure/virtual-machines/linux/toc.json&bc=/azure/virtual-machines/linux/breadcrumb/toc.json>
