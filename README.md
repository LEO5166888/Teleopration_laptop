# Teleopration_laptop

給學生在自己的 Mac 筆電上使用的 SO-101 鍵盤遙控工具，也保留之後手機遙操作需要的 Mac relay。

目前環境架設票只要求 **Mac 鍵盤控制**。鍵盤程式會直接經過 SSH tunnel 連到 Server，因此不需要先架手機 App、8765 relay、HTTPS/WSS 或 iPhone 憑證。

Thomas 的手機 UI 由 private repository `WIDM/teleop-app` 維護，沒有複製到這個 repository。未來要整合手機時，再向 Thomas 取得權限並鎖定 App commit。

## 每位學生的連線方式

每位學生都在自己的筆電 clone 本 repository：

```text
學生自己的 Mac 鍵盤
  → mac_hold_teleop.py
  → 該學生 Mac 的 ws://127.0.0.1:8766
  → 該學生自己的 SSH local forward
  → 實驗室 Server/Docker 的 127.0.0.1:8766
  → S4 Bridge
  → Isaac Sim SO-101
```

多人規則：

1. 每個人都可以先在自己的筆電完成安裝與 tunnel 設定。
2. **同一時間只能有一位操作者連線並控制。**
3. 換人前，前一位必須按 `Q` 關閉鍵盤程式。
4. 不可兩人同時按鍵測試，也不可共用同一個命令序號狀態。
5. Server 畫面異常時，所有人都先停止，指定一人排查。

## Repository 邊界

| Repository | Owner | 負責內容 |
|---|---|---|
| `LEO5166888/Teleopration_laptop` | Leo | 學生筆電鍵盤控制、診斷工具與選用的手機 relay |
| `LEO5166888/Teleopration_SO-101` | Leo | Docker、Isaac Sim S4、Bridge 與任務邏輯 |
| `WIDM/teleop-app` | Thomas/WIDM | 之後使用的 iPhone Teleop UI 與 HTTPS/WSS server |

請勿手動複製 Thomas App 原始碼到本 repository。手機測試時應記錄實際使用的 App commit SHA。

## 檔案

| 檔案 | 用途 |
|---|---|
| `mac_hold_teleop.py` | **目前環境架設票的入口**：按住鍵盤移動、放開停止 |
| `mac_move_delta.py` | 鍵盤工具共用的訊息與回覆 helper |
| `mac_keyboard_teleop.py` | 輸入一個按鍵再按 Enter 的診斷工具 |
| `mac_estop.py` | 急停診斷 client |
| `mac_estop_reset.py` | 解除急停診斷 client |
| `mac_disconnect_estop.py` | 斷線進入 Estop 的檢查工具 |
| `mac_phone_relay.py` | 之後手機控制使用的透明 WebSocket relay |
| `test_mac_phone_relay.py` | relay 本機來回測試 |
| `docs/THOMAS_APP_HOLD_PROTOCOL.md` | App 與 Bridge 的按住控制訊息規格 |

## 需求

- 學生自己的 macOS 筆電與 Python 3。
- Thomas 提供的實驗室 Server 個人帳號。
- Docker S4 已顯示 `S4 WS READY ws://127.0.0.1:8766`。
- 學生 Mac `127.0.0.1:8766` 已透過 VS Code 或 SSH local forward 轉到 Server `127.0.0.1:8766`。
- Mac 需有圖形桌面，因為 `mac_hold_teleop.py` 會開啟 Tk 控制視窗。

## 第一次設定［每位學生各自在自己的 Mac 執行］

```bash
cd "$HOME/Documents"
git clone https://github.com/LEO5166888/Teleopration_laptop.git
cd Teleopration_laptop
./scripts/setup_mac.sh
git rev-parse --short HEAD
```

將最後的 commit SHA 記在 Notion worklog。Python dependency 固定為已驗證的 `websockets==12.0`。

## 每次啟動鍵盤控制

### 1. 指定一位當次操作者

先在群組確認當次操作者。其他人的鍵盤程式保持關閉。

### 2. 啟動 Server／Docker

依 Server repository 的鍵盤驗收手冊啟動：

<https://github.com/LEO5166888/Teleopration_SO-101/blob/main/output/onboarding/ON-1_Isaac_Sim_%E9%8D%B5%E7%9B%A4%E6%93%8D%E6%8E%A7_%E5%BF%AB%E9%80%9F%E9%A9%97%E6%94%B6.md>

Docker Terminal 必須看到：

```text
S4 PICK_PLACE SIM READY
S4 WS READY ws://127.0.0.1:8766
```

