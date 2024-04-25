# 在 Microsoft Azure 上使用 [IBM/HashiCorp Terraform](https://www.terraform.io/docs/cli-index.html) 實機操作

## Terraform 與 Microsoft Azure 相關資源
* [Terraform on Microsoft Azure 首頁](https://docs.microsoft.com/zh-tw/azure/terraform/)
* [Terraform 所能建立之 Azure 資源清單](https://registry.terraform.io/browse/modules?provider=azurerm)
* [Terraform 建立 Azure 資源範例](https://github.com/terraform-providers/terraform-provider-azurerm/tree/master/examples)

## Lab 0 準備工作，安裝 Terraform
* [下載您作業系統版本的 Terraform](https://www.terraform.io/downloads.html) 後將其解壓縮，只有一個單一可執行檔 terraform.exe (Windows) 或 terraform (MacOS,Linux,FreeBSD)
* 將檔案放置到可以在命令模式搜尋到的路徑 (可由系統環境變數 PATH 設妥)，本實機操作使用 Terraform v1.8.1 版本。

## Lab 1 連接至 Microsoft Azure
Terraform 可透過數種方式連接 Microsoft Azure :
* [Authenticating to Azure using the Azure CLI](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli)
* [Authenticating to Azure using Managed Identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/managed_service_identity)
* [Authenticating to Azure using a Service Principal and a Client Certificate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_certificate)
* [Authenticating to Azure using a Service Principal and a Client Secret](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret)

本次使用以 Service Principal 搭配 Client Secret 方式設定，步驟如下:
1. 列出所有 Azure 訂閱帳號
```bash
az account list --query "[].{name:name, subscriptionId:id, tenantId:tenantId}"
```

2. 紀錄回傳的 <訂閱帳號 ID> (subscriptionId) 與 <租戶 ID> (tenantId)

3. 挑選特定 Azure 訂閱帳號，將訂閱帳號 ID 填入下列命令
```bash
az account set --subscription="<訂閱帳號 ID>"
```

4. 建立 Service Principal 
```bash
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<訂閱帳號 ID>"
```
5. 紀錄回傳的 \<appId>  (又稱 Client ID) 與 \<password> (又稱 Client Secret) ，請注意僅會顯示一次，請務必記錄下來

6. 將相關記錄下來值設定至環境變數

* 使用 bash 的方式
```bash
ARM_SUBSCRIPTION_ID = <訂閱帳號 ID>
ARM_CLIENT_ID = <之前紀錄的 appID>
ARM_CLIENT_SECRET =  <之前紀錄的 password>
ARM_TENANT_ID = <租戶 ID>
ARM_ENVIRONMENT = public
```
* 使用 PowerShell 的方式

```powershell
$env:ARM_SUBSCRIPTION_ID = "<訂閱帳號 ID>"
$env:ARM_CLIENT_ID = "<之前紀錄的 appID>"
$env:ARM_CLIENT_SECRET =  "<之前紀錄的 password>"
$env:ARM_TENANT_ID = "<租戶 ID>"
$env:ARM_ENVIRONMENT = "public"
```
若要測試一些尚未公開技術預覽之 Microsoft Azure 服務或資料中心時，可以強制忽略目前 Azure Terraform Provider 預設對於參數值的檢查，請將以下環境變數設為 false。

* 使用 bash 方式
```bash
ARM_PROVIDER_ENHANCED_VALIDATION = false
```
* 使用 PowerShell 的方式
```powershell
$ENV:ARM_PROVIDER_ENHANCED_VALIDATION = "false"
```


## Lab 2 首次使用 Terraform

* 目標 : 建立一個資源群組內包含三個 Azure Storage 帳號，建立在東亞機房。其 HCL 檔案名稱為 main.tf，使用 HCL 語法，亦可至 Repo [下載原始程式碼](https://github.com/tomleetaiwan/Terraform-Hands-on-lab/tree/master/Storage) 參考。由於東亞機房可用機器數量較少，某些免費試用訂閱帳號可能無法順利建立雲端資源，若遇到此種狀況，您可以運用以下 Azure CLI 指令，列出所有 Azure 資料中心名稱，挑選其他資料中心取代預設的 "eastasia"
```bash
az account list-locations -o table
``` 


* 以命令列模式建立一個資料夾，並進入該資料夾
* 如下鍵入進行初始化，初始化只須執行一次
```bash
terraform init 
``` 
* 確認已建立妥 main.tf 檔案，檔案內容如下:
```terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  default = "eastasia"
}

# 預設的資源群組名稱請修改  
variable "resource_group_name" {
  default = "<您預設之資源群組名稱>"
}

# 預設的資源群組名稱請修改。請注意名稱必須為小寫英文數字 3-24 字元所組成
variable "storage_name" {
  default = "<您預設之儲存體帳號名稱>"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "sa" {
  count                    = 3
  name                     = format("%s%02d", var.storage_name, count.index)
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_replication_type = "LRS"
  account_tier             = "Standard"
}
``` 

* 如下鍵入嘗試產生執行計畫
```bash 
terraform plan 
``` 
* 確認執行計畫無錯誤訊息
* 如下鍵入執行執行計畫，最後需要鍵入 yes 確認
```bash
terraform apply 
```
* 成功後以 [Azure Management Portal](https://portal.azure.com/) 確認是否如實產生

## Lab 3 使用變數檔
* 目標 : 將變數設定從 main.tf 移出，單獨放在一個名為 variables.tfvars 的檔案中，並由變數檔設定將資料中心改為東南亞機房，
* 以命令列模式進入到 main.tf 所在資料夾
* 確認已建立妥 variables.tfvars 檔案內容如下:
```bash
location            = "southeastasia"
```
* 請確認 main.tf 與 variables.tfvars 位於同一資料夾中，如下鍵入嘗試產生執行計畫
```bash
 terraform plan -var-file="variables.tfvars" 
```

* 確認執行計畫無錯誤訊息，如下鍵入執行執行計畫
```bash
terraform apply -var-file="variables.tfvars" 
```
* 若希望 Terraform CLI 執行時自動帶入變數值，可將延伸檔名設定為 .auto.tfvars，可減少附加 -var-file 參數內容。

* 成功後以 [Azure Management Portal](https://portal.azure.com/) 確認是否如實產生。variables.tfvars 與 variables.tf 兩者之間有何差異?  variables.tf 可議定義變數，而是否設定變數值可由撰寫的工程師決定。而 variables.tfvars 則是專門用於設定變數值，無法定義新的變數於其內。

## Lab 4 清除與恢復環境
* 如下鍵入刪除在 Azure 訂閱帳號在本 Lab 所建立的所有內容
```bash
terraform destroy
```
* 成功後以 [Azure Management Portal](https://portal.azure.com/) 確認是否全部清除

## 其他範例

* [Storage](https://github.com/tomleetaiwan/Terraform-Hands-on-lab/tree/master/Storage) : 本次 Hands-on lab 內容，建立三個 Azure Storage 帳號，展示 Terraform 基本功能
* [ResourceGroup](https://github.com/tomleetaiwan/Terraform-Hands-on-lab/tree/master/ResourceGroup) : 建立兩個 Azure Resource Group 示範 Terraform output 與 Data 功能
* [AppService](https://github.com/tomleetaiwan/Terraform-Hands-on-lab/tree/master/AppService) : 建立 Azure App Service Web App Free Tier 與 Azure SQL Database Basic
* [AppServiceModule](https://github.com/tomleetaiwan/Terraform-Hands-on-lab/tree/master/AppServiceModule) : 建立 Azure App Service Web App Free Tier 與 Azure SQL Database Basic 但將資料庫建立部分拆成獨立模組
* [LinuxVM](https://github.com/tomleetaiwan/Terraform-Hands-on-lab/tree/master/LinuxVM) : 建立 Linux Azure Virtual Machine 與 Azure VM Extension - Azure Monitor Agent 的最簡範例
* [LinuxVM-LB](https://github.com/tomleetaiwan/Terraform-Hands-on-lab/tree/master/LinuxVM-LB) : 建立 Linux Azure Virtual Machine 與 Azure Load Balancer 基本版，本範例是修改來自 https://github.com/terraform-providers/terraform-provider-azurerm/tree/master/examples/virtual-machines/linux/load-balanced 的範例，並使用 variables.tf 來定義與設定變數值
