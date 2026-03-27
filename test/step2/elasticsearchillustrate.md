### elastic search ymal ECK 
### ECK ES 叢集
```yml
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: quickstart
```
- 使用 ECK 自訂資源建立 ES 叢集
- 名稱是 quickstart，會對應到生成的資源名，如 quickstart-es-master-node-0
---
# 叢集版本
```yml
spec:
  version: 8.16.1
```
- 部署 Elasticsearch 8.16.1
- 你需要確保你的 Helm chart 或 Operator 支援這個版本
---
### 第一組節點：master-node
```yml
nodeSets:
  - name: master-node
    count: 3
```
- 部署 3 個主節點 Pod，負責叢集管理
```yml
    config:
      node.roles: ["master"]
```
- 這些節點只扮演 master，不參與資料儲存
```yml
      cluster.name: "quickstart"
      discovery.seed_hosts: ["quickstart-es-master-node"]
      cluster.initial_master_nodes: ["quickstart-es-master-node-0"]
```
- 用來初始化叢集的配置
- quickstart-es-master-node 是對應 StatefulSet 自動建立的 headless service 名稱
```yml
    volumeClaimTemplates:
      - metadata:
          name: elasticsearch-data
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 10Gi
          storageClassName: standard
```
- 每個 master Pod 都會建立一個 PVC 名為 elasticsearch-data，容量為 10Gi
- 與你前面手動建立的 pv-master-* 是對應的
---
### 第二組節點：data-nodes
```yml
  - name: data-nodes
    count: 3
```
- 部署 3 個 Data node Pod，負責儲存資料與處理請求
```yml
    config:
      node.roles: ["data" , "ingest", "ml"]
```
- 每個節點有三種角色：

- data: 儲存與查詢資料

- ingest: 前處理管線（Ingest Pipeline）

- ml: 機器學習相關功能

```yml 
    volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 1000Gi
        storageClassName: standard
```
- 每個 data node 有一塊 1000Gi 的持久化磁碟。

- 會產生 PVC：elasticsearch-data-quickstart-es-data-nodes-0, -1, -2。

- 對應你手動建立的 pv-quickstart-data-*
---
### 配合前面你手動建立的 PV 是怎麼綁定的？
| PV 名稱                  | 對應 PVC 名稱                                        | 節點角色         |
| ---------------------- | ------------------------------------------------ | ------------ |
| `pv-master-0`          | `elasticsearch-data-quickstart-es-master-node-0` | Master Pod 0 |
| `pv-master-1`          | `elasticsearch-data-quickstart-es-master-node-1` | Master Pod 1 |
| `pv-master-2`          | `elasticsearch-data-quickstart-es-master-node-2` | Master Pod 2 |
| `pv-quickstart-data-0` | `elasticsearch-data-quickstart-es-data-nodes-0`  | Data Pod 0   |
| `pv-quickstart-data-1` | `elasticsearch-data-quickstart-es-data-nodes-1`  | Data Pod 1   |
| `pv-quickstart-data-2` | `elasticsearch-data-quickstart-es-data-nodes-2`  | Data Pod 2   |
你的 claimRef（PV YAML） 與這份 ECK Elasticsearch YAML 是一一對應的

---
###  總結
| 項目          | 說明                        |
| ----------- | ------------------------- |
| 叢集名稱        | `quickstart`              |
| 節點數         | master: 3、data: 3         |
| 使用者定義 PV    | 靜態綁定（hostPath 與 local）    |
| 每個節點有獨立 PVC | 名稱與 PV YAML 中 claimRef 對應 |
| 硬碟大小        | master: 10Gi，data: 1000Gi |
