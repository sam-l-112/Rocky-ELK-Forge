# Rocky-ELK-Forge
# Rocky-ELK-Forge：自動化 ELK Stack 監控實驗室佈署指南

> **Project Maintainer:** [sam-l-112](https://github.com/sam-l-112)
> **Environment:** Rocky Linux 8/9
> **Goal:** 快速建置整合資安監控（SIEM）與日誌分析的 ELK 環境。

---

## 📌 目錄
* [📝 專案簡介](#-專案簡介)
    * [ELK 三大組件作用](#elk-三大組件作用)
* [🛠 核心功能與測試項目](#-核心功能與測試項目)
* [🚀 執行流程說明](#-執行流程說明)
    * [Step 1: 環境初始化](#step-1-環境初始化)
    * [Step 2: 基礎架構安裝](#step-2-基礎架構安裝)
    * [Step 3: 配置 Logstash 數據管道](#step-3-配置-logstash-數據管道)
    * [Step 4: Kibana 啟動與網頁驗證](#step-4-kibana-啟動與網頁驗證)
* [📊 測試與驗證方式](#-測試與驗證方式)
* [🛡️ 資安實驗室建議](#️-資安實驗室建議)
* [⚠️ 注意事項](#-注意事項)

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

### Step 1: 環境初始化
確認網路連線並複製專案，腳本會優先檢查 OS 版本是否為 Rocky Linux。
```bash
git clone https://github.com/sam-l-112/Rocky-ELK-Forge.git
cd Rocky-ELK-Forge
sudo chmod +x *.sh
```
### Step 3: 配置 Logstash 數據管道
Logstash 負責將原始日誌轉化為結構化數據，請依照以下邏輯進行配置：

1. 路徑：將自定義規則檔案放置於 /etc/logstash/conf.d/。

2. 監聽：預設開啟 5044 端口接收來自 Filebeat 的數據。

3. 過濾 (Filter)：建議使用 Grok 過濾器解析關鍵資安事件（例如：解析 /var/log/auth.log 以偵測 SSH 暴力破解）。

### Step 4: Kibana 啟動與網頁驗證
啟動 Kibana 服務後，管理員即可透過圖形化界面進行日誌分析。

- 訪問位址：http://<Server_IP>:5601

- 初次設定：登入後需先前往 "Stack Management" 建立 Index Pattern (例如 logs-*)。

---
# 測試與驗證方式
使用以下指令或操作確認各項組件是否正常運作：

|測試階段| 檢查動作| 預期結果|
| :--- | :--- | :--- |
|服務檢查| systemctl status elasticsearch | 狀態顯示為 active (running)
|API 驗證| curl -XGET 'localhost:9200' | 回傳 JSON 格式的 ES 叢集資訊
|日誌流向| 在 Kibana 點選 Discover | 看到即時滾動的日誌數據
|權限驗證| 使用 elastic 帳號登入 | 成功登入 Kibana 管理界面

---

# 🛡️ 資安實驗室建議

為了強化 Hacker Offense & Defense 的實驗效果，建議進一步實作以下場景：

1. 多機監控：在其他 4 台實驗機器部署 Filebeat，將所有系統日誌統一彙整至此 Forge 節點，實現集中化管理。

2. 攻擊模擬：使用 Hydra 或 nmap 對目標機進行暴力破解測試，並觀察 Kibana 儀表板是否能即時觸發告警。

---
# ⚠️ 注意事項
- 資源配置：Elasticsearch 較耗記憶體，建議虛擬機至少配置 4GB RAM，否則服務可能無法啟動。

- 防火牆設定：請確保 Rocky Linux 的 firewalld 已開啟 9200 (API), 5601 (Kibana), 5044 (Logstash) 端口。

- 路徑權限：執行腳本與修改設定檔時，請務必使用 sudo 權限。
---
相關資源

[Elasticsearch 官方文件](https://www.elastic.co/guide/index.html)

[GitHub Repository - Rocky-ELK-Forge](https://github.com/sam-l-112/Rocky-ELK-Forge)
