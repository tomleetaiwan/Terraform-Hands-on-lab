# 變數宣告
variable "prefix" {
  default     = "demo"
  description = "建立雲端資源時統一命名"
}

variable "location" {
  default     = "eastasia"
  description = "定義變數 location 來決定資料中心"
}

variable "username" {
  default     =  "<您的登入帳號>"
  description = "定義 Linux VM 預設系統管理員帳號"
}

variable "password" {
  default     =  "<您的登入密碼>"
  description = "定義 Linux VM 預設系統管理員密碼"
}