# Rocky-ELK-Forge
# Rocky-ELK-Forge：自動化 ELK Stack 監控實驗室佈署指南

> **Project Maintainer:** [sam-l-112](https://github.com/sam-l-112)
> **Environment:** Rocky Linux 8/9
> **Goal:** 快速建置整合資安監控（SIEM）與日誌分析的 ELK 環境。
---

## [TOC]

---

## 📝 專案簡介
**Rocky-ELK-Forge** 是一個針對 Rocky Linux 環境開發的自動化佈署工具，旨在簡化 **Elasticsearch、Logstash、Kibana**（簡稱 ELK）的安裝與優化流程。本專案特別強化了「Forge（鍛造）」的概念，確保系統在安裝後即具備穩定的基礎配置，適合用於 **資安攻防演練（Hacker Offense & Defense）** 或 **SIEM 模擬實驗室**。

### ELK 三大組件作用
1. **Elasticsearch (儲存/搜尋)**：分散式搜尋引擎，負責儲存海量的日誌數據，並提供高效的全文檢索。
2. **Logstash (處理/過濾)**：數據處理管道，負責從多個來源（如 Nginx, Syslog）抓取數據，進行格式化與過濾後轉存至 ES。
3. **Kibana (視覺化)**：Web 圖形界面，讓管理員能透過儀表板（Dashboard）直觀地觀察系統趨勢與異常流量。

---

## 🛠 核心功能與測試項目

### 1. 自動化環境優化
- **系統配置**：自動調整 `max_map_count` 與 `limits.conf`，確保 Elasticsearch 運作時不會因記憶體限制而崩潰。
- **依賴管理**：自動檢測並安裝所需的 Java (JDK) 環境。

### 2. 安全性實作 (Security)
- **X-Pack 整合**：內置加密認證腳本，協助產生 SSL 憑證以保護節點間的通信。
- **權限控制**：支援 Role-based Access Control (RBAC) 基礎設定。

### 3. 日誌流測試 (Log Pipeline Test)
- **Grok 解析測試**：驗證 Logstash 是否能正確切割非結構化的日誌字串。
- **索引驗證**：測試數據是否能正確依照日期格式（如 `logstash-2026.03.27`）自動建立索引。

---

## 🚀 執行流程說明

本專案建議依照下列步驟進行佈署：

### Step 1: 環境初始化
確認網路連線並複製專案，腳本會優先檢查 OS 版本是否為 Rocky Linux。
```bash
git clone [https://github.com/sam-l-112/Rocky-ELK-Forge.git](https://github.com/sam-l-112/Rocky-ELK-Forge.git)
cd Rocky-ELK-Forge
sudo chmod +x *.sh
```
---
# Step 2: 基礎架構安裝
```bash
./install_es.sh
```