### 3. 當次操作者檢查自己的 SSH tunnel

在自己的 Mac 執行：

```bash
lsof -nP -iTCP:8766 -sTCP:LISTEN
```

若已看到 `Code Helper` 或 `ssh` 監聽 `127.0.0.1:8766`，不要重複建立。

只有完全沒有輸出時，才把 placeholder 換成 Thomas 提供的個人帳號與 Server 位址：

```bash
ssh -N -o ExitOnForwardFailure=yes \
  -L 127.0.0.1:8766:127.0.0.1:8766 \
  <STUDENT_ACCOUNT>@<LAB_HOST>
```

登入後 Terminal 停在空白畫面是正常的，測試期間保持開啟。每位學生的 tunnel 都只存在自己的筆電上，不會共用 `localhost`。

### 4. 當次操作者開啟鍵盤控制

在另一個 Mac Terminal：

```bash
cd "$HOME/Documents/Teleopration_laptop"
git pull --ff-only origin main
./scripts/start_keyboard.sh
```

預期輸出：

```text
S4 HOLD CONTROL READY — use the focused control window
```

先點一下新開啟的控制視窗，再按鍵。

| 按鍵 | 功能 |
|---|---|
| `W / S` | 往桌內／往機器人底座 |
| `A / D` | 往綠色目標／反方向 |
| `R / F` | 上／下 |
| 按住 `I / K` | wrist flex 正／反向 |
| 按住 `O / C` | 張開／閉合夾爪 |
| `1 / 2` | fine／coarse |
| `M` | base／tool frame |
| `E / T` | 急停／解除急停 |
| `0` | 重置場景 |
| `Q` | 關閉控制器 |

桌面附近一律使用 `fine + base`。按住移動鍵才會移動；放開或視窗失去焦點就會停止。

### 5. 最小驗收

1. 短暫按住 `R`，WebRTC 應看到向上移動。
2. 放開 `R`，動作必須停止。
3. 按 `E`，再按移動鍵；命令必須被拒絕且手臂不得移動。
4. 按 `T`，再做一次安全短移動。
5. 按 `0`，手臂、夾爪與方塊必須回到初始場景。

必須同時看到 Terminal ACK／state 與 WebRTC 實際動作。只有 ACK 不算通過。

### 6. 換下一位學生

1. 現任操作者放開所有鍵。
2. 必要時按 `0` 回到初始場景。
3. 按 `Q` 關閉控制器。
4. Terminal 確認連線已結束。
5. 下一位學生才可啟動自己的 `./scripts/start_keyboard.sh`。

## 選用：之後的手機整合

目前鍵盤票做到上一節即可。只有開始手機整合時才執行本節。

### 啟動 Mac relay

```bash
cd "$HOME/Documents/Teleopration_laptop"
./scripts/start_relay.sh
```

預期輸出：

```text
MAC PHONE RELAY READY listen=ws://0.0.0.0:8765 upstream=ws://127.0.0.1:8766
Thomas App URL: ws://<Mac LAN IP>:8765
One App connection; no command buffering or automatic retry.
```

### 取得 Thomas App

Thomas 加入 private repository 權限後：

```bash
git clone git@github.com:WIDM/teleop-app.git
cd teleop-app
git rev-parse --short HEAD
```

依該 commit 的 README 啟動。Leo 於 2026-10-14 驗證的入口是：

```bash
.venv/bin/python serve_https.py
```

若 current README 不同，以鎖定 commit 的 README 為準，並將差異寫進 Notion worklog。

### relay 本機測試

```bash
.venv/bin/python test_mac_phone_relay.py
```

預期最後一行：

```text
MAC PHONE RELAY LOCAL ROUND-TRIP PASS
```

這只能證明 relay 的本機來回，不能證明 SSH tunnel、手機 App、WebRTC 或 Isaac Sim 實際動作。

## 安全規則

- 先用鍵盤 `fine + base` 測一個安全方向。
- 等 final ACK 後才能送下一個命令。
- 被拒絕的命令不可自動重送。
- 出現 `rejected`、IK failure、Estop、連線失敗、方向錯誤、碰撞或穿模時立即停止。
- 多人測試時，只接受指定操作者的控制；其他人不得同時連線。
- 不可 commit `.cert`、PEM、private key、密碼或 JSONL session log。

## 更新規則

Mac 端程式以本 repository 為主要版本。Server repository 若仍保留相容副本，測試報告必須同時記錄兩邊的 commit SHA，避免混用版本。

