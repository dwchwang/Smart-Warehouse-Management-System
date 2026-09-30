# Smart Warehouse Management System (WMS)

## Tài liệu thiết kế & lộ trình triển khai dự án

> Tài liệu này là "kim chỉ nam" để bạn xây dựng dự án từ con số 0 đến production.
> Đọc từ trên xuống, làm theo từng phase. Mỗi phần đều có gợi ý sơ đồ cần vẽ.
> **Nguyên tắc vàng:** làm cho nghiệp vụ lõi _đúng_ trước, rồi mới "DevOps hóa". Đừng làm ngược.

---

## Mục lục

1. [Tổng quan & mục tiêu](#1-tổng-quan--mục-tiêu)
2. [Đi sâu nghiệp vụ](#2-đi-sâu-nghiệp-vụ)
3. [Các actor & phân quyền](#3-các-actor--phân-quyền)
4. [Mô hình domain & khái niệm cốt lõi](#4-mô-hình-domain--khái-niệm-cốt-lõi)
5. [Bài toán kỹ thuật khó (điểm ăn tiền)](#5-bài-toán-kỹ-thuật-khó-điểm-ăn-tiền)
6. [Kiến trúc hệ thống & microservices](#6-kiến-trúc-hệ-thống--microservices)
7. [Thiết kế cơ sở dữ liệu](#7-thiết-kế-cơ-sở-dữ-liệu)
8. [Thiết kế API](#8-thiết-kế-api)
9. [Các luồng nghiệp vụ quan trọng (sequence)](#9-các-luồng-nghiệp-vụ-quan-trọng)
10. [Công nghệ & tech stack](#10-công-nghệ--tech-stack)
11. [Lộ trình triển khai chi tiết theo phase](#11-lộ-trình-triển-khai-chi-tiết-theo-phase)
12. [Các sơ đồ nên vẽ](#12-các-sơ-đồ-nên-vẽ)
13. [Tiêu chí "done" & cách kể chuyện trong CV](#13-tiêu-chí-done--cách-kể-chuyện-trong-cv)

---

## 1. Tổng quan & mục tiêu

### 1.1. Mô tả một dòng

Hệ thống quản lý kho hàng đa điểm (multi-warehouse) cho doanh nghiệp bán lẻ/phân phối, xử lý nhập – xuất – chuyển – kiểm kê tồn kho theo thời gian thực, đảm bảo **tính nhất quán tuyệt đối** của dữ liệu tồn kho trong môi trường nhiều người thao tác đồng thời.

### 1.2. Mục tiêu kép của dự án

- **Mục tiêu sản phẩm:** một hệ thống WMS chạy được, giải quyết nghiệp vụ thật của doanh nghiệp.
- **Mục tiêu nghề nghiệp (quan trọng hơn với bạn):** chứng minh năng lực **làm chủ toàn bộ vòng đời** — từ thiết kế hệ thống, code BE/FE, đến containerize, CI/CD, K8s, observability, IaC, autoscaling, security. Đây là hồ sơ DevOps Engineer middle đúng nghĩa.

### 1.3. Vì sao đề tài này phù hợp

- Nghiệp vụ **rõ ràng, ai cũng hiểu**, mọi công ty có hàng hóa đều cần.
- Có **ràng buộc kỹ thuật khó** (tồn kho không được sai/âm/nhân đôi) → tạo _lý do chính đáng_ để phô diễn distributed transaction, concurrency control, observability, chaos engineering. Phần DevOps không còn "làm cho có".
- Dễ kiểm soát hơn ví điện tử, ít bão hòa hơn e-commerce.

---

## 2. Đi sâu nghiệp vụ

### 2.1. Bối cảnh doanh nghiệp

Một công ty phân phối có nhiều kho ở nhiều địa điểm. Hàng nhập từ nhà cung cấp, lưu trong kho theo vị trí cụ thể, rồi xuất đi khi có đơn hàng (từ e-commerce, đại lý, hoặc bán buôn). Đôi khi cần chuyển hàng giữa các kho để cân bằng tồn. Định kỳ phải kiểm kê để đối soát tồn thực tế với hệ thống.

Bài toán cốt lõi: **luôn biết chính xác đang có bao nhiêu hàng, ở đâu, và mọi thay đổi đều truy vết được.**

### 2.2. Các nhóm nghiệp vụ

#### A. Quản lý danh mục (Master Data)

- **Sản phẩm & SKU:** một sản phẩm (Product) có thể có nhiều biến thể (SKU) — ví dụ áo thun có SKU theo size/màu. SKU là đơn vị quản lý tồn kho thực tế.
- **Danh mục (Category):** phân loại sản phẩm dạng cây (cha–con).
- **Đơn vị tính (UoM - Unit of Measure):** cái, hộp, thùng… và quy đổi giữa chúng (1 thùng = 24 hộp).
- **Barcode/QR:** mỗi SKU gắn mã để quét nhanh khi nhập/xuất.
- **Nhà cung cấp (Supplier)** và **Khách hàng (Customer/Partner)**.

#### B. Quản lý kho & vị trí (Warehouse & Location)

- **Kho (Warehouse):** nhiều kho, mỗi kho có thông tin địa điểm, người quản lý.
- **Vị trí lưu trữ (Location/Bin):** cấu trúc phân cấp trong kho — Zone (khu) → Rack (kệ) → Bin (ô). Giúp biết chính xác hàng nằm đâu. _Có thể làm đơn giản ở v1 (chỉ tới cấp kho) rồi mở rộng._

#### C. Nghiệp vụ lõi — nơi tập trung độ khó

**1. Nhập kho (Inbound / Goods Receipt)**

- Tạo phiếu nhập (dựa trên đơn đặt hàng nhà cung cấp — Purchase Order, hoặc nhập tay).
- Nhận hàng thực tế → kiểm đếm số lượng → xác nhận.
- Khi xác nhận: **tăng tồn kho** của SKU tại vị trí tương ứng + ghi một bản ghi biến động (stock movement).
- Trạng thái phiếu: `DRAFT → CONFIRMED → RECEIVING → COMPLETED / CANCELLED`.

**2. Xuất kho (Outbound / Goods Issue)**

- Tạo phiếu xuất (dựa trên đơn hàng khách, hoặc xuất tay).
- **Picking:** chọn hàng từ vị trí để lấy.
- Khi xác nhận: **giảm tồn kho** + ghi biến động.
- **Ràng buộc sống còn:** không được xuất quá số lượng đang có (không để tồn âm), kể cả khi nhiều người xuất cùng lúc.
- Trạng thái: `DRAFT → CONFIRMED → PICKING → COMPLETED / CANCELLED`.

**3. Chuyển kho (Stock Transfer)**

- Chuyển hàng từ kho A sang kho B.
- Về bản chất = **xuất ở A + nhập ở B**, phải đảm bảo _cả hai cùng thành công hoặc cùng thất bại_.
- Đây là **bài toán distributed transaction điển hình** → dùng Saga pattern.
- Có trạng thái trung gian: hàng đang trên đường (in-transit).
- Trạng thái: `DRAFT → CONFIRMED → IN_TRANSIT → RECEIVED / CANCELLED`.

**4. Kiểm kê (Stocktake / Inventory Count)**

- Đếm tồn thực tế trong kho, so với số liệu hệ thống.
- Ghi nhận chênh lệch (thừa/thiếu) → tạo bút toán điều chỉnh (adjustment) + lý do.
- Trạng thái: `DRAFT → COUNTING → REVIEW → ADJUSTED / CANCELLED`.

**5. Điều chỉnh tồn (Stock Adjustment)**

- Điều chỉnh thủ công (hàng hỏng, mất, phát hiện sai lệch) — luôn kèm **lý do** và **người thực hiện** để audit.

#### D. Tồn kho realtime & lịch sử biến động

- **Tồn kho hiện tại (Stock Level):** số lượng khả dụng của mỗi SKU tại mỗi kho/vị trí, luôn phản ánh đúng.
- **Tồn khả dụng vs tồn đã giữ chỗ (Available vs Reserved):** khi tạo phiếu xuất nhưng chưa hoàn tất, số lượng đó nên được "giữ chỗ" (reserve) để người khác không xuất mất. Đây là chi tiết nghiệp vụ nâng cao rất đáng làm.
  - `available = on_hand - reserved`
- **Lịch sử biến động (Stock Movement / Ledger):** _mọi_ thay đổi tồn kho đều sinh một bản ghi bất biến (immutable) ghi rõ: SKU, kho, loại biến động (nhập/xuất/chuyển/điều chỉnh), số lượng (+/-), tồn trước, tồn sau, tham chiếu phiếu, người thực hiện, thời gian. Đây chính là "sổ cái" của kho — cho phép truy vết và tái dựng lại tồn kho tại bất kỳ thời điểm nào.

#### E. Nghiệp vụ hỗ trợ

- **Cảnh báo tồn:** tồn dưới mức tối thiểu (reorder point) → nhắc đặt hàng; tồn vượt tối đa; hàng cận hạn sử dụng (nếu quản lý lô/hạn dùng).
- **Quản lý lô & hạn dùng (Batch/Lot & Expiry)** _(tùy chọn nâng cao):_ với hàng có hạn, quản lý theo lô, xuất theo FEFO (First Expired First Out).
- **Báo cáo:** giá trị tồn kho, tốc độ luân chuyển (inventory turnover), top SKU bán chạy/tồn đọng, biến động theo thời gian, hàng sắp hết.

### 2.3. Vòng đời một SKU trong kho (bức tranh tổng)

```
Nhà cung cấp → [Nhập kho] → Tồn tại vị trí trong kho A
                                   │
                     ┌─────────────┼──────────────┐
                     ▼             ▼              ▼
              [Xuất cho đơn]  [Chuyển kho B]  [Kiểm kê/Điều chỉnh]
                     │             │              │
                     ▼             ▼              ▼
              Giảm tồn        Tồn A giảm,     Tồn khớp thực tế
                             Tồn B tăng
        ── Mọi bước đều ghi Stock Movement (truy vết được) ──
```

---

## 3. Các actor & phân quyền

| Actor                               | Vai trò                      | Quyền chính                                              |
| ----------------------------------- | ---------------------------- | -------------------------------------------------------- |
| **Admin hệ thống**                  | Quản trị toàn hệ thống       | Quản lý user, cấu hình, tất cả các kho                   |
| **Quản lý kho (Warehouse Manager)** | Phụ trách một/nhiều kho      | Duyệt phiếu, xem báo cáo, quản lý nhân viên kho đó       |
| **Nhân viên kho (Staff)**           | Thao tác hằng ngày           | Tạo/thực hiện phiếu nhập/xuất/kiểm kê trong kho được gán |
| **Kế toán/Xem báo cáo (Viewer)**    | Chỉ đọc                      | Xem tồn kho, báo cáo, không chỉnh sửa                    |
| **Hệ thống ngoài (System/API)**     | E-commerce, ERP đẩy đơn sang | Gọi API để tạo phiếu xuất/trừ kho                        |

**Nguyên tắc phân quyền:** kết hợp **RBAC** (theo vai trò) **+ scope theo kho** (một nhân viên chỉ thao tác được trên kho mình được gán). Đây là chi tiết làm nghiệp vụ "thật" hơn hẳn CRUD thường.

---

## 4. Mô hình domain & khái niệm cốt lõi

### 4.1. Các thực thể chính (Entity)

- **Product** — sản phẩm gốc.
- **SKU** — biến thể quản lý tồn (thuộc về Product).
- **Category** — danh mục (cây).
- **UoM** — đơn vị tính.
- **Warehouse** — kho.
- **Location** — vị trí trong kho (zone/rack/bin).
- **Supplier / Customer** — đối tác.
- **StockLevel** — tồn hiện tại (SKU × Warehouse × Location).
- **StockMovement** — bản ghi biến động (bất biến).
- **InboundOrder / OutboundOrder / TransferOrder / StocktakeOrder** — các loại phiếu.
- **User / Role** — người dùng & phân quyền.

### 4.2. Các khái niệm cần nắm chắc (viết ra để hiểu, đừng bỏ qua)

- **On-hand quantity:** số lượng thực có trong kho.
- **Reserved quantity:** số đã cam kết cho phiếu xuất chưa hoàn tất.
- **Available quantity:** `on_hand - reserved` — số thực sự có thể bán/xuất tiếp.
- **Stock Movement:** đơn vị nhỏ nhất, bất biến, ghi lại một lần thay đổi tồn. Tồn kho hiện tại = tổng hợp các movement (hoặc lưu snapshot + movement).
- **Idempotency key:** khóa duy nhất cho một thao tác, để nếu client gửi lại (do timeout/retry) thì hệ thống không thực hiện hai lần.

---

## 5. Bài toán kỹ thuật khó (điểm ăn tiền)

Đây là phần khiến CV của bạn khác biệt. Hãy làm kỹ và hiểu sâu để trả lời phỏng vấn.

### 5.1. Concurrency control — chống tồn âm khi xuất đồng thời

**Vấn đề:** hai nhân viên cùng xuất SKU X đang có 10 cái. Cả hai cùng đọc "còn 10", cùng xuất 8 → tồn thành -6. Sai.

**Giải pháp (làm cả hai để so sánh, nói được trong phỏng vấn):**

- **Optimistic Locking:** thêm cột `version` vào StockLevel. Khi update kèm điều kiện version cũ; nếu ai đó đã đổi trước → update fail → retry. Hợp khi ít xung đột.
- **Pessimistic Locking:** `SELECT ... FOR UPDATE` khóa dòng tồn trước khi trừ. Hợp khi xung đột nhiều.
- **Kết hợp Redis distributed lock** cho hot SKU (hàng bán chạy).
- **Ràng buộc DB:** thêm `CHECK (quantity >= 0)` như lưới an toàn cuối cùng.

### 5.2. Idempotency — chống tạo trùng / trừ trùng

- Mỗi request nghiệp vụ (tạo phiếu, xác nhận xuất) mang một **Idempotency-Key** (client sinh, ví dụ UUID).
- Server lưu key đã xử lý + kết quả. Gặp lại key đó → trả kết quả cũ, không làm lại.
- Cực kỳ quan trọng với retry qua mạng và message queue.

### 5.3. Saga pattern — chuyển kho (distributed transaction)

Chuyển kho đụng tới ≥ 2 kho (có thể 2 service/2 DB). Không dùng được transaction ACID duy nhất → dùng **Saga**:

- **Choreography** (các service tự phản ứng qua event) hoặc **Orchestration** (một orchestrator điều phối). Với nghiệp vụ chuyển kho, **orchestration dễ hiểu và dễ debug hơn** — khuyến nghị.
- Các bước: `Trừ tồn kho A` → `Đánh dấu in-transit` → `Cộng tồn kho B`. Nếu bước sau lỗi → chạy **compensating transaction** (hoàn tác bước trước: cộng lại kho A).

### 5.4. Event-driven & audit trail

- Mỗi biến động phát một **event** (StockMovedEvent) lên Kafka → các service khác (Reporting, Notification) tiêu thụ.
- **Exactly-once / at-least-once + idempotent consumer:** đảm bảo báo cáo không đếm trùng.
- StockMovement là **audit trail** sẵn có — thể hiện tư duy hệ thống nghiêm túc.

### 5.5. Reserve/Release tồn (nâng cao, rất đáng làm)

- Khi tạo phiếu xuất: **reserve** số lượng (tăng reserved).
- Khi hoàn tất: chuyển reserved → giảm on-hand thật.
- Khi hủy phiếu: **release** (giảm reserved).
- Cần cơ chế **timeout tự release** nếu phiếu treo quá lâu (dùng scheduled job / TTL).

---

## 6. Kiến trúc hệ thống & microservices

### 6.1. Danh sách service (dự kiến)

| Service                  | Trách nhiệm                                            | Ghi chú                 |
| ------------------------ | ------------------------------------------------------ | ----------------------- |
| **API Gateway**          | Điểm vào duy nhất, routing, rate limit, xác thực token | Spring Cloud Gateway    |
| **Auth Service**         | Đăng nhập, JWT, RBAC + scope theo kho                  |                         |
| **Catalog Service**      | Product, SKU, Category, UoM, Barcode, Supplier         | Master data             |
| **Warehouse Service**    | Kho, vị trí lưu trữ, cấu hình                          |                         |
| **Inventory Service**    | ⭐ Tồn kho, concurrency control, StockMovement         | **Trái tim hệ thống**   |
| **Operation Service**    | Nghiệp vụ nhập/xuất/chuyển/kiểm kê, điều phối Saga     | Có thể tách nhỏ hơn sau |
| **Reporting Service**    | Báo cáo, đọc từ read-model riêng (CQRS)                | Tiêu thụ event          |
| **Notification Service** | Cảnh báo tồn, thông báo realtime (WebSocket/email)     | Tiêu thụ event          |

> **Lời khuyên thực tế:** ở Phase 1 đừng tách quá nhỏ. Có thể gộp Catalog + Warehouse, gộp Operation vào chung, miễn là **Inventory tách riêng** vì nó là lõi. Tách dần khi cần. Microservice quá sớm = tự làm khổ mình.

### 6.2. Giao tiếp giữa các service

- **Đồng bộ:** REST (ngoài) + gRPC (nội bộ, hiệu năng cao) — hoặc REST hết ở v1 cho đơn giản.
- **Bất đồng bộ:** Kafka/RabbitMQ cho event (biến động tồn, saga, notification).
- **Pattern:** Database-per-service, API Gateway, CQRS (cho Reporting), Saga (cho transfer), Event-driven.

### 6.3. Sơ đồ kiến trúc mức cao (mô tả để bạn vẽ)

```
[Web FE - React] ──► [API Gateway] ──► ┌─ Auth Service
                                       ├─ Catalog Service ──► PostgreSQL
                                       ├─ Warehouse Service ─► PostgreSQL
                                       ├─ Inventory Service ─► PostgreSQL + Redis
                                       └─ Operation Service ─► PostgreSQL
                                                │
                                          (publish events)
                                                ▼
                                          [Kafka / RabbitMQ]
                                             │        │
                                             ▼        ▼
                                    Reporting Svc   Notification Svc
                                    (read-model)    (WebSocket/email)
```

---

## 7. Thiết kế cơ sở dữ liệu

> Mỗi service một database riêng. Dưới đây là các bảng chính theo service. Kiểu dữ liệu để tham khảo, tinh chỉnh khi làm.

### 7.1. Catalog Service

```
categories(id, name, parent_id, path, created_at)
products(id, name, description, category_id, base_uom_id, status, created_at)
skus(id, product_id, sku_code, barcode, attributes_json, uom_id, min_stock, max_stock, created_at)
uoms(id, name, ratio_to_base)          -- đơn vị & quy đổi
suppliers(id, name, contact, address)
```

### 7.2. Warehouse Service

```
warehouses(id, code, name, address, manager_id, status)
locations(id, warehouse_id, zone, rack, bin, code, type)   -- vị trí lưu trữ
```

### 7.3. Inventory Service ⭐ (quan trọng nhất)

```
stock_levels(
  id, sku_id, warehouse_id, location_id,
  on_hand      NUMERIC NOT NULL DEFAULT 0,
  reserved     NUMERIC NOT NULL DEFAULT 0,
  version      BIGINT  NOT NULL DEFAULT 0,      -- optimistic locking
  updated_at,
  UNIQUE(sku_id, warehouse_id, location_id),
  CHECK (on_hand >= 0),
  CHECK (reserved >= 0),
  CHECK (reserved <= on_hand)
)

stock_movements(                                -- bất biến, không UPDATE/DELETE
  id, sku_id, warehouse_id, location_id,
  movement_type,          -- INBOUND / OUTBOUND / TRANSFER_OUT / TRANSFER_IN / ADJUSTMENT
  quantity_change,        -- +/-
  qty_before, qty_after,
  reference_type,         -- loại phiếu
  reference_id,           -- id phiếu
  reason,                 -- cho adjustment
  performed_by, created_at
)

idempotency_keys(key, request_hash, response_json, created_at)   -- chống trùng
```

### 7.4. Operation Service (các phiếu)

```
inbound_orders(id, code, supplier_id, warehouse_id, status, created_by, created_at)
inbound_order_lines(id, order_id, sku_id, expected_qty, received_qty)

outbound_orders(id, code, customer_ref, warehouse_id, status, created_by, created_at)
outbound_order_lines(id, order_id, sku_id, requested_qty, picked_qty)

transfer_orders(id, code, from_warehouse_id, to_warehouse_id, status, saga_state, created_at)
transfer_order_lines(id, order_id, sku_id, quantity)

stocktake_orders(id, code, warehouse_id, status, created_at)
stocktake_lines(id, order_id, sku_id, system_qty, counted_qty, diff)
```

### 7.5. Auth Service

```
users(id, username, email, password_hash, status, created_at)
roles(id, name)                          -- ADMIN, MANAGER, STAFF, VIEWER
user_roles(user_id, role_id)
user_warehouse_scope(user_id, warehouse_id)   -- giới hạn theo kho
```

### 7.6. Reporting Service

- Dùng **read-model** riêng (bảng tổng hợp / materialized view), cập nhật từ event. Ví dụ: `daily_stock_snapshot`, `turnover_by_sku`. Không query trực tiếp DB nghiệp vụ.

> **Gợi ý sơ đồ:** vẽ **ERD** cho từng service (không phải một ERD khổng lồ), nhấn mạnh quan hệ trong Inventory.

---

## 8. Thiết kế API

> REST-style, versioned (`/api/v1/...`). Dưới đây là các endpoint chính (rút gọn).

### Catalog

```
POST   /api/v1/products
GET    /api/v1/products?category=&search=&page=
POST   /api/v1/skus
GET    /api/v1/skus/{id}
GET    /api/v1/skus/barcode/{barcode}
```

### Warehouse

```
POST   /api/v1/warehouses
GET    /api/v1/warehouses
POST   /api/v1/warehouses/{id}/locations
```

### Inventory ⭐

```
GET    /api/v1/inventory?sku=&warehouse=          -- xem tồn (on_hand/reserved/available)
GET    /api/v1/inventory/{skuId}/movements        -- lịch sử biến động
POST   /api/v1/inventory/reserve                  -- giữ chỗ (Idempotency-Key header)
POST   /api/v1/inventory/release                  -- nhả giữ chỗ
POST   /api/v1/inventory/adjust                   -- điều chỉnh (kèm reason)
```

### Operations

```
POST   /api/v1/inbound-orders            + /{id}/confirm  + /{id}/receive
POST   /api/v1/outbound-orders           + /{id}/confirm  + /{id}/pick  + /{id}/complete
POST   /api/v1/transfer-orders           + /{id}/confirm  + /{id}/receive
POST   /api/v1/stocktakes                + /{id}/count    + /{id}/adjust
```

### Quy ước quan trọng

- Header `Idempotency-Key` bắt buộc cho các thao tác thay đổi tồn.
- Chuẩn hóa response lỗi (mã lỗi nghiệp vụ: `INSUFFICIENT_STOCK`, `VERSION_CONFLICT`…).
- Phân trang, filter, sort thống nhất.

---

## 9. Các luồng nghiệp vụ quan trọng

### 9.1. Xuất kho (có reserve) — mô tả để vẽ sequence

```
User → Gateway → Operation: tạo outbound order (DRAFT)
Operation → Inventory: reserve(sku, qty)  [Idempotency-Key]
  Inventory: kiểm tra available >= qty?
     - Không đủ → trả INSUFFICIENT_STOCK → Operation báo lỗi
     - Đủ → tăng reserved (optimistic/pessimistic lock) → OK
Operation: order = CONFIRMED
... (picking) ...
User → Operation: complete
Operation → Inventory: commit(sku, qty)
  Inventory: on_hand -= qty; reserved -= qty; ghi StockMovement(OUTBOUND)
  Inventory: publish StockMovedEvent → Kafka
Reporting/Notification tiêu thụ event
Operation: order = COMPLETED
```

### 9.2. Chuyển kho (Saga orchestration) — mô tả để vẽ

```
User → Operation: tạo transfer A→B (DRAFT) → confirm
Saga bắt đầu:
  Step 1: Inventory.deduct(A, sku, qty)      -- trừ kho A
          thành công? → tiếp ; lỗi? → hủy saga
  Step 2: đánh dấu IN_TRANSIT + StockMovement(TRANSFER_OUT)
  Step 3: Inventory.add(B, sku, qty)         -- cộng kho B
          thành công? → COMPLETED + StockMovement(TRANSFER_IN)
          lỗi? → COMPENSATE: Inventory.add(A, sku, qty) [hoàn tác] → CANCELLED
Mỗi bước ghi saga_state để phục hồi nếu service chết giữa chừng.
```

### 9.3. Nhập kho — ngắn gọn

```
Tạo inbound (DRAFT) → confirm → nhận hàng thực tế (received_qty)
→ Inventory.increase(sku, qty) + StockMovement(INBOUND) → COMPLETED → publish event
```

### 9.4. Kiểm kê

```
Tạo stocktake → đếm thực tế (counted_qty) → so system_qty → diff
→ tạo Adjustment cho từng dòng lệch (kèm reason) → Inventory.adjust → ADJUSTED
```

> **Sơ đồ nên vẽ ở phần này:** sequence diagram cho 9.1 và 9.2 (quan trọng nhất), state diagram cho vòng đời mỗi loại phiếu.

---

## 10. Công nghệ & tech stack

### Backend (ưu tiên Java)

- **Java 21, Spring Boot 3, Spring Cloud** (Gateway, OpenFeign/gRPC, Config).
- Spring Data JPA + Hibernate; Flyway/Liquibase cho migration.
- (Tùy chọn) viết **1 service bằng Go** — ví dụ Notification hoặc một phần Inventory — để chứng minh polyglot. Không bắt buộc, cân nhắc theo thời gian.

### Data & Messaging

- **PostgreSQL** (database-per-service).
- **Redis** (cache tồn nóng, distributed lock).
- **Kafka** (khuyến nghị, vì hợp event-driven + học được nhiều) hoặc RabbitMQ (đơn giản hơn).
- (Tùy chọn) Elasticsearch cho search sản phẩm/log.

### Frontend

- **React + TypeScript**, Ant Design hoặc MUI.
- Dashboard tồn kho **realtime (WebSocket)**, màn quản lý phiếu, báo cáo (Recharts), quản trị.

### DevOps & Cloud (trọng tâm hồ sơ)

- **Container:** Docker (multi-stage build, image nhỏ gọn).
- **Orchestration:** Kubernetes (EKS/GKE, hoặc k3s/kind để tiết kiệm chi phí lúc học), **Helm**.
- **IaC:** **Terraform** (provision hạ tầng cloud), Ansible (config nếu cần VM).
- **CI/CD:** GitHub Actions (hoặc GitLab CI) + **ArgoCD** (GitOps), multi-environment (dev/staging/prod).
- **Observability:** **Prometheus + Grafana** (metrics), **Loki** (logs), **Tempo + OpenTelemetry** (tracing), **Alertmanager** (alert theo SLO).
- **Scaling & Resilience:** **HPA** (autoscale), **k6** (load test), **Chaos Mesh** (chaos engineering).
- **Security (DevSecOps):** **Vault** (secret), **Trivy** (scan image), **Cosign** (sign image), SBOM, secret scanning trong CI.
- **Cloud:** chọn **1** (AWS _hoặc_ GCP) và đi sâu. AWS phổ biến hơn ở thị trường tuyển dụng.

> **Cảnh báo chi phí:** cloud thật tốn tiền. Chiến lược tiết kiệm: dev toàn bộ trên **kind/k3s local**, chỉ lên cloud thật ở giai đoạn cuối để chụp screenshot/demo, rồi **tear down** bằng Terraform. Tận dụng free tier.

---

## 11. Lộ trình triển khai chi tiết theo phase

> Tổng thời gian tham khảo: **4–6 tháng** làm ngoài giờ. Đừng vội. Làm chắc từng phase.
> Sau **mỗi phase** đều commit, viết README, chụp ảnh/ghi lại kết quả để đưa vào CV dần.

### 🟢 PHASE 0 — Chuẩn bị & thiết kế (1–2 tuần)

Mục tiêu: hiểu rõ mình sắp xây gì trước khi gõ dòng code đầu tiên.

- [ ] Đọc lại tài liệu này, chốt phạm vi **v1** (làm gì, _không_ làm gì).
- [ ] Viết **danh sách user story** (VD: "Là nhân viên kho, tôi muốn tạo phiếu xuất để…").
- [ ] Vẽ **sơ đồ nghiệp vụ** (business flow) cho nhập/xuất/chuyển/kiểm kê.
- [ ] Vẽ **kiến trúc mức cao** & chốt danh sách service cho v1 (nên gộp bớt).
- [ ] Vẽ **ERD** từng service.
- [ ] Thiết kế **API contract** (dùng OpenAPI/Swagger).
- [ ] Set up repo (mono-repo hoặc multi-repo), quy ước branch, commit convention.
- **Output:** bộ tài liệu thiết kế + sơ đồ. _Chưa cần code._

### 🟢 PHASE 1 — Sản phẩm chạy local (4–6 tuần) — **quan trọng nhất**

Mục tiêu: nghiệp vụ lõi chạy đúng trên máy, bằng docker-compose.

- [ ] Dựng skeleton các service (Spring Boot), kết nối PostgreSQL, migration bằng Flyway.
- [ ] **Auth Service:** đăng nhập, JWT, RBAC + scope kho.
- [ ] **Catalog + Warehouse:** CRUD master data.
- [ ] **Inventory Service (làm kỹ nhất):** stock_levels, stock_movements, API xem tồn, **concurrency control** (optimistic + pessimistic), **idempotency**.
- [ ] **Operation Service:** nhập, xuất (có reserve), kiểm kê. Sau đó **chuyển kho với Saga**.
- [ ] Tích hợp **Kafka**: publish StockMovedEvent.
- [ ] **Reporting** (đọc event → read-model) + **Notification** (cảnh báo tồn thấp).
- [ ] **Frontend:** các màn hình chính + dashboard tồn realtime (WebSocket).
- [ ] **docker-compose** chạy toàn bộ (services + PG + Redis + Kafka).
- [ ] **Viết test:** unit cho logic tồn kho, **integration test cho concurrency** (mô phỏng nhiều request đồng thời — bằng chứng vàng cho phỏng vấn).
- **Output:** hệ thống chạy được end-to-end trên local. Quay video demo.

### 🟢 PHASE 2 — Cloud-native hóa (1–2 tuần)

Mục tiêu: chuẩn hóa app để chạy tốt trên K8s.

- [ ] Áp dụng **12-factor**: config qua env, không hardcode.
- [ ] **Health check** (liveness/readiness), **graceful shutdown**.
- [ ] Externalize config & secret (chuẩn bị cho Vault/ConfigMap).
- [ ] Structured logging (JSON), correlation ID xuyên suốt request.
- [ ] Dockerfile multi-stage tối ưu cho từng service.
- **Output:** app sẵn sàng cho K8s.

### 🟢 PHASE 3 — Kubernetes + CI/CD (2–3 tuần)

Mục tiêu: deploy tự động lên K8s theo GitOps.

- [ ] Viết **Helm chart** cho từng service (values theo môi trường).
- [ ] Dựng cluster (kind/k3s local trước, cloud sau).
- [ ] **CI:** build → test → build image → push registry (GitHub Actions).
- [ ] **CD/GitOps:** **ArgoCD** đồng bộ từ Git → cluster.
- [ ] Multi-environment: **dev / staging / prod** (namespace hoặc cluster tách).
- [ ] Chiến lược deploy: rolling update; **canary cho Inventory** (service nhạy cảm).
- **Output:** push code → tự động deploy. Chứng minh GitOps.

### 🟢 PHASE 4 — Observability (2 tuần)

Mục tiêu: nhìn thấy mọi thứ đang xảy ra trong hệ thống.

- [ ] **Metrics:** Prometheus + Grafana. Dashboard: đơn/phút, latency, tồn kho, lỗi.
- [ ] **Logs:** Loki tập trung, query theo correlation ID.
- [ ] **Tracing:** OpenTelemetry + Tempo — **trace một lệnh chuyển kho** đi qua các service.
- [ ] **Alerting:** Alertmanager theo **SLO** (VD: p99 latency, error rate, tồn âm bất thường).
- **Output:** bộ dashboard + alert. Screenshot cực "ăn ảnh" cho CV.

### 🟢 PHASE 5 — Infrastructure as Code (1–2 tuần)

Mục tiêu: toàn bộ hạ tầng tạo bằng code.

- [ ] **Terraform:** provision cluster, database, network, registry trên cloud.
- [ ] Module hóa, **remote state** (S3 + DynamoDB lock hoặc GCS).
- [ ] (Tùy chọn) **Ansible** nếu có VM cần config.
- [ ] (Nâng cao) **Policy-as-code** (OPA) kiểm tra tài nguyên.
- **Output:** `terraform apply` dựng cả hệ thống; `terraform destroy` dọn sạch (tiết kiệm tiền).

### 🟢 PHASE 6 — Scaling & Resilience (1–2 tuần)

Mục tiêu: chứng minh hệ thống chịu tải & chịu lỗi.

- [ ] **HPA:** autoscale Inventory/Operation theo CPU hoặc custom metric.
- [ ] **Load test (k6):** mô phỏng cao điểm, đo throughput/latency, có số liệu.
- [ ] **Chaos Engineering (Chaos Mesh):** **kill Inventory giữa lúc chuyển kho** → chứng minh tồn kho _không sai, không mất, không nhân đôi_. Đây là màn trình diễn đắt giá nhất.
- [ ] Circuit breaker, retry, timeout (Resilience4j).
- **Output:** báo cáo load test + chaos test. Bằng chứng năng lực SRE.

### 🟢 PHASE 7 — DevSecOps (1 tuần)

Mục tiêu: bảo mật xuyên suốt pipeline.

- [ ] **Trivy:** scan image trong CI, chặn nếu có lỗ hổng nghiêm trọng.
- [ ] **Cosign:** ký image, verify khi deploy.
- [ ] **Vault:** quản lý secret (DB password, JWT key), rotation.
- [ ] **SBOM:** sinh danh sách thành phần phần mềm.
- [ ] Secret scanning (gitleaks) trong CI.
- **Output:** pipeline bảo mật hoàn chỉnh.

### 🟢 PHASE 8 — Hoàn thiện & trình bày (1 tuần)

- [ ] **README** xịn: kiến trúc, cách chạy, screenshot, video demo.
- [ ] **Architecture Decision Records (ADR):** ghi lại _vì sao_ chọn X thay Y — cực kỳ ấn tượng.
- [ ] Sơ đồ tổng hợp đẹp (dùng draw.io/Excalidraw).
- [ ] Viết một **blog post** hoặc trang portfolio kể lại hành trình.
- [ ] Chuẩn bị câu chuyện phỏng vấn (xem phần 13).

---

## 12. Các sơ đồ nên vẽ

Vẽ dần theo phase, dùng **draw.io / Excalidraw / Mermaid**. Danh sách:

1. **Business Flow Diagram** — luồng nhập/xuất/chuyển/kiểm kê (Phase 0).
2. **Use Case Diagram** — actor & chức năng (Phase 0).
3. **High-level Architecture** — services, gateway, DB, message broker (Phase 0).
4. **ERD** — cho từng service, nhấn mạnh Inventory (Phase 0).
5. **Sequence Diagram** — xuất kho có reserve; chuyển kho Saga (Phase 1).
6. **State Diagram** — vòng đời mỗi loại phiếu (Phase 1).
7. **Deployment/Infra Diagram** — K8s, namespace, cloud resources (Phase 3–5).
8. **Observability Diagram** — luồng metrics/logs/traces (Phase 4).
9. **CI/CD Pipeline Diagram** — từ commit tới production (Phase 3).

---

## 13. Tiêu chí "done" & cách kể chuyện trong CV

### 13.1. Định nghĩa "done" cho v1

- Nghiệp vụ lõi (nhập/xuất/chuyển/kiểm kê) chạy đúng, **có test chứng minh không tồn âm khi concurrency**.
- Deploy tự động lên K8s qua GitOps, multi-environment.
- Có observability đầy đủ (metrics/logs/traces/alert).
- Hạ tầng tạo bằng Terraform.
- Có bằng chứng scaling (load test) & resilience (chaos test).
- Pipeline có security scan + signing.
- README + sơ đồ + video demo.

### 13.2. Cách viết vào CV (gợi ý)

> **Smart WMS — Hệ thống quản lý kho microservice (cá nhân, full-stack + DevOps)**
>
> - Thiết kế & xây dựng hệ WMS gồm N microservice bằng **Java/Spring Cloud**, giải bài toán **nhất quán tồn kho ở concurrency cao** (optimistic/pessimistic locking, idempotency, Saga cho chuyển kho).
> - Tự tay đưa lên **production trên cloud (AWS/GCP)**: Docker, **Kubernetes + Helm**, **CI/CD + ArgoCD (GitOps)**, multi-environment.
> - Triển khai **observability** đầy đủ (Prometheus/Grafana/Loki/Tempo + OpenTelemetry) và **autoscaling (HPA)**; chứng minh resilience bằng **chaos engineering** (kill service giữa giao dịch, tồn kho vẫn chính xác).
> - **IaC** với Terraform; **DevSecOps** với Trivy/Cosign/Vault/SBOM.

### 13.3. Câu hỏi phỏng vấn nên chuẩn bị trả lời

- Làm sao đảm bảo tồn kho không âm khi nhiều người xuất cùng lúc? (so sánh optimistic vs pessimistic)
- Chuyển kho lỡ chết giữa chừng thì sao? (Saga + compensation + saga_state phục hồi)
- Vì sao chọn Kafka? Xử lý message trùng thế nào? (idempotent consumer)
- Vì sao GitOps? ArgoCD giải quyết vấn đề gì so với CI/CD truyền thống?
- Alert của bạn dựa trên SLO nào? Vì sao?
- Nếu Inventory quá tải, hệ thống phản ứng ra sao? (HPA + circuit breaker)

---

## Lời kết

Bí quyết thành công của dự án này: **đừng cố làm mọi thứ cùng lúc.** Làm nghiệp vụ lõi cho _đúng và có test_ ở Phase 1, rồi bồi đắp DevOps lên trên từng lớp một. Sau mỗi phase, dừng lại ghi chép, chụp ảnh, cập nhật CV. Sau 4–6 tháng bạn sẽ có một project mà _rất ít ứng viên middle nào có được_: một sản phẩm nghiệp vụ thật, tự code, tự đưa lên production, tự vận hành — đúng bức tranh một DevOps Engineer làm chủ toàn bộ vòng đời phần mềm.

Chúc bạn code vui và kiên trì. 🚀
