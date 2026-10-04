# Phase 0 — Bộ tài liệu thiết kế & khung làm việc: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tạo toàn bộ tài liệu thiết kế Phase 0 của Smart WMS v1 (nghiệp vụ → giải pháp), dựng khung làm việc kiểu team trên GitHub, và backlog Phase 1 đạt Definition of Ready — không viết code sản phẩm.

**Architecture:** Docs-as-code trong monorepo `dwchwang/Smart-Warehouse-Management-System`. Mỗi tài liệu là một PR riêng vào `main`, có CI kiểm tra (markdownlint, Mermaid render, Redocly lint OpenAPI). Tài liệu nghiệp vụ đi trước (tuần 1), tài liệu giải pháp bám theo (tuần 2). Mọi tài liệu nghiệp vụ có một **checkpoint với chủ dự án** để đào sâu trước khi merge.

**Tech Stack:** Markdown + Mermaid, OpenAPI 3.1, GitHub (Issues, Projects, Actions, `gh` CLI), Node 22 (`.nvmrc`; mermaid-cli 12 cần ≥ 22.13) + `npx` (markdownlint-cli2, @mermaid-js/mermaid-cli, @redocly/cli).

**Spec:** `docs/superpowers/specs/2026-09-30-phase-0-design.md` — khi plan và spec lệch nhau, spec thắng; sửa spec trước (PR riêng) rồi mới làm khác.

## Global Constraints

- Không viết code sản phẩm trong Phase 0 (không `apps/api`, `apps/web`).
- Văn bản tiếng Việt; **mọi định danh kỹ thuật bằng tiếng Anh** (tên bảng, cột, enum, endpoint, event, mã lỗi), viết đúng như spec.
- Sơ đồ dùng Mermaid trong Markdown; tối đa 2 sơ đồ Excalidraw (`docs/03-architecture/*.excalidraw` + PNG export).
- Số lượng tồn: số nguyên, đơn vị cơ sở. Đơn vị tồn: `(sku_id, warehouse_id)`. Không có zone/rack/bin, lô/hạn dùng, serial trong v1.
- Phạm vi v1 đúng mục 3 của spec; mục "Không làm ở v1" không được xuất hiện như yêu cầu v1 (chỉ được nhắc ở phần "v2/ngoài phạm vi").
- Quy ước ID trong tài liệu: user story `US-<EPIC>-<NN>`; quy tắc nghiệp vụ `BR-<AREA>-<NN>`; bất biến `I1`–`I5`; yêu cầu phi chức năng `NFR-<NN>`; ADR `NNNN-kebab-title.md`. Epic/area: `ACC, CAT, WH, INV, INB, OUT, TRF, STK, ADJ, CH, ALR`.
- Trạng thái phiếu (giữ đúng chữ hoa): Inbound `DRAFT, CONFIRMED, RECEIVING, COMPLETED, CANCELLED`; Outbound `DRAFT, CONFIRMED, PICKING, COMPLETED, CANCELLED`; Transfer `DRAFT, CONFIRMED, IN_TRANSIT, RECEIVED, DISCREPANCY, CLOSED, CANCELLED`; Stocktake `DRAFT, COUNTING, REVIEW, ADJUSTED, CANCELLED`.
- Movement types: `INBOUND, OUTBOUND, TRANSFER_OUT, TRANSFER_IN, ADJUSTMENT`. Reservation status: `ACTIVE, COMMITTED, RELEASED`. Reason codes điều chỉnh: `DAMAGED, LOST, FOUND, COUNT_CORRECTION, OTHER`.
- Mã lỗi nghiệp vụ tối thiểu: `INSUFFICIENT_STOCK, INVALID_STATE_TRANSITION, WAREHOUSE_SCOPE_DENIED, VERSION_CONFLICT, IDEMPOTENCY_KEY_REUSED, IDEMPOTENCY_IN_PROGRESS`.
- Workflow Git: branch `docs/<slug>` (Phase 0 chưa có issue) → PR → CI xanh → squash merge vào `main`. Tên PR theo Conventional Commits (`docs: …`, `chore: …`, `ci: …`).
- Mọi commit kết thúc bằng dòng `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` khi do Claude tạo.
- Ngân sách: ~42h trong 2 tuần; ước lượng từng task ghi ở tiêu đề.

### Thủ tục merge tài liệu (MERGE-DOC)

Bước cuối của mọi task tài liệu, thay `<branch>`, `<files>`, `<title>` bằng giá trị ghi trong task:
```bash
git add <files>
git commit -m "<title>"
git push -u origin <branch>
gh pr create --title "<title>" --fill
gh pr checks --watch          # Expected: pr-title và check-docs xanh
gh pr merge --squash --delete-branch
git switch main && git pull
```

## Review Focus

1. **Tên trạng thái/enum lệch giữa các tài liệu** (state-machines ↔ ERD ↔ openapi) → người đọc sẽ tin vào một tài liệu sai. Kiểm tra bằng lệnh `grep` chéo ở Task 11 Step 6 và Task 15 Step 4.
2. **Story không truy vết được tới quy tắc và endpoint** → sang Phase 1 không biết làm theo cái gì. Bảng truy vết US → BR → endpoint ở Task 5, được hoàn tất ở Task 11 Step 7.
3. **Phiếu nhiều dòng chỉ thiếu một dòng** → người dùng cần biết *dòng nào* thiếu và còn bao nhiêu. Phải có trong BR-OUT, sequence xuất kho và schema `InsufficientStockProblem` (Task 6, 9, 11).
4. **Tính năng v2 lọt vào v1** (Kafka, Redis, bin, lô, WebSocket) → backlog phình. Lệnh `grep` chặn ở Task 5 Step 5 và Task 15 Step 4.
5. **Mermaid không render trên GitHub** → tài liệu "đẹp ở local, vỡ trên repo". CI render mọi khối Mermaid (Task 1).

---

## File Structure

```
.github/
├── workflows/docs.yml                 # CI tài liệu + kiểm tra tên PR (Task 1)
├── pull_request_template.md           # (Task 1)
└── ISSUE_TEMPLATE/
    ├── story.yml  task.yml  bug.yml  spike.yml  config.yml   # (Task 14)
.markdownlint-cli2.jsonc               # (Task 1)
redocly.yaml                           # (Task 1)
scripts/check-docs.sh                  # chạy mọi kiểm tra tài liệu (Task 1)
scripts/puppeteer-config.json          # cho mmdc trong CI (Task 1)
README.md                              # (Task 1, cập nhật Task 15)
docs/
├── 00-vision-scope.md                 # Task 2
├── 01-requirements/user-stories.md    # Task 5
├── 01-requirements/nfr.md             # Task 13
├── 02-domain/glossary.md              # Task 3
├── 02-domain/context-map.md           # Task 4
├── 02-domain/business-rules.md        # Task 6
├── 02-domain/state-machines.md        # Task 7
├── 02-domain/business-flows.md        # Task 8
├── 03-architecture/README.md          # C4 L1–L2 + sequence (Task 9)
├── 04-data/erd.md                     # Task 10
├── 05-api/conventions.md              # Task 11
├── 05-api/openapi.yaml                # Task 11
├── adr/0001 … 0009-*.md + README.md   # Task 12
└── process/workflow.md                # Task 14
    process/backlog-phase-1.md         # Task 15
    process/retros/.gitkeep            # Task 14
```

Thứ tự task bám lịch spec mục 4, trừ Task 1: khung repo + CI tài liệu phải có trước để mọi tài liệu sau đi qua PR (điều kiện "merge qua PR" của spec).

---

## TUẦN 1 — Hiểu bài toán

### Task 1: Khung repo & CI tài liệu (~3h)

**Files:**
- Create: `.markdownlint-cli2.jsonc`, `redocly.yaml`, `scripts/check-docs.sh`, `scripts/puppeteer-config.json`, `.github/workflows/docs.yml`, `.github/pull_request_template.md`, `README.md`
- Modify: branch local `master` → `main`

**Interfaces:**
- Produces: lệnh `./scripts/check-docs.sh` (exit 0 = tài liệu hợp lệ) mà mọi task sau dùng; workflow CI tên `docs` và check `pr-title`.

- [x] **Step 1: Đồng bộ branch với remote** — đã làm ngoài phiên (local `main` = `origin/main` tại `352cf5c`). Thay bằng: cài git hook `.githooks/pre-commit` chặn commit trên `main` và bật `git config core.hooksPath .githooks`; kiểm chứng trong repo tạm: commit trên `main` → exit 1, trên branch → exit 0.

- [ ] **Step 2: Tạo branch làm việc**

```bash
git switch -c docs/repo-bootstrap
```

- [ ] **Step 3: Viết cấu hình lint**

`.markdownlint-cli2.jsonc`:
```jsonc
{
  "config": {
    "default": true,
    "MD013": false,          // không giới hạn độ dài dòng (bảng tiếng Việt dài)
    "MD033": false,          // cho phép <br/> trong bảng/Mermaid
    "MD041": false,
    "MD024": { "siblings_only": true }
  },
  "ignores": ["docs/superpowers/**", "overview.md", "node_modules/**"]
}
```

