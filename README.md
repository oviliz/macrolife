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
- **Azure Subscription** with two **Resource Groups**, one for the Azure DevOps (ADO) Pipeline and a static RG (i.e. with manually deployed resources) to host the suposedly pre-existing Azure Key Vault (we would also use this to create a new Storage Account via ADO Pipeline for the Terraform state file)

![image](https://user-images.githubusercontent.com/73616/126718551-0a788f5a-ecf8-40fc-99e0-438237476949.png)

- **Azure Key Vault** with relevant Secrets for Windows VM Administrator; the Service Principal automatically created by the ADO Service Connection to the static RG, needs adding to the Key Vault Access Policies with GET and LIST permissions

- **Azure DevOps** (ADO) **Project**

- **ADO Service Connections**, one per Azure Resource Group (avoid granting general access to whole subscriptions!); to make life easier, name them after Resource Groups

![image](https://user-images.githubusercontent.com/73616/126718612-41181ea3-f71b-4c5f-9fbf-8f4eaea120f7.png)

- **ADO Extensions**:
  - [Terraform](https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks)
  - [Replace Tokens](https://marketplace.visualstudio.com/items?itemName=qetza.replacetokens)

## IaC Terraform
The Terraform main file is located at [main.tf](main.tf).

## CI
A single Artifact is set up to simply provide the Terraform file to the CD Release Pipeline to be consumed.

![image](https://user-images.githubusercontent.com/73616/126718357-de09eb31-0cf3-4160-bf6a-6a465e1de6b8.png)

This could further be improved with a stage executing `terraform plan` with results to be approved as a condition for a Pull Request to be accepted.

## CD
The Artifact is loaded in a Release Pipeline with multiple tasks:

1. Azure CLI - Create Storage Account and Container
```csharp
call az storage account create --name $(TerraformStorageAccount) --resource-group $(TerraformStorageRG) --location uksouth --sku Standard_LRS
call az storage container create --name $(TerraformContainer) --account-name $(TerraformStorageAccount)
```

2. Azure PowerShell - Get Storage Account Key and update env variable
```powershell
$key=(Get-AzureRmStorageAccountKey -ResourceGroupName $(TerraformStorageRG) -AccountName $(TerraformStorageAccount)).Value[0]
Write-Host "##vso[task.setvariable variable=StorageKey]$key"
```

3. Azure Key Vault - Get Azure Key Vault Secrets with the VM passwords (another approach could have been that of linking the Key Vault Secrets as Variables in the ADO Project by adding a Variable Group from Library)
```yaml
- task: AzureKeyVault@2
  inputs:
    azureSubscription: '$(TerraformStorageRG)'
    KeyVaultName: '$(KVname)'
    SecretsFilter: 'VM1AdminPWD,VM2AdminPWD'
```

4. Replace Tokens to replace __ in the Terraform file
```yaml
- task: replacetokens@3
  inputs:
    targetFiles: |
      **/*.tf
      **/*.tfvars
    escapeType: none
    tokenPrefix: '__'
    tokenSuffix: '__'
```

5. Terraform Tool Installer - Install latest Terraform 1.0.3 on the agent pool
```yaml
- task: TerraformInstaller@0
  inputs:
    terraformVersion: '1.0.3'
```

6. `terraform init -input=false` - prepare current working directory for use with Terraform; this will also connect to the backend Storage Account

7. `terraform plan` - creates the execution plan

8. `terraform apply -input=false -auto-approve` - executes the plan

![image](https://user-images.githubusercontent.com/73616/126720764-a6eebd90-7b89-4d15-8b5c-4fcfd4be7479.png)

### Variables

![image](https://user-images.githubusercontent.com/73616/126719501-0eb85cd9-dcf5-45e8-a22b-926a6564e62b.png)

## Summary
- All the Pipeline build steps are triggered as soon as code is commited to the master branch. In a more complete setup we could have multiple branch and policies and conditions created around these, including managing Pull Requests.
- The scenario was approached in a simplistic way so a single Artifact is created to produce the Terraform file to be consumed by the Release Pipeline.
- The defined IaC resources are then deployed to an existing Resource Group with the VMs being set with adminstrative passwords retrieved from the pre-existing Key Vault.

![image](https://user-images.githubusercontent.com/73616/126720982-fe381945-6610-44ea-94fa-772f9346266b.png)
