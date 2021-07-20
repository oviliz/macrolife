# Maersk Q2 Macro Life

## Scenario
Macro Life, a healthcare company has recently setup the entire Network and Infrastructure on Azure.
The infrastructure has different components such as Virtual N/W, Subnets, NIC, IPs, NSG etc.
The IT team currently has developed PowerShell scripts to deploy each component where all the properties of each resource is set using PowerShell commands.
The business has realized that the PowerShell scripts are growing over period of time and difficult to handover when new admin onboards in the IT.
The IT team has now decided to move to Terraform based deployment of all resources to Azure.
All the passwords are stored in an Azure Service known as key Vault. The deployments needs to be automated using Azure DevOps using IaC (Infrastructure as Code).
1) What are different artifacts you need to create - name of the artifacts and its purpose
2) List the tools you will to create and store the Terraform templates.
3) Explain the process and steps to create automated deployment pipeline.
4) Create a sample Terraform template you will use to deploy below services:
- Vnet
- 2 Subnet
- NSG to open port 80 and 443
- 1 Windows VM in each subnet
- 1 Storage account
5) Explain how will you access the password stored in Key Vault and use it as Admin Password in the VM Terraform template.

## Prerequisites
- Azure Subscription with two Resource Groups, one for the Azure DevOps (ADO) Pipeline and a static RG (i.e. with manually deployed resources) to host the suposedly pre-existing Azure Key Vault (we would also use this to create a new Storage Account via ADO Pipeline for the Terraform state file)

![Azure Resource Groups](readme/img/azureRGs.png)

- Azure DevOps (ADO) Project

- ADO Service Connections, one per Azure Resource Group (avoid granting general access to whole subscriptions!); to make life easier, name them after Resource Groups

![ADO Service Connections](readme/img/adoServiceConnections.png)

- Azure Key Vault with relevant Secrets for Windows VM Administrator; the Service Principal automatically created by the ADO Service Connection to the static RG, needs adding to the Key Vault Access Policies with GET and LIST permissions

- ADO Extensions:
  - [Terraform](https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks)
  - [Replace Tokens](https://marketplace.visualstudio.com/items?itemName=qetza.replacetokens)

## IaC Terraform
The Terraform main file is located at [main.tf](main.tf).

## CI/CD
Continous Integration and Delivery is achieved through a single Pipeline using the [azure-pipelines.yml](azure-pipelines.yml) YAML file. This was linked to in a new Azure DevOps Pipeline and defines build steps as well as the different environmental stages.

Comments were added to the file to facilitate review and reading.

![ADO Pipeline](readme/img/adoPipeline.png)

## Summary
- All the Pipeline build steps are triggered as soon as code is commited to the master branch. In a more complete setup we could have multiple branch and policies and conditions created around these, including managing Pull Requests.
- A single Artifact is created and that is simply to produce the Terraform file to be consumed by the Pipeline. The defined IaC resources are then deployed to an existing Resource Group.
- An Azure Key Vault Task is used to retrieve the relevant Administrator Secrets for the VMs. This is possible by adding the Service Account to the KV Access Policies as explained in [Prerequisites](#Prerequisites).

![ADO Pipeline Flow](readme/img/adoPipelineFlow.png)