`redocly.yaml`:
```yaml
extends:
  - recommended
rules:
  operation-4xx-response: error
  no-unused-components: warn
```

`scripts/puppeteer-config.json`:
```json
{ "args": ["--no-sandbox"] }
```

- [ ] **Step 4: Viết script kiểm tra**

`scripts/check-docs.sh`:
```bash
#!/usr/bin/env bash
# Kiểm tra toàn bộ tài liệu: markdownlint, Mermaid render, OpenAPI lint.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== markdownlint =="
npx --yes markdownlint-cli2 "**/*.md"

echo "== mermaid =="
tmp="$(mktemp -d)"
while IFS= read -r -d '' f; do
  if grep -q '```mermaid' "$f"; then
    echo "  render $f"
    npx --yes -p @mermaid-js/mermaid-cli mmdc -q \
      -p scripts/puppeteer-config.json \
      -i "$f" -o "$tmp/$(basename "$f")" >/dev/null
  fi
done < <(find docs -name '*.md' -not -path 'docs/superpowers/*' -print0)

echo "== openapi =="
if [ -f docs/05-api/openapi.yaml ]; then
  npx --yes @redocly/cli lint docs/05-api/openapi.yaml
else
  echo "  (chưa có openapi.yaml — bỏ qua)"
fi

echo "ALL DOC CHECKS PASSED"
```

```bash
chmod +x scripts/check-docs.sh
```

- [ ] **Step 5: Chứng minh script bắt được lỗi (test fail trước)**

```bash
mkdir -p docs && printf '# T\n\n```mermaid\nflowchart LR\n  A -->\n```\n' > docs/_broken.md
./scripts/check-docs.sh; echo "exit=$?"
```
Expected: lỗi parse Mermaid ở `docs/_broken.md`, `exit=1`.

```bash
rm docs/_broken.md
./scripts/check-docs.sh
```
Expected: `ALL DOC CHECKS PASSED`.

- [ ] **Step 6: CI workflow**

`.github/workflows/docs.yml`:
```yaml
name: docs
on:
  pull_request:
    types: [opened, edited, synchronize, reopened]
  push:
    branches: [main]
jobs:
  pr-title:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    permissions:
      pull-requests: read
    steps:
      - uses: amannn/action-semantic-pull-request@v5
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  check-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: .nvmrc
      - run: ./scripts/check-docs.sh
```

- [ ] **Step 7: PR template**

`.github/pull_request_template.md`:
```markdown
## Thay đổi gì & vì sao

<!-- 2–5 dòng. Link issue: Closes #N (Phase 0 có thể để trống) -->

## Cách kiểm chứng

- [ ] `./scripts/check-docs.sh` xanh
- [ ] Đã tự review lại vào hôm sau (hoặc đã nhờ AI review)

## Checklist

- [ ] Thuật ngữ khớp `docs/02-domain/glossary.md`
- [ ] Định danh (trạng thái, enum, mã lỗi) khớp spec / tài liệu liên quan
- [ ] OpenAPI cập nhật (nếu đổi API)
- [ ] Migration/ERD cập nhật (nếu đổi dữ liệu)
- [ ] ADR mới (nếu có quyết định kiến trúc)
```

- [ ] **Step 8: README tối thiểu**

`README.md`:
```markdown
# Smart Warehouse Management System

Hệ thống quản lý kho đa điểm cho **VietHome Distribution** (doanh nghiệp giả định, phân phối đồ gia dụng, 3 kho).
v1: modular monolith (Spring Boot) + Next.js + Keycloak + PostgreSQL.

- Thiết kế Phase 0: [`docs/superpowers/specs/2026-09-30-phase-0-design.md`](docs/superpowers/specs/2026-09-30-phase-0-design.md)
- Tài liệu: [`docs/`](docs/)

## Kiểm tra tài liệu

    ./scripts/check-docs.sh
