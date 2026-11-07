# Team Bot：自動分工 → 匯總 → 回覆

在 Issue / PR 留言 `/team <任務>`，系統會自動：

```
使用者留言 /team ...
      │
      ▼
① plan       Planner bot 讀任務與程式碼庫，拆成 1～5 個子任務（JSON）
      │
      ▼
② work       每個子任務由專職 bot 平行處理（GitHub Actions matrix）
   ├─ researcher   找相關程式碼與根因
   ├─ architect    設計方案與取捨
   ├─ implementer  具體修改（diff，不自動套用）
   ├─ tester       測試案例與驗證步驟
   └─ reviewer     風險與邊界情況
      │
      ▼
③ aggregate  Aggregator bot 整合、去重、處理衝突 → 一則留言回覆使用者
```

## 設定
1. Repo → Settings → Secrets and variables → Actions：新增 Secret `ANTHROPIC_API_KEY`
2. （選用）新增 Variable `TEAM_BOT_MODEL` 指定模型
3. 只有 OWNER / MEMBER / COLLABORATOR 的留言會觸發

## 檔案
| 檔案 | 用途 |
|---|---|
| `.github/workflows/team-bot.yml` | 三階段流程 |
| `prompts/planner.md` | 分派規則與可用角色 |
| `prompts/worker.md` | 專職 bot 共同規則 |
| `prompts/aggregator.md` | 最終回覆格式 |
| `extract_plan.rb` | 解析分派結果；失敗時退回單一子任務 |

## 設計重點
- **安全**：所有 bot 唯讀（只允許 Read/Grep/Glob），留言內容透過環境變數傳入，不直接插入 shell。
- **容錯**：單一 bot 失敗不影響其他（`fail-fast: false`）；彙整失敗時直接附上各 bot 原始產出。
- **可追蹤**：開始時加 👀、完成時加 🚀，回覆附上 Actions 執行紀錄連結；分工計畫寫在 Job Summary。
- **擴充角色**：在 `planner.md` 加入新角色，並把角色名加到 `extract_plan.rb` 的 `ROLES`。
