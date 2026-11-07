# 提案：手機／平板完成任務與最終人工檢查

> 狀態：**討論中**。這份文件還沒實作，用來先對齊流程與做法，第 7 節是待決定的問題。

## 1. 目標

讓使用者**只用手機或平板**就能跑完整個流程：

1. 交付任務
2. 確認 bot 的分工計畫（可略過）
3. 收到彙整結果
4. 檢查實際修改（PR）
5. 核准、要求修改或取消
6. 合併上線

全程不需要開電腦，也不需要打長指令。

## 2. 使用的工具（不另外開發 App）

| 用途 | 工具 | 理由 |
|---|---|---|
| 交付任務、回覆指令 | **GitHub Mobile**（Issue／留言） | 現有 Team Bot 已用留言觸發，不用另建介面 |
| 推播通知 | GitHub Mobile 推播 | 預設就有；之後可再加 LINE 或 Slack |
| 檢查程式碼、核准、合併 | GitHub Mobile 的 PR 審查 | 手機上可以看 diff、Approve、Merge |
| 對話式追問（選用） | Claude App 雲端 session | 需要來回討論時使用 |

## 3. 流程

```
📱 交付任務（Issue 表單或 /team 留言）
   │  bot 加 👀，並貼上標籤 team:planning
   ▼
① 分派：Planner 拆子任務，貼出「分工計畫卡」
   │
   ├─ 🔸 人工檢查點 A（可選）：在手機上勾選「✅ 開始執行」或回覆 /go
   ▼
② 分工：各 bot 平行處理（team:working）
   ▼
③ 匯總：貼出適合手機閱讀的結果卡（team:review）
   │
   ├─ 🔸 人工檢查點 B：勾選「✅ 依此方案修改程式碼」，或用 /revise 補充意見
   ▼
④ 實作（新增）：Implementer bot 依最終方案修改，開 Draft PR，等 CI 跑完
   ▼
⑤ 🔸 最終人工檢查 C：在 GitHub Mobile 看 PR 摘要卡和 diff
   │     ├─ Approve → Merge（標籤 team:done）
   │     ├─ /revise <意見> → 回到 ④ 修改同一個 PR
   │     └─ /cancel → 關閉 PR，結束
   ▼
✅ 完成通知
```

**重點：bot 永遠不會自己合併。** 最後一步一定由人在手機上按下 Approve 與 Merge，並以 branch protection 強制要求。

## 4. 手機上的操作方式

手機打字不方便，所以操作以**點擊**為主、**短指令**為輔。

### 4.1 可勾選的清單（主要方式）
bot 貼出的卡片裡放 Markdown checkbox，在 GitHub Mobile 上直接點就能勾選。勾選會觸發 `issue_comment: edited` 事件，bot 讀到後執行下一步。

```markdown
**下一步（點選一項）**
- [ ] ✅ 依此方案修改程式碼並開 PR
- [ ] ✏️ 需要調整（請另外留言說明）
- [ ] ❌ 取消任務
```

### 4.2 短指令（備用）
| 指令 | 作用 |
|---|---|
| `/team <任務>` | 交付任務 |
| `/go` | 確認計畫，開始執行 |
| `/revise <意見>` | 依意見重做或修改 PR |
| `/status` | 查詢目前進度 |
| `/cancel` | 取消任務 |

### 4.3 Issue 表單（交付任務）
用 `.github/ISSUE_TEMPLATE/team-task.yml` 提供選項欄位，在手機上不用打長文：
- 任務描述（必填）
- 類型：調查／修 bug／新功能／重構
- 是否需要改程式碼：是／只要分析
- 是否需要先確認計畫：是／直接執行

## 5. 適合手機閱讀的輸出格式

每張卡片都遵守：**第一個畫面就看得懂，細節收在折疊區塊。**

```markdown
## 📋 結果：登入變慢的原因是 N+1 查詢
**建議**：在 `SessionsController` 加 `includes(:roles)`（修改 1 個檔案，風險低）

| 項目 | 狀態 |
|---|---|
| 影響範圍 | 2 個檔案 |
| 測試 | ✅ 3 個新案例 |
| 風險 | 🟢 低 |

<details><summary>🔍 調查細節</summary>…</details>
<details><summary>🧪 測試計畫</summary>…</details>
<details><summary>📝 分工紀錄</summary>…</details>

**下一步（點選一項）**
- [ ] ✅ 依此方案修改並開 PR
- [ ] ❌ 取消
```

PR 的最終檢查卡另外附上：
- 用一句話列出每個檔案改了什麼，不必在手機上逐行看 diff 也能掌握重點
- CI 結果與測試數量
- **人工檢查清單**，例如：「行為符合預期？」「沒有動到不相關的檔案？」「錯誤訊息合理？」
- 有 UI 變更時附上截圖；如果有預覽環境，附上預覽連結

## 6. 狀態標籤與安全措施

**標籤**：`team:planning` → `team:awaiting-approval` → `team:working` → `team:review` → `team:pr-open` → `team:done` / `team:cancelled`
在 Issue 列表用標籤篩選，就能看到「等我處理」的項目。

**安全**
- 只有 OWNER／MEMBER／COLLABORATOR 能下指令或勾選觸發下一步；別人勾選會被忽略並還原。
- 只有第 ④ 階段能寫入程式碼，而且只寫到 `team/issue-<編號>` 分支，開的是 Draft PR。
- main 分支設定保護規則：必須有 1 位人工 Approve，而且 CI 要通過。
- 每個任務設定執行次數與子任務數量上限，控制費用。

## 7. 待討論的問題

1. **交付入口**：只用 `/team` 留言、加上 Issue 表單，還是也從 Claude App 交付？
2. **檢查點 A（確認計畫）**：每次都要，只在大任務時才要，還是由表單選項決定？
3. **操作方式**：以勾選清單為主、短指令為輔可以嗎？還是只用其中一種？
4. **推播管道**：GitHub Mobile 推播夠用嗎？需不需要 LINE 或 Slack？
5. **第 ④ 階段**：分析完是否一律接著實作，還是一定要人工勾選後才實作？（建議要勾選）
6. **核准人**：只有你本人，還是任何協作者都可以核准與合併？
7. **預覽環境**：這個 Rails 專案有沒有部署預覽（例如 Render、Fly.io），可以在手機上直接操作驗證？

## 8. 預計實作範圍（確認後才做）

| 項目 | 檔案 |
|---|---|
| Issue 任務表單 | `.github/ISSUE_TEMPLATE/team-task.yml` |
| 勾選與指令處理 | `team-bot.yml` 新增 `issue_comment: edited` 和指令路由 |
| 第 ④ 階段實作與開 PR | `team-bot.yml` 新增 `implement` job |
| 手機版卡片格式 | `prompts/aggregator.md`，以及新增的 `prompts/pr-summary.md` |
| 狀態標籤 | workflow 各階段自動切換 |
| 保護規則 | 在 GitHub 設定中手動開啟（附上步驟說明） |