```

- [ ] **Step 9: Kiểm tra, commit, PR, merge**

```bash
./scripts/check-docs.sh
git add .markdownlint-cli2.jsonc redocly.yaml scripts .github README.md
git commit -m "ci: add docs tooling, PR template and docs workflow"
git push -u origin docs/repo-bootstrap
gh pr create --title "ci: add docs tooling and workflow" --fill
gh pr checks --watch
gh pr merge --squash --delete-branch
git switch main && git pull
```
Expected: cả hai check `pr-title` và `check-docs` xanh trước khi merge.

- [ ] **Step 10: Bảo vệ `main`** (🧑 cần chủ dự án đồng ý — thay đổi cấu hình repo public)

```bash
gh api -X PUT repos/dwchwang/Smart-Warehouse-Management-System/branches/main/protection \
  --input - <<'JSON'
{
  "required_status_checks": { "strict": true, "contexts": ["check-docs", "pr-title"] },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
```
Expected: JSON trả về có `"required_linear_history": {"enabled": true}`. `enforce_admins: false` để chủ dự án vẫn sửa nhanh được khi CI hỏng.

---

### Task 2: Vision & phạm vi — `docs/00-vision-scope.md` (~2h)

**Files:** Create: `docs/00-vision-scope.md`

**Interfaces:**
- Consumes: spec mục 1–3.
- Produces: danh sách nỗi đau đánh số `P1`–`P5` (các tài liệu sau tham chiếu), danh sách "v1 làm" / "không làm".

- [ ] **Step 1:** `git switch -c docs/vision-scope`

- [ ] **Step 2: Viết tài liệu với đúng các mục sau**

1. `## Bối cảnh` — VietHome Distribution: ngành, nguồn hàng, 3 kênh bán (tỷ trọng), 3 kho, quy mô SKU/nhân sự, tải ngày thường và ngày sale (lấy nguyên số liệu spec mục 2).
2. `## Nỗi đau` — bảng `P1`–`P5` đúng thứ tự spec: bán vượt tồn, tồn lệch không truy vết, mất hàng khi chuyển kho, thất thoát hàng giá trị cao, nhân viên sửa nhầm kho khác. Mỗi dòng: mô tả, hậu quả kinh doanh, phần hệ thống giải quyết.
3. `## Mục tiêu sản phẩm v1` — 3–5 mục tiêu đo được, ví dụ "0 trường hợp tồn âm", "mọi thay đổi tồn truy được người + lý do + phiếu".
4. `## Phạm vi v1` — hai danh sách "Làm" / "Không làm (v2 hoặc sau)" sao chép nghĩa từ spec mục 3.
5. `## Người dùng` — 5 actor (Admin, Manager, Staff, Viewer, Channel client) + một câu mô tả công việc thường ngày của mỗi người tại VietHome.
6. `## Tiêu chí thành công v1` — demo được 5 kịch bản: hai người xuất cùng lúc không âm tồn; chuyển BN→ĐN nhận thiếu và xử lý; cycle count lệch và điều chỉnh; đơn channel gửi trùng không tạo trùng; staff Đà Nẵng không thao tác được kho Bình Dương.

- [ ] **Step 3: 🧑 Checkpoint với chủ dự án** — đọc cùng nhau, hỏi: "Có nỗi đau nào của VietHome còn thiếu hoặc muốn nhấn mạnh hơn?". Ghi lại thay đổi vào tài liệu.

- [ ] **Step 4:** `./scripts/check-docs.sh` → Expected `ALL DOC CHECKS PASSED`.

- [ ] **Step 5: Commit + PR + merge** — MERGE-DOC với branch `docs/vision-scope`, files `docs/00-vision-scope.md`, title `docs: add vision and v1 scope`

---

### Task 3: Glossary — `docs/02-domain/glossary.md` (~2h)

**Files:** Create: `docs/02-domain/glossary.md`

**Interfaces:**
- Produces: tên chuẩn tiếng Việt ↔ định danh tiếng Anh cho mọi tài liệu và code sau này.

- [ ] **Step 1:** `git switch -c docs/glossary`

- [ ] **Step 2: Viết bảng** cột: `Thuật ngữ (VN)` | `Định danh (EN, dùng trong code)` | `Định nghĩa` | `Ví dụ tại VietHome`. Bắt buộc có đủ các mục sau:

| VN | EN |
|---|---|
| Sản phẩm | `Product` |
| Biến thể / SKU | `Sku` |
| Danh mục | `Category` |
| Đơn vị cơ sở | `baseUom` |
| Quy đổi đơn vị theo SKU | `SkuUomConversion` (`qty_in_base`) |
| Kho | `Warehouse` |
| Tồn thực có | `onHand` |
| Tồn đã giữ chỗ | `reserved` |
| Tồn khả dụng | `available = onHand − reserved` |
| Hàng đang đi đường | `inTransit` |
| Mức tồn | `StockLevel` |
| Biến động tồn / Sổ cái | `StockMovement` / ledger |
| Giữ chỗ | `Reservation` |
| Tham chiếu phiếu | `referenceType`, `referenceId` |
| Phiếu nhập / xuất / chuyển / kiểm kê | `InboundOrder` / `OutboundOrder` / `TransferOrder` / `Stocktake` |
| Điều chỉnh tồn | `Adjustment` (+ `reasonCode`) |
| Nhận thiếu (nhập) | `shortQty` |
| Xuất thiếu | short pick |
| Chênh lệch chuyển kho | transit discrepancy; xử lý `WRITE_OFF` / `FOUND` |
| Đếm mù | blind count |
| Kiểm kê vòng | cycle count |
| Giữ chỗ quá hạn | stale reservation |
| Khóa chống trùng (HTTP) | `Idempotency-Key` |
| Khóa lệnh inventory | command key |
| Kênh bán / client kênh | `Channel` / channel client |
| Phạm vi kho | warehouse scope |
| Cảnh báo tồn thấp | low-stock alert (`minStock`) |
| Đối soát | reconciliation |
| Module | module |
| Sự kiện nghiệp vụ | domain event |

- [ ] **Step 3: 🧑 Checkpoint** — chủ dự án xác nhận từ tiếng Việt nào sẽ dùng trên giao diện (ví dụ "Tồn khả dụng" hay "Có thể bán").

- [ ] **Step 4:** `./scripts/check-docs.sh` → PASS.

- [ ] **Step 5: Commit + PR + merge** — MERGE-DOC với branch `docs/glossary`, files `docs/02-domain/glossary.md`, title `docs: add domain glossary`.

---

### Task 4: Context map & giải thích module — `docs/02-domain/context-map.md` (~3h)

Đây là chỗ chủ dự án đã yêu cầu **làm rõ kỹ** (spec mục 5 ghi "phác thảo").

**Files:** Create: `docs/02-domain/context-map.md`

**Interfaces:**
- Consumes: spec mục 5, glossary.
- Produces: tên 6 module `catalog, warehouse, inventory, operation, channel, access`; tên 8 domain event; tên interface `InventoryApi` và 7 lệnh `reserve, release, commit, receive, adjust, transferOut, transferIn`.

- [ ] **Step 1:** `git switch -c docs/context-map`

- [ ] **Step 2: Viết các mục**

1. `## Module là gì (giải thích cho người mới)` — 1 đoạn so sánh: monolith "một khối", microservice "nhiều app", modular monolith "một app, chia phòng có cửa". Ví dụ cụ thể: "khi staff confirm phiếu xuất, `operation` không tự sửa bảng tồn, mà nhờ `inventory` giữ chỗ — giống phòng bán hàng gọi phòng kho".
2. `## 6 module` — bảng từ spec mục 5 (Sở hữu / Ràng buộc), thêm cột "Câu hỏi nghiệp vụ module này trả lời" (ví dụ inventory: "Còn bao nhiêu, ở đâu, ai đã đổi?").
3. `## Quan hệ` — Mermaid `flowchart LR` y như spec mục 5, kèm giải thích mỗi mũi tên bằng một câu nghiệp vụ.
4. `## InventoryApi — cửa duy nhất vào tồn kho` — bảng 7 lệnh: tên, ai gọi (loại phiếu + trạng thái), tác động lên `on_hand`/`reserved`, movement sinh ra, command key mẫu. Ví dụ: `reserve` | outbound/transfer CONFIRM | `reserved += q` | không | `OUTBOUND:{orderId}:RESERVE`.
5. `## 5 luật ranh giới` — chép spec, mỗi luật thêm một câu "nếu vi phạm thì sang v2 sẽ khổ thế nào".
6. `## Domain events` — bảng 8 event: tên, phát khi nào, dữ liệu chính (`skuId, warehouseId, qtyChange, referenceType, referenceId, occurredAt`), consumer v1. Consumer: low-stock alert nghe **mọi event `Stock*`** (vì `available` giảm khi `StockReserved/StockCommitted/StockTransferredOut/StockAdjusted` âm, và tăng khi `StockReceived/StockReleased/StockTransferredIn/StockAdjusted` dương — cần cả hai chiều để bật và tắt cảnh báo); `OrderStatusChanged` ghi "chưa có consumer ở v1 (dành cho notification v2)".
7. `## Đường sang v2` — 3 gạch đầu dòng từ spec mục 11.

- [ ] **Step 3: 🧑 Checkpoint** — chủ dự án giải thích lại bằng lời của mình "khi chuyển kho thì module nào gọi module nào". Nếu chưa trôi chảy, bổ sung ví dụ vào mục 1.

- [ ] **Step 4:** `./scripts/check-docs.sh` → PASS.

- [ ] **Step 5: Commit + PR + merge** — MERGE-DOC với branch `docs/context-map`, files `docs/02-domain/context-map.md`, title `docs: add context map and module guide`.

---

### Task 5: User stories & use case — `docs/01-requirements/user-stories.md` (~5h)

**Files:** Create: `docs/01-requirements/user-stories.md`

**Interfaces:**
- Consumes: vision (P1–P5, actor), glossary.
- Produces: ID `US-<EPIC>-<NN>` dùng cho issue Phase 1; bảng truy vết (cột BR và Endpoint sẽ điền ở Task 6 và Task 11).

- [ ] **Step 1:** `git switch -c docs/user-stories`

- [ ] **Step 2: Sơ đồ use case** — Mermaid `flowchart LR`: 5 actor bên trái (node hình `([…])`), nhóm chức năng theo epic (subgraph), nối actor → chức năng đúng bảng phân quyền spec mục 6.7.

- [ ] **Step 3: Viết story** theo mẫu:

```markdown
### US-OUT-02 — Xác nhận phiếu xuất và giữ chỗ
**Là** nhân viên kho Bắc Ninh, **tôi muốn** xác nhận phiếu xuất **để** hàng được giữ cho đơn này, không ai xuất mất.
**Nỗi đau:** P1 · **Ưu tiên:** P0

**Acceptance criteria**
- Given SKU NCK-5L tại BN có onHand 10, reserved 0, phiếu DRAFT cần 8
  When tôi xác nhận
  Then phiếu CONFIRMED, reserved = 8, available = 2
- Given phiếu có 2 dòng, dòng 2 thiếu 3 cái
  When tôi xác nhận
  Then phiếu vẫn DRAFT, không dòng nào bị giữ chỗ, lỗi INSUFFICIENT_STOCK liệt kê dòng 2: cần 5, khả dụng 2
- Given tôi không thuộc scope kho BN
  When tôi xác nhận
  Then lỗi WAREHOUSE_SCOPE_DENIED
```

Danh sách story tối thiểu (mỗi cái đủ AC như mẫu, có ít nhất 1 AC lỗi):

- **ACC:** 01 đăng nhập qua Keycloak; 02 Admin gán scope kho cho user; 03 user chỉ thấy dữ liệu kho trong scope.
- **CAT:** 01 quản lý category dạng cây; 02 tạo product + SKU (barcode, `minStock`); 03 khai báo quy đổi ĐVT theo SKU; 04 tìm SKU theo barcode; 05 quản lý supplier; 06 quản lý customer/đại lý.
- **WH:** 01 quản lý kho (code `BN`, `DN`, `BD`).
- **INV:** 01 xem tồn onHand/reserved/available theo SKU × kho; 02 xem ledger một SKU tại một kho; 03 xem hàng in-transit theo tuyến.
- **INB:** 01 tạo phiếu nhập; 02 xác nhận; 03 nhận hàng một phần nhiều lần; 04 tự hoàn tất khi nhận đủ; 05 Manager đóng phiếu thiếu; 06 hủy khi chưa nhận.
- **OUT:** 01 tạo phiếu; 02 xác nhận + giữ chỗ (mẫu trên); 03 bắt đầu lấy hàng; 04 hoàn tất (có short pick + lý do); 05 hủy (Staff chỉ DRAFT; Manager khi đã giữ chỗ); 06 xem & xử lý hàng loạt giữ chỗ quá hạn; 07 sửa phiếu DRAFT với `If-Match`.
- **TRF:** 01 tạo phiếu chuyển; 02 xác nhận (giữ chỗ kho nguồn); 03 xuất đi (IN_TRANSIT); 04 kho đích nhận đủ; 05 kho đích nhận thiếu → DISCREPANCY; 06 Manager xử lý `WRITE_OFF`/`FOUND` → CLOSED; 07 hủy trước khi xuất.
- **STK:** 01 tạo phiếu kiểm kê (cả kho hoặc danh sách SKU); 02 đếm mù; 03 gửi duyệt khi đủ dòng; 04 Manager yêu cầu đếm lại dòng lệch; 05 Manager duyệt → điều chỉnh theo chênh lệch; 06 chặn khi điều chỉnh làm onHand < reserved.
- **ADJ:** 01 Manager điều chỉnh tồn có reason code.
- **CH:** 01 kênh tạo đơn (giữ chỗ ngay, có `warehouseCode`); 02 gửi lại cùng `Idempotency-Key` nhận lại kết quả cũ; 03 cùng key khác payload bị từ chối; 04 kênh hủy đơn; 05 kênh xem available.
- **ALR:** 01 cảnh báo tồn thấp (bật/tắt theo ngưỡng); 02 cảnh báo khi job đối soát phát hiện lệch.

- [ ] **Step 4: Bảng truy vết** cuối file: cột `Story | Nỗi đau | BR | Endpoint`. Điền cột Nỗi đau ngay; cột BR, Endpoint để ký hiệu `→ Task 6` / `→ Task 11` (sẽ thay bằng ID thật ở các task đó — đây là việc có chủ đích, không phải TODO bỏ quên).

- [ ] **Step 5: Kiểm tra không lọt phạm vi v2**
```bash
grep -niE "kafka|redis|websocket|bin|rack|zone|lô|hạn dùng|serial" docs/01-requirements/user-stories.md
```
Expected: không có kết quả (hoặc chỉ nằm trong mục "Ngoài phạm vi").

- [ ] **Step 6: 🧑 Checkpoint** — chủ dự án đọc từng epic, thêm/bớt story, chỉnh ưu tiên P0/P1/P2.

- [ ] **Step 7:** `./scripts/check-docs.sh` → PASS.

- [ ] **Step 8: Commit + PR + merge** — MERGE-DOC với branch `docs/user-stories`, files `docs/01-requirements/user-stories.md`, title `docs: add user stories and use case diagram`.

---

### Task 6: Quy tắc nghiệp vụ — `docs/02-domain/business-rules.md` (~4h) ⭐

**Files:**
- Create: `docs/02-domain/business-rules.md`
- Modify: `docs/01-requirements/user-stories.md` (cột BR của bảng truy vết)

**Interfaces:**
- Consumes: spec mục 6, glossary, user stories.
- Produces: ID `BR-<AREA>-<NN>` và `I1`–`I5`.

- [ ] **Step 1:** `git switch -c docs/business-rules`

- [ ] **Step 2: Viết tài liệu** — mỗi quy tắc một dòng bảng: `ID | Quy tắc | Lý do nghiệp vụ (gắn P1–P5) | Ví dụ số`. Các nhóm và quy tắc bắt buộc (nội dung lấy từ spec mục 6, không thêm bớt nghĩa):

- `## Bất biến tồn kho` — I1–I5 kèm cột "Bảo vệ bởi".
- `## BR-INV` — 01 đơn vị tồn `(sku, kho)` số nguyên; 02 in-transit không thuộc kho nào; 03 sửa sai bằng movement bù; 04 `reserved` đổi không sinh movement; 05 concurrency mặc định UPDATE có điều kiện, nhiều dòng theo `sku_id` tăng dần, all-or-nothing; 06 HTTP `Idempotency-Key` (phạm vi, TTL 7 ngày, 2 mã lỗi 409); 07 command key nội bộ; 08 đối soát chỉ cảnh báo.
- `## BR-INB` — 01 nhận nhiều lần, ghi `INBOUND` mỗi lần; 02 không nhận vượt `expected_qty`; 03 nhận đủ tự COMPLETED; 04 Manager đóng phiếu thiếu, lưu `short_qty`; 05 chỉ hủy khi chưa nhận.
- `## BR-OUT` — 01 giữ chỗ khi CONFIRM, all-or-nothing, lỗi liệt kê từng dòng thiếu (`skuId, requested, available`); 02 đơn channel tạo+confirm một request, bắt buộc `warehouseCode` trong scope client; 03 PICKING khi bấm bắt đầu; 04 giữ chỗ quá hạn 24h/48h chỉ đánh dấu, không tự hủy, ngưỡng cấu hình; 05 short pick commit phần đã lấy, release phần còn lại, bắt buộc lý do; 06 hủy → release toàn bộ; Staff chỉ hủy DRAFT.
- `## BR-TRF` — 01 CONFIRM giữ chỗ kho nguồn; 02 SHIP commit + `TRANSFER_OUT`; 03 RECEIVE do staff kho đích, `received ≤ shipped`; 04 thiếu → DISCREPANCY; 05 xử lý `WRITE_OFF` (ghi bên chịu trách nhiệm: `CARRIER`, `SOURCE_WAREHOUSE`, `DESTINATION_WAREHOUSE`) hoặc `FOUND` (ghi `TRANSFER_IN`); 06 hủy chỉ trước SHIP.
- `## BR-STK` — 01 phạm vi cả kho/danh sách SKU, không khóa kho; 02 blind count; 03 chụp `system_qty` lúc nhập số đếm; 04 điều chỉnh theo chênh lệch; 05 đếm lại từng dòng; 06 sang REVIEW khi đủ dòng; 07 chặn khi onHand < reserved.
- `## BR-ADJ` — 01 chỉ Manager+; 02 reason code bắt buộc.
- `## BR-ACC` — bảng phân quyền spec 6.7 nguyên văn.
- `## BR-ALR` — 01 bật khi `available < minStock`, không bật lại tới khi hồi phục.

- [ ] **Step 3: Viết mục `## Ví dụ có số`** — 3 kịch bản chạy tay từng bước, mỗi bước ghi onHand/reserved/available:
  1. Hai staff cùng xác nhận phiếu 8 cái trên SKU còn 10 → một thành công, một `INSUFFICIENT_STOCK` (available 2).
  2. Chuyển 20 nồi chiên BN→ĐN, nhận 18 → DISCREPANCY 2 → `WRITE_OFF` CARRIER 1, `FOUND` 1 → CLOSED; tồn ĐN cuối = 19.
  3. Kiểm kê: system 50 lúc đếm, đếm được 47, trước khi duyệt có xuất thêm 5 (onHand 45) → điều chỉnh −3 → onHand 42.

- [ ] **Step 4: Tự kiểm số** — cộng/trừ lại từng kịch bản, xác nhận không bước nào vi phạm I1.

- [ ] **Step 5: Cập nhật cột BR** trong bảng truy vết user-stories (thay `→ Task 6` bằng ID thật).

- [ ] **Step 6: 🧑 Checkpoint (dài nhất tuần 1)** — chủ dự án thử "phá" từng quy tắc bằng tình huống thực tế ("nếu xe giao hàng quay lại trả 1 cái thì sao?"). Tình huống nào chưa có quy tắc → thêm quy tắc hoặc ghi rõ "ngoài phạm vi v1" trong mục `## Câu hỏi đã chốt`.

- [ ] **Step 7:** `./scripts/check-docs.sh` → PASS.

- [ ] **Step 8: Commit + PR + merge** — MERGE-DOC với branch `docs/business-rules`, files `docs/02-domain/business-rules.md docs/01-requirements/user-stories.md`, title `docs: add business rules and invariants`.

---

### Task 7: State machines — `docs/02-domain/state-machines.md` (~3h)

**Files:** Create: `docs/02-domain/state-machines.md`

**Interfaces:**
- Consumes: BR-INB/OUT/TRF/STK, Global Constraints (tên trạng thái).
- Produces: tên action dùng làm endpoint ở Task 11: `confirm, receive, close, cancel, start-picking, complete, ship, resolve-discrepancy, start-counting, submit-count, request-recount, submit-for-review, approve`.

- [ ] **Step 1:** `git switch -c docs/state-machines`

- [ ] **Step 2: Mỗi loại phiếu một mục** gồm Mermaid `stateDiagram-v2` + bảng chuyển trạng thái `Từ | Action | Đến | Ai được làm | Lệnh InventoryApi | Điều kiện`. Nội dung bảng:

**Inbound**
| Từ | Action | Đến | Ai | Inventory | Điều kiện |
|---|---|---|---|---|---|
| DRAFT | confirm | CONFIRMED | Staff+ | — | có ≥ 1 dòng |
| CONFIRMED / RECEIVING | receive | RECEIVING hoặc COMPLETED | Staff+ | `receive` | `received_total ≤ expected` mỗi dòng; đủ hết → COMPLETED |
| RECEIVING | close | COMPLETED | Manager+ | — | lưu `short_qty` |
| DRAFT / CONFIRMED | cancel | CANCELLED | Staff (DRAFT), Manager+ | — | chưa nhận lần nào |

**Outbound**
| Từ | Action | Đến | Ai | Inventory | Điều kiện |
|---|---|---|---|---|---|
| DRAFT | confirm | CONFIRMED | Staff+, Channel | `reserve` | all-or-nothing |
| CONFIRMED | start-picking | PICKING | Staff+ | — | |
| PICKING | complete | COMPLETED | Staff+ | `commit` (+ `release` phần thiếu) | `picked ≤ requested`; thiếu → bắt buộc lý do |
| DRAFT | cancel | CANCELLED | Staff+, Channel | — | |
| CONFIRMED / PICKING | cancel | CANCELLED | Manager+, Channel (đơn của mình) | `release` | |

**Transfer**
| Từ | Action | Đến | Ai | Inventory | Điều kiện |
|---|---|---|---|---|---|
| DRAFT | confirm | CONFIRMED | Staff+ kho nguồn | `reserve` (nguồn) | kho nguồn ≠ kho đích |
| CONFIRMED | ship | IN_TRANSIT | Staff+ kho nguồn | `transferOut` | |
| IN_TRANSIT | receive | RECEIVED hoặc DISCREPANCY | Staff+ kho đích | `transferIn` | `received ≤ shipped` mỗi dòng |
| DISCREPANCY | resolve-discrepancy | DISCREPANCY hoặc CLOSED | Manager+ kho nguồn | `transferIn` nếu `FOUND` | hết dòng chênh lệch → CLOSED |
| DRAFT | cancel | CANCELLED | Staff+ | — | |
| CONFIRMED | cancel | CANCELLED | Manager+ | `release` (nguồn) | |

**Stocktake**
| Từ | Action | Đến | Ai | Inventory | Điều kiện |
|---|---|---|---|---|---|
| DRAFT | start-counting | COUNTING | Manager+ | — | chốt danh sách SKU |
| COUNTING | submit-count | COUNTING | Staff+ | — | chụp `system_qty` của dòng |
| COUNTING | submit-for-review | REVIEW | Staff+ | — | mọi dòng có số đếm |
| REVIEW | request-recount | COUNTING | Manager+ | — | chỉ các dòng được chọn bị xóa số đếm |
| REVIEW | approve | ADJUSTED | Manager+ | `adjust` mỗi dòng lệch | không dòng nào làm onHand < reserved |
| DRAFT / COUNTING / REVIEW | cancel | CANCELLED | Manager+ | — | |

- [ ] **Step 3: Mục `## Hành động không hợp lệ`** — 1 câu: mọi action không có trong bảng → `409 INVALID_STATE_TRANSITION`.

- [ ] **Step 4: Đối chiếu tên trạng thái**
```bash
grep -oE "\b(DRAFT|CONFIRMED|RECEIVING|COMPLETED|CANCELLED|PICKING|IN_TRANSIT|RECEIVED|DISCREPANCY|CLOSED|COUNTING|REVIEW|ADJUSTED)\b" docs/02-domain/state-machines.md | sort -u
```
Expected: đúng 13 tên, không có tên lạ.

- [ ] **Step 5: 🧑 Checkpoint** — chủ dự án đi qua sơ đồ, hỏi "trạng thái nào người dùng có thể bị kẹt mãi?" (ví dụ RECEIVING không ai đóng) và ghi cách xử lý.

- [ ] **Step 6:** `./scripts/check-docs.sh` → PASS.

- [ ] **Step 7: Commit + PR + merge** — MERGE-DOC với branch `docs/state-machines`, files `docs/02-domain/state-machines.md`, title `docs: add order state machines`.

---

### Task 8: Business flows — `docs/02-domain/business-flows.md` (~2h)

**Files:** Create: `docs/02-domain/business-flows.md`

**Interfaces:** Consumes: state machines, business rules.

- [ ] **Step 1:** `git switch -c docs/business-flows`

- [ ] **Step 2: Viết 5 luồng**, mỗi luồng là Mermaid `flowchart TD` có swimlane bằng `subgraph` theo vai trò (Staff, Manager, Hệ thống, Kênh/NCC) và một đoạn kể chuyện tại VietHome:
  1. Nhập hàng từ NCC về Bắc Ninh, giao làm 2 đợt.
  2. Đơn Shopee → channel tạo đơn → kho Bình Dương lấy hàng → xuất (có nhánh short pick).
  3. Chuyển BN → ĐN (nhánh nhận đủ / nhận thiếu → xử lý).
  4. Cycle count hàng giá trị cao ở ĐN (nhánh đếm lại).
  5. Ngày sale 11.11: nhiều đơn cùng tranh 1 SKU (nhánh hết hàng → kênh nhận `INSUFFICIENT_STOCK`).

- [ ] **Step 3: 🧑 Checkpoint** — chủ dự án kể lại luồng 3 không nhìn tài liệu.

- [ ] **Step 4:** `./scripts/check-docs.sh` → PASS.

- [ ] **Step 5: Commit + PR + merge** — MERGE-DOC với branch `docs/business-flows`, files `docs/02-domain/business-flows.md`, title `docs: add business flows`.

---

## TUẦN 2 — Thiết kế giải pháp

### Task 9: Kiến trúc — `docs/03-architecture/README.md` (~4h)

**Files:** Create: `docs/03-architecture/README.md`, `docs/03-architecture/overview.excalidraw`, `docs/03-architecture/overview.png`

**Interfaces:** Consumes: context map, state machines. Produces: tên container `web, api, postgres, keycloak` dùng ở docker-compose Sprint 1.

- [ ] **Step 1:** `git switch -c docs/architecture`

- [ ] **Step 2: C4 Level 1 (System Context)** — Mermaid `flowchart`: người dùng nội bộ (5 vai trò), hệ thống WMS, Keycloak, các kênh bán (client ngoài). Một câu cho mỗi quan hệ.

- [ ] **Step 3: C4 Level 2 (Container)** — Mermaid: `web` (Next.js) → `api` (Spring Boot modular monolith) → `postgres` (6 schema: `catalog, warehouse, inventory, operation, channel, access`); `web` và `api` ↔ `keycloak`; channel client → `api` (client credentials). Ghi giao thức trên mũi tên (HTTPS/JSON, OIDC, JDBC).

- [ ] **Step 4: Sequence 1 — Xác nhận phiếu xuất** (Mermaid `sequenceDiagram`): Staff → web → api(`operation`) → `access` (scope) → `InventoryApi.reserve` → PostgreSQL UPDATE có điều kiện theo `sku_id` tăng dần; nhánh `alt` đủ hàng / dòng 2 thiếu (rollback, trả `INSUFFICIENT_STOCK` liệt kê dòng); event `StockReserved` lưu cùng transaction.

- [ ] **Step 5: Sequence 2 — Chuyển kho ship + receive có chênh lệch**: hai giao dịch tách biệt (ship ngày 1, receive ngày 3), `transferOut`, `transferIn`, trạng thái DISCREPANCY.

- [ ] **Step 6: Sequence 3 — Channel tạo đơn gửi trùng**: lần 1 xử lý và lưu response theo `(principal, Idempotency-Key)`; lần 2 trả response cũ; lần 3 khác payload → `409 IDEMPOTENCY_KEY_REUSED`.

- [ ] **Step 7: Sơ đồ trưng bày** — vẽ lại Container diagram bằng Excalidraw, lưu `.excalidraw` + export `overview.png`, nhúng ảnh ở đầu README.

- [ ] **Step 8: 🧑 Checkpoint** — chủ dự án chỉ ra trên sequence 1 "dòng nào chặn tồn âm" (câu trả lời: điều kiện `on_hand - reserved >= :q` + `CHECK`).

- [ ] **Step 9:** `./scripts/check-docs.sh` → PASS.

- [ ] **Step 10: Commit + PR + merge** — MERGE-DOC với branch `docs/architecture`, files `docs/03-architecture`, title `docs: add C4 and sequence diagrams`.

---

### Task 10: ERD — `docs/04-data/erd.md` (~4h)

**Files:** Create: `docs/04-data/erd.md`

**Interfaces:**
- Consumes: business rules, state machines.
- Produces: tên bảng/cột dùng cho Flyway ở Phase 1 và schema OpenAPI ở Task 11.

- [ ] **Step 1:** `git switch -c docs/erd`

- [ ] **Step 2: Mục `## Quy ước chung`** — UUIDv7 PK `id`; cột audit `created_at, created_by, updated_at, updated_by` (timestamptz UTC, `*_by` = Keycloak `sub`); bảng phiếu có `version bigint`; mã phiếu `{TYPE}-{WH}-{YYMMDD}-{SEQ}`; không FK xuyên schema (ghi chú `-- ref catalog.skus` thay vì FK).

- [ ] **Step 3: Mỗi module một Mermaid `erDiagram` + bảng cột (`cột | kiểu | ràng buộc | ghi chú`)**. Bảng bắt buộc:

- `catalog`: `categories(id, parent_id, name, path)`, `products(id, category_id, name, description, base_uom_code, status)`, `skus(id, product_id, sku_code UNIQUE, barcode UNIQUE, attributes jsonb, min_stock int ≥ 0, status)`, `sku_uom_conversions(sku_id, uom_code, qty_in_base int > 0, PK(sku_id, uom_code))`, `suppliers(id, code UNIQUE, name, contact, address)`, `customers(id, code UNIQUE, name, type DEALER|PROJECT|OTHER, contact, address)`.
- `warehouse`: `warehouses(id, code UNIQUE, name, address, status)`.
- `access`: `user_profiles(sub PK, username, display_name, email)`, `user_warehouse_scopes(sub, warehouse_id, PK(sub, warehouse_id))`.
- `inventory` ⭐:
  - `stock_levels(id, sku_id, warehouse_id, on_hand int, reserved int, version bigint, updated_at, UNIQUE(sku_id, warehouse_id), CHECK(on_hand >= 0), CHECK(reserved >= 0), CHECK(reserved <= on_hand))`
  - `stock_movements(id, sku_id, warehouse_id, movement_type, qty_change int <> 0, on_hand_before, on_hand_after, reference_type, reference_id, reference_line_id, reason_code null, note null, performed_by, created_at)` + ghi chú I5 (REVOKE UPDATE/DELETE + trigger).
  - `reservations(id, sku_id, warehouse_id, qty int > 0, reference_type, reference_id, reference_line_id, status ACTIVE|COMMITTED|RELEASED, created_at, updated_at)`, index `(sku_id, warehouse_id) WHERE status='ACTIVE'`, UNIQUE `(reference_type, reference_line_id)`.
  - `inventory_commands(command_key PK, result jsonb, created_at)` — chặn trùng lệnh nội bộ (luật ranh giới 2).
  - `low_stock_alerts(id, sku_id, warehouse_id, available_at_trigger, min_stock, status OPEN|RESOLVED, opened_at, resolved_at)`.
- `operation`: `inbound_orders(id, code, supplier_id, warehouse_id, status, version, …)` + `inbound_order_lines(id, order_id, sku_id, expected_qty, received_qty, short_qty)` + `inbound_receipts(id, order_id, received_at, received_by)` + `inbound_receipt_lines(receipt_id, line_id, qty)`; `outbound_orders(id, code, warehouse_id, customer_id null, channel_code null, external_ref null, status, cancel_reason null, stale_flagged_at null, version, …)` + `outbound_order_lines(id, order_id, sku_id, requested_qty, picked_qty null, short_reason null)`; `transfer_orders(id, code, from_warehouse_id, to_warehouse_id, status, shipped_at, received_at, version, …)` + `transfer_order_lines(id, order_id, sku_id, qty, shipped_qty, received_qty, discrepancy_qty)` + `transfer_discrepancy_resolutions(id, line_id, resolution WRITE_OFF|FOUND, qty, responsible CARRIER|SOURCE_WAREHOUSE|DESTINATION_WAREHOUSE null, note, resolved_by, resolved_at)`; `stocktakes(id, code, warehouse_id, scope FULL|SKU_LIST, status, version, …)` + `stocktake_lines(id, stocktake_id, sku_id, counted_qty null, system_qty_at_count null, counted_by null, counted_at null, recount_requested bool, adjustment_qty null)`.
- `channel`: `channels(code PK, name, keycloak_client_id UNIQUE)`, `channel_warehouses(channel_code, warehouse_id, PK)`, `channel_orders(id, channel_code, external_order_id, outbound_order_id, UNIQUE(channel_code, external_order_id))`.
- Bảng idempotency HTTP: `idempotency_keys(principal, key, request_hash, status IN_PROGRESS|COMPLETED, response_status, response_body jsonb, created_at, expires_at, PK(principal, key))` — schema đặt ở đâu sẽ chốt trong ADR-0005 (Task 12); ở ERD ghi tạm trong mục `## Hạ tầng dùng chung`.

- [ ] **Step 4: Đối chiếu ERD ↔ quy tắc** — với mỗi BR có dữ liệu (ví dụ BR-INB-04 cần `short_qty`, BR-STK-03 cần `system_qty_at_count`, BR-OUT-04 cần `stale_flagged_at`), xác nhận có cột tương ứng; ghi bảng `BR → bảng.cột` ở cuối file.

- [ ] **Step 5: 🧑 Checkpoint** — đi qua schema `inventory`, chủ dự án giải thích vì sao `stock_movements` có `on_hand_before/after`.

- [ ] **Step 6:** `./scripts/check-docs.sh` → PASS.

- [ ] **Step 7: Commit + PR + merge** — MERGE-DOC với branch `docs/erd`, files `docs/04-data/erd.md`, title `docs: add ERD per module`.

---

### Task 11: Quy ước API & OpenAPI — `docs/05-api/` (~5h)

**Files:**
- Create: `docs/05-api/conventions.md`, `docs/05-api/openapi.yaml`
- Modify: `docs/01-requirements/user-stories.md` (cột Endpoint bảng truy vết)

**Interfaces:**
- Consumes: state machines (tên action), ERD (tên trường), business rules (mã lỗi).
- Produces: contract mà Phase 1 sinh code (openapi-generator `interfaceOnly`, orval).

- [ ] **Step 1:** `git switch -c docs/api-contract`

- [ ] **Step 2: `conventions.md`** với các mục: versioning `/api/v1`; JSON camelCase; thời gian ISO-8601 UTC; action là sub-resource `POST /{resource}/{id}/{action}`; phân trang `page` (0-based), `size` (mặc định 20, tối đa 100), `sort=field,asc|desc`, response `Page<T>` `{items, page, size, totalItems, totalPages}`; lỗi RFC 9457 + `code` + `traceId`; bảng mã lỗi ↔ HTTP status (`INSUFFICIENT_STOCK` 422, `INVALID_STATE_TRANSITION` 409, `WAREHOUSE_SCOPE_DENIED` 403, `VERSION_CONFLICT` 412, `IDEMPOTENCY_KEY_REUSED` 409, `IDEMPOTENCY_IN_PROGRESS` 409, validation 400); `Idempotency-Key` bắt buộc cho: mọi action của phiếu làm đổi tồn (`confirm, receive, complete, cancel, ship, resolve-discrepancy, approve`), `POST /inventory/adjustments`, mọi `POST /channel/**`; `If-Match`/`ETag` cho `PUT` phiếu; header `X-Correlation-Id`.

- [ ] **Step 3: `openapi.yaml` — phần đầy đủ** (OpenAPI 3.1, `security: bearerAuth` JWT; mỗi operation có `operationId`, request/response schema, response 4xx dùng `ProblemDetail`):

Inventory (tag `inventory`):
```
GET  /api/v1/inventory/stock-levels          ?skuId&warehouseId&belowMinStock&page&size&sort -> Page<StockLevel>
GET  /api/v1/inventory/movements             ?skuId&warehouseId&from&to&page&size        -> Page<StockMovement>
GET  /api/v1/inventory/in-transit            ?fromWarehouseId&toWarehouseId               -> InTransitSummary[]
POST /api/v1/inventory/adjustments           (Idempotency-Key) AdjustmentRequest          -> StockMovement
GET  /api/v1/inventory/reservations          ?warehouseId&status&stale&page&size          -> Page<Reservation>
GET  /api/v1/inventory/low-stock-alerts      ?warehouseId&status                          -> Page<LowStockAlert>
```
Outbound (tag `outbound`):
```
POST /api/v1/outbound-orders                         CreateOutboundOrderRequest -> OutboundOrder (201)
GET  /api/v1/outbound-orders                         ?warehouseId&status&stale&page&size&sort -> Page<OutboundOrderSummary>
GET  /api/v1/outbound-orders/{id}                    -> OutboundOrder (+ ETag)
PUT  /api/v1/outbound-orders/{id}                    (If-Match) UpdateOutboundOrderRequest -> OutboundOrder
POST /api/v1/outbound-orders/{id}/confirm            (Idempotency-Key) -> OutboundOrder | 422 InsufficientStockProblem
POST /api/v1/outbound-orders/{id}/start-picking      -> OutboundOrder
POST /api/v1/outbound-orders/{id}/complete           (Idempotency-Key) CompleteOutboundRequest{lines[{lineId,pickedQty,shortReason?}]} -> OutboundOrder
POST /api/v1/outbound-orders/{id}/cancel             (Idempotency-Key) CancelRequest{reason} -> OutboundOrder
POST /api/v1/outbound-orders/bulk-cancel             (Idempotency-Key) BulkCancelRequest{orderIds[], reason} -> BulkResult
```
Channel (tag `channel`, security `clientCredentials`):
```
POST /api/v1/channel/orders                  (Idempotency-Key) ChannelOrderRequest{externalOrderId, warehouseCode, lines[{skuCode, qty}]} -> ChannelOrder (201) | 422 InsufficientStockProblem
GET  /api/v1/channel/orders/{id}             -> ChannelOrder
POST /api/v1/channel/orders/{id}/cancel      (Idempotency-Key) CancelRequest -> ChannelOrder
GET  /api/v1/channel/availability            ?skuCode&warehouseCode -> Availability{skuCode, warehouseCode, available}
```
Schemas bắt buộc: `ProblemDetail{type,title,status,detail,instance,code,traceId}`, `InsufficientStockProblem` (allOf ProblemDetail + `lines[{lineId, skuId, requested, available}]`), `Page*`, `StockLevel{skuId, warehouseId, onHand, reserved, available, minStock}`, `StockMovement`, `Reservation`, `OutboundOrder` (status enum đúng 5 giá trị), `MovementType` enum, `ReasonCode` enum.

- [ ] **Step 4: `openapi.yaml` — phần khung** (path + method + `summary` + `operationId` + response 200/201 trỏ schema tối thiểu `{id}` và `ProblemDetail` cho 4xx): catalog (`/categories`, `/products`, `/skus`, `/skus/by-barcode/{barcode}`, `/skus/{id}/uom-conversions`, `/suppliers`, `/customers`), `/warehouses`, access (`/users/{sub}/warehouse-scopes`), inbound (`/inbound-orders` + `confirm, receive, close, cancel`), transfer (`/transfer-orders` + `confirm, ship, receive, resolve-discrepancy, cancel`), stocktake (`/stocktakes` + `start-counting, lines/{lineId}/count, submit-for-review, request-recount, approve, cancel`). Mỗi operation khung có `x-status: skeleton`.

- [ ] **Step 5: Lint**
```bash
npx --yes @redocly/cli lint docs/05-api/openapi.yaml
```
Expected: `Woohoo! Your API description is valid.` (warnings `no-unused-components` chấp nhận được).

- [ ] **Step 6: Đối chiếu enum ↔ state machines**
```bash
for s in DRAFT CONFIRMED PICKING COMPLETED CANCELLED; do grep -q "$s" docs/05-api/openapi.yaml || echo "THIẾU $s"; done
grep -oE "start-picking|confirm|complete|cancel" docs/05-api/openapi.yaml | sort -u
```
Expected: không dòng `THIẾU`; 4 action đều có.

- [ ] **Step 7: Cập nhật cột Endpoint** trong bảng truy vết user-stories (thay `→ Task 11` bằng `METHOD path`).

- [ ] **Step 8: 🧑 Checkpoint** — xem OpenAPI bằng `npx --yes @redocly/cli preview-docs docs/05-api/openapi.yaml`, chủ dự án thử "đóng vai FE": màn hình danh sách phiếu xuất cần gì thì API đã có chưa.

- [ ] **Step 9:** `./scripts/check-docs.sh` → PASS.

- [ ] **Step 10: Commit + PR + merge** — MERGE-DOC với branch `docs/api-contract`, files `docs/05-api docs/01-requirements/user-stories.md`, title `docs: add API conventions and OpenAPI contract`.

---

### Task 12: ADR 0001–0009 — `docs/adr/` (~3h)

**Files:** Create: `docs/adr/README.md`, `docs/adr/0000-template.md`, 9 file ADR dưới đây. Modify (nếu ADR-0005 chọn khác spec): `docs/superpowers/specs/2026-09-30-phase-0-design.md`, `docs/04-data/erd.md`.

- [ ] **Step 1:** `git switch -c docs/adr`

- [ ] **Step 2: Template** `docs/adr/0000-template.md`:
```markdown
# NNNN — Tiêu đề

- **Trạng thái:** Proposed | Accepted | Superseded by NNNN
- **Ngày:** YYYY-MM-DD

## Bối cảnh
## Các phương án đã cân nhắc
## Quyết định
## Hệ quả (tốt / xấu / phải làm thêm)
```

- [ ] **Step 3: Viết 9 ADR** (trạng thái `Accepted`, ngày merge), mỗi ADR ≥ 2 phương án, lấy lập luận đã chốt khi brainstorm:

| File | Quyết định | Phương án bị loại |
|---|---|---|
| `0001-modular-monolith.md` | Modular monolith v1, tách `inventory` ở v2 (strangler) | Microservice từ đầu; monolith không chia module |
| `0002-keycloak-oidc.md` | Keycloak OIDC; RBAC + scope kho trong app | Tự viết Spring Security + JWT |
| `0003-inventory-api-boundary.md` | 5 luật ranh giới | Cho `operation` sửa bảng tồn trực tiếp |
| `0004-concurrency-strategy.md` | UPDATE có điều kiện mặc định; optimistic & pessimistic là chiến lược đo so sánh | Chỉ optimistic; Redis lock (v1 không có Redis) |
| `0005-idempotency-storage.md` | Lưu trên PostgreSQL; **bảng `idempotency_keys` đặt trong schema `platform` dùng chung** vì idempotency HTTP áp dụng cho cả `operation`, `inventory`, `channel` | Đặt trong schema `inventory` (như spec mục 5 ghi); Redis |
| `0006-contract-first-openapi.md` | OpenAPI là nguồn; sinh interface BE + client FE | Code-first (springdoc sinh spec) |
| `0007-modulith-events-outbox.md` | Spring Modulith events + Event Publication Registry | Gọi trực tiếp; Kafka ở v1 |
| `0008-monorepo-trunk-based.md` | Monorepo, trunk-based, squash merge | Multi-repo; GitFlow |
| `0009-uuidv7-primary-keys.md` | UUIDv7 (PostgreSQL 18 `uuidv7()`) | bigserial; UUIDv4 |

- [ ] **Step 4: Đồng bộ ADR-0005** — sửa spec mục 5 (dòng `inventory` bỏ `idempotency_keys`, thêm ghi chú "bảng `platform.idempotency_keys`, xem ADR-0005") và ERD mục `## Hạ tầng dùng chung` ghi schema `platform`.
```bash
grep -n "idempotency_keys" docs/superpowers/specs/2026-09-30-phase-0-design.md docs/04-data/erd.md
```
Expected: mọi dòng nhắc tới đều thống nhất `platform`.

- [ ] **Step 5: `docs/adr/README.md`** — bảng mục lục 9 ADR (số, tiêu đề, trạng thái, link).

- [ ] **Step 6: 🧑 Checkpoint** — chủ dự án tập trả lời phỏng vấn bằng ADR-0001 và 0004 (nói trong 1 phút mỗi cái).

- [ ] **Step 7:** `./scripts/check-docs.sh` → PASS.

- [ ] **Step 8: Commit + PR + merge** — MERGE-DOC với branch `docs/adr`, files `docs/adr docs/superpowers/specs/2026-09-30-phase-0-design.md docs/04-data/erd.md`, title `docs: add ADR 0001-0009`.

---

### Task 13: Yêu cầu phi chức năng — `docs/01-requirements/nfr.md` (~1.5h)

**Files:** Create: `docs/01-requirements/nfr.md`

- [ ] **Step 1:** `git switch -c docs/nfr`

- [ ] **Step 2: Bảng `ID | Yêu cầu | Đo bằng gì | Khi nào kiểm (phase)`**, tối thiểu:
  - NFR-01 Tính đúng: 0 lần vi phạm I1–I5 — test concurrency (Phase 1), job đối soát + alert (Phase 4).
  - NFR-02 Tải thường: 1.000 phiếu xuất/ngày; tải sale: 10.000 phiếu trong 4 giờ, đỉnh ~50 confirm/giây trên một SKU nóng — k6 (Phase 6).
  - NFR-03 Độ trễ: p95 `confirm` < 300 ms, p95 đọc tồn < 200 ms ở tải thường — k6 + Prometheus.
  - NFR-04 Khả dụng mục tiêu (SLO sơ bộ): 99.5%/tháng cho API — Phase 4.
  - NFR-05 Audit: mọi thay đổi tồn truy được người + lý do + phiếu — I2 + test.
  - NFR-06 Bảo mật: mọi endpoint yêu cầu JWT; scope kho kiểm ở server; secret không nằm trong repo — test + gitleaks (Phase 7).
  - NFR-07 Quan sát: mọi request có `X-Correlation-Id`, log JSON — Phase 2.
  - NFR-08 Khả năng tách: `ApplicationModules.verify()` xanh — CI Phase 1.
  - NFR-09 Trình duyệt: Chrome/Edge/Safari bản mới; giao diện dùng được ở màn 1366×768 (máy kho) — Playwright.

- [ ] **Step 3: 🧑 Checkpoint** — chủ dự án chỉnh các con số NFR-02/03 nếu muốn thử thách hơn.

- [ ] **Step 4:** `./scripts/check-docs.sh` → PASS.

- [ ] **Step 5: Commit + PR + merge** — MERGE-DOC với branch `docs/nfr`, files `docs/01-requirements/nfr.md`, title `docs: add non-functional requirements`.

---

### Task 14: Quy trình & GitHub Project — `docs/process/workflow.md` + `.github/ISSUE_TEMPLATE/` (~2h)

**Files:**
- Create: `docs/process/workflow.md`, `docs/process/retros/.gitkeep`, `.github/ISSUE_TEMPLATE/story.yml`, `task.yml`, `bug.yml`, `spike.yml`, `config.yml`

**Interfaces:** Produces: labels, milestones, project board mà Task 15 dùng.

- [ ] **Step 1:** `git switch -c chore/process`

- [ ] **Step 2: `workflow.md`** chép và cụ thể hóa spec mục 8: board 5 cột; Iteration 2 tuần bắt đầu thứ 7; tên branch `feat|fix|chore|docs/<issue>-<slug>`; PR `Closes #N`; squash; Conventional Commits; quy trình tự review hôm sau + AI review; bảng nghi thức sprint; DoR; DoD; mẫu daily comment:
```markdown
**Daily YYYY-MM-DD** — ✅ xong: … · ▶️ tiếp: … · ⛔ vướng: …
```
và mẫu retro `docs/process/retros/sprint-N.md`: `## Giữ` `## Bỏ` `## Thử` `## Ước lượng vs thực tế`. Thêm mục `## Ngoại lệ bootstrap`: 3 commit đầu (`fe71b3c`, `f36abc0`, `352cf5c`) vào thẳng `main` trước khi có quy trình; từ PR `docs/repo-bootstrap` trở đi mọi thay đổi qua PR, được chặn bởi git hook + branch protection.

- [ ] **Step 3: Issue template `story.yml`**
```yaml
name: User story
description: Một user story có acceptance criteria
title: "US-XXX-NN: "
labels: ["type:story"]
body:
  - type: textarea
    id: story
    attributes:
      label: Story
      value: "**Là** …, **tôi muốn** … **để** …"
    validations: { required: true }
  - type: textarea
    id: ac
    attributes:
      label: Acceptance criteria (Given/When/Then)
    validations: { required: true }
  - type: input
    id: refs
    attributes:
      label: BR / Endpoint / Bảng liên quan
  - type: checkboxes
    id: dor
    attributes:
      label: Definition of Ready
      options:
        - label: AC đủ, có ít nhất 1 trường hợp lỗi
        - label: Endpoint đã có trong openapi.yaml
        - label: Bảng/cột đã có trong erd.md
        - label: Vừa một sprint
```
`task.yml`, `bug.yml` (các trường: mô tả, bước tái hiện, kết quả mong đợi, thực tế), `spike.yml` (câu hỏi, giới hạn thời gian, kết quả mong đợi) theo cùng cấu trúc; `config.yml`: `blank_issues_enabled: false`.

- [ ] **Step 4: Labels & milestones** (🧑 xác nhận trước khi chạy — tạo dữ liệu trên repo public)
```bash
R=dwchwang/Smart-Warehouse-Management-System
for l in "type:story:1d76db" "type:task:5319e7" "type:bug:d73a4a" "type:chore:cccccc" "type:spike:fbca04" \
         "priority:P0:b60205" "priority:P1:d93f0b" "priority:P2:fef2c0" \
         "module:catalog:0e8a16" "module:warehouse:0e8a16" "module:inventory:0e8a16" "module:operation:0e8a16" \
         "module:channel:0e8a16" "module:access:0e8a16" "module:web:0e8a16" "module:platform:0e8a16"; do
  name="${l%:*}"; color="${l##*:}"
  gh label create "$name" --color "$color" -R "$R" --force
done
for m in "Phase 0 — Design" "Phase 1 — Local product" "Phase 2 — Cloud-native" "Phase 3 — K8s & CI/CD" \
         "Phase 4 — Observability" "Phase 5 — IaC" "Phase 6 — Scaling & Resilience" "Phase 7 — DevSecOps" "Phase 8 — Showcase"; do
  gh api -X POST "repos/$R/milestones" -f title="$m" >/dev/null
done
gh label list -R "$R" | wc -l     # Expected: ≥ 16
gh api "repos/$R/milestones" --jq 'length'   # Expected: 9
```

- [ ] **Step 5: Project board**
```bash
gh auth refresh -s project      # nếu token chưa có scope project
gh project create --owner dwchwang --title "Smart WMS"
```
Sau đó trên giao diện web của Project: thêm trường `Status` với 5 giá trị `Backlog, Ready, In Progress, In Review, Done`; thêm trường **Iteration** (2 tuần, bắt đầu thứ 7 sau khi Phase 0 xong); thêm trường number `Estimate (h)`; link project vào repo. (Các bước này `gh` chưa hỗ trợ đầy đủ — làm tay, chụp màn hình lưu cho portfolio.)

- [ ] **Step 6:** `./scripts/check-docs.sh` → PASS.

- [ ] **Step 7: Commit + PR + merge** — MERGE-DOC với branch `chore/process`, files `docs/process .github/ISSUE_TEMPLATE`, title `chore: add team workflow and issue templates`.

---

### Task 15: Backlog Phase 1 & nghiệm thu Phase 0 (~3h)

**Files:**
- Create: `docs/process/backlog-phase-1.md`
- Modify: `README.md`

**Interfaces:** Consumes: user stories (ID), ERD, OpenAPI, labels/milestones/project từ Task 14.

- [ ] **Step 1:** `git switch -c docs/backlog-phase-1`

- [ ] **Step 2: `backlog-phase-1.md`** — 6 sprint đúng spec mục 10. Mỗi sprint: mục tiêu, demo, danh sách item `[ID] tiêu đề — ước lượng giờ`. Tổng mỗi sprint ≤ 30h.
  - S1 (task kỹ thuật, ID `T-S1-NN`): monorepo `apps/api` + `apps/web`; docker-compose `web, api, postgres, keycloak`; Keycloak realm-as-code (5 role, client `wms-web`, `wms-api`, `channel-demo`); đăng nhập end-to-end; Flyway 6 schema + `platform`; Problem Details + `X-Correlation-Id`; sinh code OpenAPI 2 phía + check drift; `ApplicationModules.verify()`; CI build/test/lint; ADR chọn UI kit (shadcn/ui vs Ant Design) + chốt phiên bản Java/Spring Boot/PG/Next.js.
  - S2: US-ACC-*, US-CAT-*, US-WH-01.
  - S3: US-INV-01, 02, 03; US-INB-*; story kỹ thuật `T-S3-01` 3 chiến lược concurrency + test concurrency (100 luồng cùng reserve); `T-S3-02` idempotency HTTP + command key.
  - S4: US-OUT-*, US-CH-*.
  - S5: US-TRF-*, US-ADJ-01, US-ALR-01.
  - S6: US-STK-*, US-ALR-02 (job đối soát), Playwright cho 5 kịch bản tiêu chí thành công (Task 2), tag `v1.0.0`, video demo.

- [ ] **Step 3: Tạo issue cho S1 và S2** (🧑 xác nhận trước) — mỗi item một issue, milestone `Phase 1 — Local product`, label `type:*`, `module:*`, `priority:*`, body theo `story.yml` (dán AC từ user-stories), thêm vào project với Status `Ready`. Ví dụ:
```bash
R=dwchwang/Smart-Warehouse-Management-System
gh issue create -R "$R" --title "US-ACC-02: Admin gán scope kho cho user" \
  --label "type:story,module:access,priority:P0" --milestone "Phase 1 — Local product" \
  --body-file /tmp/us-acc-02.md
gh project item-add <PROJECT_NUMBER> --owner dwchwang --url <ISSUE_URL>
```
(`<PROJECT_NUMBER>` lấy bằng `gh project list --owner dwchwang`.) Item S3–S6 tạo issue với Status `Backlog`, chỉ cần tiêu đề + link tới story trong `user-stories.md`.

- [ ] **Step 4: Kiểm tra nghiệm thu Phase 0**
```bash
# 1. Đủ tài liệu
for f in docs/00-vision-scope.md docs/01-requirements/user-stories.md docs/01-requirements/nfr.md \
         docs/02-domain/{glossary,context-map,business-rules,state-machines,business-flows}.md \
         docs/03-architecture/README.md docs/04-data/erd.md docs/05-api/conventions.md docs/05-api/openapi.yaml \
         docs/process/workflow.md docs/process/backlog-phase-1.md; do test -f "$f" || echo "THIẾU $f"; done
ls docs/adr/000[1-9]-*.md | wc -l          # Expected: 9
# 2. Không còn ký hiệu chờ điền trong bảng truy vết
grep -n "→ Task" docs/01-requirements/user-stories.md   # Expected: không có kết quả
# 3. Không lọt v2 vào yêu cầu v1
grep -rniE "kafka|redis|websocket" docs/01-requirements docs/02-domain | grep -viE "v2|ngoài phạm vi"   # Expected: rỗng
# 4. Mọi tài liệu hợp lệ
./scripts/check-docs.sh
# 5. Issue S1–S2 ở trạng thái Ready
gh issue list -R dwchwang/Smart-Warehouse-Management-System --milestone "Phase 1 — Local product" --state open | wc -l
```
Expected: không dòng `THIẾU`; 9 ADR; mục 2, 3 rỗng; `ALL DOC CHECKS PASSED`; số issue ≥ số item S1 + S2.

- [ ] **Step 5: README** — thêm mục `## Tài liệu` liệt kê và link mọi tài liệu Phase 0, mục `## Trạng thái` "Phase 0 ✅ — Phase 1 bắt đầu Sprint 1".

- [ ] **Step 6: 🧑 Checkpoint — Sprint 1 Planning** — chủ dự án kéo issue S1 vào Iteration 1, ước lượng giờ từng issue.

- [ ] **Step 7: Commit + PR + merge + tag**
```bash
git add docs/process/backlog-phase-1.md README.md
git commit -m "docs: add Phase 1 backlog and close Phase 0"
git push -u origin docs/backlog-phase-1
gh pr create --title "docs: add Phase 1 backlog and close Phase 0" --fill
gh pr checks --watch && gh pr merge --squash --delete-branch
git switch main && git pull
git tag -a phase-0-done -m "Phase 0: design complete" && git push origin phase-0-done
```

---

## Ước lượng tổng

| Tuần | Task | Giờ |
|---|---|---|
| 1 | 1–8 | 3 + 2 + 2 + 3 + 5 + 4 + 3 + 2 = 24 |
| 2 | 9–15 | 4 + 4 + 5 + 3 + 1.5 + 2 + 3 = 22.5 |
| | **Tổng** | **~46.5h** (vượt ngân sách 42h khoảng 10%: dùng cuối tuần thứ 3 nếu cần, ghi vào retro Phase 0) |
