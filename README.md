# SO-101 學生筆電鍵盤遙控包

這個 repository 只做一件事：

> 讓學弟妹使用自己的 Mac 鍵盤，控制實驗室 Server 上 Isaac Sim 裡的 SO-101 手臂。

```text
學生自己的 Mac 鍵盤
  → keyboard_control.py
  → 自己 Mac 的 localhost:8766
  → 自己的 SSH tunnel
  → 實驗室 Server／Docker
  → Isaac Sim SO-101
```

## 這一週不需要做的事

- 不用手機 App。
- 不用 phone relay 或 port 8765。
- 不用錄影資料集。
- 不用 HDF5、LeRobot 或資料轉換。
- 不用收集訓練資料。
- 不用理解 IK 或 Bridge 內部程式。
- 不用操作夾爪、手腕角度或切換座標系。

第一週只要把環境裝好，證明鍵盤可以讓手臂移動並在放開後停止。

> **唯一控制入口：`./scripts/start_keyboard.sh`**
> 這個指令會啟動「按住持續移動、放開立即停止」的 keyboard teleop。
> 不要直接執行 `mac_move_delta.py`；它只是程式內部使用的 helper。

## Repository 內只有什麼

```text
README.md
requirements.txt
keyboard_control.py
mac_move_delta.py
scripts/setup_mac.sh
scripts/start_keyboard.sh
.gitignore
```

- `keyboard_control.py`：學生唯一要執行的控制程式。
- `mac_move_delta.py`：控制程式會自動載入的 helper，不用直接執行。
- `setup_mac.sh`：第一次安裝 Python 環境。
- `start_keyboard.sh`：每次開始控制時執行。

## 開始前向學長拿三項資料

```text
<STUDENT_ACCOUNT>  自己的實驗室 Server 帳號
<LAB_HOST>         Server hostname 或 IP
WebRTC 網址        用來觀看 Isaac Sim 畫面
```

第一週建議由學長先把 Docker／Isaac Sim 啟動好。學生只要確認 Server Terminal 已顯示：

```text
S4 PICK_PLACE SIM READY
S4 WS READY ws://127.0.0.1:8766
```

沒有看到這兩行時，不要啟動鍵盤控制。

## 第一次設定［每位學生在自己的 Mac 執行一次］

```bash
cd "$HOME/Documents"
git clone https://github.com/LEO5166888/Teleopration_laptop.git
cd Teleopration_laptop
./scripts/setup_mac.sh
```

看到以下訊息代表安裝完成：

```text
MAC SETUP PASS
```

## 每次開始控制

### 步驟 1：確認自己的 Mac 有沒有 tunnel

```bash
lsof -nP -iTCP:8766 -sTCP:LISTEN
```

若看到 `Code Helper` 或 `ssh` 正在監聽 `127.0.0.1:8766`，直接進入步驟 2。

完全沒有輸出時，將帳號與主機換成學長提供的值：

```bash
ssh -N -o ExitOnForwardFailure=yes \
  -L 127.0.0.1:8766:127.0.0.1:8766 \
  <STUDENT_ACCOUNT>@<LAB_HOST>
```

輸入密碼後 Terminal 停在空白畫面是正常的。這個 Terminal 要保持開啟。

### 步驟 2：開啟鍵盤控制

另外開一個 Mac Terminal：

```bash
cd "$HOME/Documents/Teleopration_laptop"
git pull --ff-only origin main
./scripts/start_keyboard.sh
```

這裡啟動的是連續 jog 控制：

1. 按下移動鍵時送出 `jog_start`。
2. 按住期間持續送出 keepalive，手臂持續移動。
3. 放開按鍵時送出 `jog_stop`，手臂停止。
4. 若視窗失去焦點或 keepalive 中斷，Server 也會停止移動。

成功時會開啟 `SO-101 Beginner Keyboard Control` 視窗，Terminal 顯示：

```text
S4 HOLD CONTROL READY — use the focused control window
```

先點一下控制視窗，再按鍵。

## 學生可以使用的按鍵

| 按鍵 | 功能 |
|---|---|
| 按住 `W / S` | 往桌內／往機器人底座 |
| 按住 `A / D` | 左右方向 |
| 按住 `R / F` | 上／下 |
| `E` | 急停 |
| `T` | 解除急停 |
| `0` | 重置場景 |
| `Q` | 關閉控制器 |

控制器固定使用 `fine + base` 安全模式：

- 按住移動鍵才會移動。
- 放開按鍵就停止。
- 控制視窗失去焦點也會停止。
- 進階按鍵全部停用。

## 第一週最小驗收

1. Mac 成功開啟控制視窗。
2. WebRTC 能看到 Isaac Sim 手臂。
3. 短暫按住 `R`，手臂向上移動。
4. 放開 `R`，手臂停止。
5. 按 `0`，場景回到初始位置。

做到這裡，這張「環境架設＋鍵盤控制」任務就完成。

## 多人使用規則

每位學生都能先在自己的 Mac 完成安裝，但 **同一時間只能一位操作者連線控制**。

換人時：

1. 現任操作者放開所有按鍵。
2. 按 `0` 回到初始場景。
3. 按 `Q` 關閉控制器。
4. 下一位學生才能執行自己的 `./scripts/start_keyboard.sh`。

## 出現問題時

以下任一情況立即放開按鍵並按 `E`：

- 方向與預期不同。
- 放開按鍵後仍在移動。
- 手臂碰撞、穿模或持續抖動。
- Terminal 顯示 `rejected`、IK failure 或連線失敗。

不要連按、不要自動重試。把 Terminal 最後的錯誤訊息貼到 Notion worklog，再請學長協助。

## 正常結束

1. 放開所有按鍵。
2. 按 `0` 重置場景。
3. 按 `Q` 關閉鍵盤控制視窗。
4. 若 tunnel 是手動開啟，在 tunnel Terminal 按 `Ctrl-C`。

