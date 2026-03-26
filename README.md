# Hyper‑V JEA 維運與多主機部署技術文件
### 適用環境： Windows Server 2025 Datacenter Core / Hyper‑V / Active Directory
---
## 一、文件目的與設計背景
以 Just Enough Administration (JEA) 落實最小權限原則

避免將維運人員加入 Local Administrators 或 Hyper‑V Administrators

符合內控制度、ISO/資安稽核及操作追蹤需求

可快速複製部署至多台 Hyper‑V Host（未來 Cluster / S2D 直接沿用）

---
## 二、權限角色與責任分工
### 角色 A：Hyper‑V 管理員（Admin）
* AD 群組： GRP‑HyperV‑Admin
* 本機群組： Hyper‑V Administrators
* 權限說明： VM 建立 / 刪除 / 設定、vSwitch、Storage、Host 設定


### 角色 B：Hyper‑V 操作員（Operator，JEA）
* AD 群組：  GRP‑HyperV‑Operator（可巢狀 MIS 部門群組）/
* 本機群組： Remote Management Users /
* 允許操作： Get‑VM、Start‑VM、Stop‑VM、Restart‑VM /
* 禁止操作： New/Set/Remove‑VM、Host、Network、Disk 管理/


---
## 三、JEA 技術架構總覽
```
AD User
  ↓
MIS 部門群組
  ↓
GRP‑HyperV‑Operator
  ↓
Remote Management Users (WinRM 登入權)
  ↓
JEA Endpoint：HyperV‑Operator
  ↓
RoleCapability：HyperVOperator.psrc
```

---
## 四、JEA 必須的檔案結構
```
C:\Program Files\WindowsPowerShell\Modules\HyperVJEA
 ├─ HyperVJEA.psm1              （模組殼，必須存在）
 ├─ HyperV‑Operator.pssc        （JEA Session 組態）
 └─ RoleCapabilities
     └─ HyperVOperator.psrc     （角色能力定義）
```

---
## 五、Role Capability（.psrc）說明
此檔案定義操作員可執行的 Cmdlet，只能一層 Hashtable。
```
@{
  VisibleCmdlets = @(
    'Get‑VM',
    'Start‑VM',
    'Stop‑VM',
    'Restart‑VM'
  )

  ModulesToImport = @('Hyper‑V')
  VisibleExternalCommands = @()
  VisibleProviders        = @()
}
```
## 六、JEA Session Configuration（.pssc）說明
```
@{
  SchemaVersion = '2.0.0.0'
  SessionType   = 'RestrictedRemoteServer'
  RunAsVirtualAccount = $true

  RoleDefinitions = @{
    'AD_Name\GRP‑HyperV‑Operator' = @{ RoleCapabilities = 'HyperVOperator' }
  }

  ModulesToImport     = 'Hyper‑V'
  TranscriptDirectory = 'C:\JEA‑Transcripts'
}
```
## 七、操作人員實際使用方式
```
Enter‑PSSession ‑ComputerName HV‑NODE-01 ‑ConfigurationName HyperV‑Operator
```

成功後提示字元：[HV‑NODE-01]: PS>

## 八、稽核與紀錄（非常重要）
* 所有 JEA 操作自動記錄在 C:\JEA‑Transcripts
* 紀錄包含：使用者、時間、執行指令
* 建議設定定期備份或匯入 SIEM
  
## 九、部署與維運注意事項
* 必須存在 .psm1，否則 RoleCapabilities 無法被載入
* .psrc 不可再包 RoleCapabilities
* 操作員需重新登入，群組權限才會生效
* Endpoint ACL 變動後建議重啟 WinRM
  
## 十、多主機與未來擴充（Phase 2）
* 同一組 Script 可直接部署在所有 Hyper‑V 節點
* Failover Cluster / S2D 環境 不需修改權限模型
* 僅需確保每一節點皆部署 JEA Endpoint
