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