### ECK
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


---
### PVC
### PVC.yml illustrate 
---
# 前面兩個部分宣告API

```yml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-master-0
```
# 詳細說明
- 宣告這是 Kubernetes v1 API 的 PersistentVolume
- name: 每個 PV 需具備唯一名稱

---

# 容量設置

```yml
capacity:
    storage: 10Gi
```

- 宣告這塊 PV 的容量
- 注意：K8s 不會實際檢查磁碟大小，這是給 PVC 用來做比對

---

# 做節點掛載方式

```yml
accessModes:
  - ReadWriteOnce
```

- 這塊 PV 允許被 單一節點以讀寫方式掛載
- ReadWriteOnce: 最常見的模式，適用於 Elasticsearch

---

# PVC 的 綁定的 StorageClas

```yml
storageClassName: standard
```
- 指定 PVC 綁定的 StorageClass 名稱（你需要在 PVC 中使用同樣的名稱）
- 即使是 static PV，也建議指定

---

# Volume 的來源 - hostPath / local
- Master 用的是 hostPath（不建議用於 production）：
```yml
hostPath:
  path: /home/ubuntu/ELK-stack-multiple-node/task-1/step2/pvc-master/
```
- 使用 hostPath 表示這個目錄直接是 節點的檔案系統目錄。

---

# Data 用的是 local（更安全穩定）：

```yml
local:
  path: /home/ubuntu/ELK-stack-multiple-node/task-1/step2/pvc-data/
```
- 使用 local 要搭配 VolumeBindingMode: WaitForFirstConsumer 的 StorageClass，才會讓它等到 Pod 指定在哪個 node 上時才去綁定

# volumeMode: Filesystem
```yml
volumeMode: Filesystem
```
- 表示是「檔案系統」類型（而不是 raw block volume）
- 幾乎所有 Pod 都會用這種方式

---
# 避免資料意外消失
```yml
persistentVolumeReclaimPolicy: Retain
```
- 當 PVC 刪除後，PV 不會自動刪除或清除資料
- 避免資料意外消失（對於 Elasticsearch 是好事）

---
# nodeAffinity（關鍵！）
```yml
nodeAffinity:
  required:
    nodeSelectorTerms:
    - matchExpressions:
      - key: kubernetes.io/hostname
        operator: In
        values:
        - master node name
```
- 控制這個 PV 只能綁定在指定的節點上（根據 hostname）
- 你需要在這裡將 "master node name" / "data node name" 替換成實際節點名稱

---
### 綁定主機，需要主機名稱:
- 你可以用以下指令找出節點名稱：
```bash
kubectl get nodes -o wide
```
- 原本的:
```yml
values:
          - master node name 
          # change here   ✅正確的 master node hostname
```
- 然後替換：
```yml
values:
  - vm1753442845161-5384787-iaas  # 範例
```

---
# claimRef（靜態 PV 對 PVC 的預綁定）
```yml
claimRef:
  name: elasticsearch-data-quickstart-es-master-node-0
  namespace: default
```
- 這塊 PV 預綁定給指定 namespace 下的 PVC
- 避免同樣 label 的 PVC 隨機綁錯 PV
- 範例中你是把 pv-master-0 綁定到 elasticsearch-data-quickstart-es-master-node-0 這個 PVC
- 注意：如果 PVC 尚未存在，這不會生效；但當 PVC 建立時，它會自動選到這塊 PV

---
| 名稱                                               | 類型                   | 節點           | 掛載路徑                           | 備註               |
| ------------------------------------------------ | -------------------- | ------------ | ------------------------------ | ---------------- |
| `pv-master-0` \~ `pv-master-2`                   | Static PV (hostPath) | master nodes | `/home/ubuntu/.../pvc-master/` | 每個綁定一個 master 節點 |
| `pv-quickstart-data-0` \~ `pv-quickstart-data-2` | Static PV (local)    | data nodes   | `/home/ubuntu/.../pvc-data/`   | 每個綁定一個 data 節點   |

---

### master node and data node 比較
- 以下兩個在 "name: " 、 " storage: " 、 " path: "  設置不一樣
- 詳細分段:
```yml
apiVersion: v1
kind: PersistentVolume
metadata:
  name:
```
- master node and data node 的名稱設定
```yml
spec:
  capacity:
    storage: 
```
- 容量大小設定
```yml
  hostPath:
    path
```
- 路徑設定
---
- master node
```yml 
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-master-0
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  storageClassName: standard
  hostPath:
    path: /home/ubuntu/ELK-stack-multiple-node/task-1/step2/pvc-master/
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - master node name 
          # change here   ✅正確的 master node hostname
  claimRef:
    name: elasticsearch-data-quickstart-es-master-node-0
    namespace: default
```
- data node
```yml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-quickstart-data-0
spec:
  capacity:
    storage: 1000Gi
  accessModes:
  - ReadWriteOnce
  storageClassName: standard
  volumeMode: Filesystem
  persistentVolumeReclaimPolicy: Retain
  local:
    path: /home/ubuntu/ELK-stack-multiple-node/task-1/step2/pvc-data/
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:               
        - key: kubernetes.io/hostname
          operator: In
          values:
          - data node name 
          # change here   ✅正確的 data node hostname
```
---

### Supplementary introduction
---
### update pvc.yml
- 綁定master node and data node 名稱為

```yaml
claimRef:
    name: elasticsearch-data-quickstart-es-master-node-0
    namespace: default
```

```yaml
name:
    name: elasticsearch-data-quickstart-es-data-node-0
    namespace: default
```

--- 

### update elasticsearch.yml
- 指定此 nodeSet 的 Pod 只會被排程到指定的節點（node-data-5361855-iaas.novalocal）
- 這樣可以確保 data-node 只會在特定主機上運行，通常用於本地存儲或特殊硬體需求
- nodeSelector 需與 PV 的 nodeAffinity 設定一致，才能正確綁定 PVC

```yaml
podTemplate:
      spec:
        nodeSelector:
          kubernetes.io/hostname: node-data-5361855-iaas.novalocal
```

---

### update elastcisearch.yml and pvc.yml data node hostname
- data node hostname elastcisearch.yml and pvc.yml 兩個data node 名稱要一樣

pvc.yml
```yaml
- matchExpressions:               
        - key: kubernetes.io/hostname
          operator: In
          values:
          - data node name # change here   ✅正確的 data node hostname
```

elasticsearch.yml
```yaml
podTemplate:
      spec:
        nodeSelector:
          kubernetes.io/hostname: data node name  # change here   ✅正確的 data node hostname
```

---

### update elasticsearch.yml 
- Pod 雖然正常排程、PVC 有綁定，但容器無法寫入 /usr/share/elasticsearch/data。
- 你可以在 podTemplate.spec 中加入這段 initContainer，用來修改 Elasticsearch 寫入資料的目錄權限：
- name: elasticsearch-data 要跟你的 volumeClaimTemplates.metadata.name 一致。

```yaml
        securityContext:
          runAsUser: 1000
          runAsGroup: 1000
          fsGroup: 1000
        initContainers:
        - name: fix-permissions
          image: busybox
          command: ["sh", "-c", "chown -R 1000:1000 /usr/share/elasticsearch/data"]
          volumeMounts:
          - name: elasticsearch-data
            mountPath: /usr/share/elasticsearch/data
```

---

### update pvc.yaml


```yaml
local:
    path: /home/ubuntu/ELK-stack-multiple-node/task-1/step2/pvc-data/
    type: DirectoryOrCreate
```

### update elasticsearch.yml 發現master
- 用於發現 master 節點

```yaml
cluster.name: "quickstart"  # 集群名稱
      discovery.seed_hosts: ["quickstart-es-master-node-0"] # 用於發現 master 節點
```

---

### update elasticsearch.yml and pvc.yml 
- pvc.yml 所更新的內容有3 master node and 3 worker node 問題
- master node ex :
```yml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-master-0
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  storageClassName: standard
  hostPath:
    path: /home/ubuntu/ELK-stack-multiple-node/task-1/step2/pvc-master/
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - master node name 
          # change here   ✅正確的 master node hostname
  claimRef:
    name: elasticsearch-data-quickstart-es-master-node-0
    namespace: default
```

- update name 0 、 1 、 2 做三個master node and worker node 
```yml
metadata:
  name: pv-quickstart-data-0
```
- worker node ex:
```yml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-quickstart-data-0
spec:
  capacity:
    storage: 1000Gi
  accessModes:
  - ReadWriteOnce
  storageClassName: standard
  volumeMode: Filesystem
  persistentVolumeReclaimPolicy: Retain
  local:
    path: /home/ubuntu/ELK-stack-multiple-node/task-1/step2/pvc-data/
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:               
        - key: kubernetes.io/hostname
          operator: In
          values:
          - data node name 
          # change here   ✅正確的 data node hostname
```
- elasticsearch update is count :３
- master node 
```yml
spec:
  version: 8.16.1
  nodeSets:
  - name: master-node
    count: 3
    config:
      node.roles: ["master"]
      cluster.name: "quickstart"
```

- worker node 
```yml 
    count: 3
    config:
      node.roles: ["data" , "ingest", "ml"]
```

- 指定群組
```yml
      node.roles: ["master"]
      cluster.name: "quickstart"
      # 這裡用 headless service 名稱，不用帶 pod 名稱
      discovery.seed_hosts: ["quickstart-es-master-node"]
      cluster.initial_master_nodes: ["quickstart-es-master-node-0"]
```