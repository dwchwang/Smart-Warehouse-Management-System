# Glossary — Thuật ngữ dùng chung

> Một khái niệm = **một tên tiếng Việt** (dùng trong tài liệu và giao diện) + **một định danh tiếng Anh** (dùng trong code, DB, API).
> Viết tài liệu hay code mà phải dùng từ khác với bảng này → sửa bảng này trước (qua PR), đừng tự đặt tên mới.

## Hàng hóa & danh mục

| Thuật ngữ (VN) | Định danh (EN) | Định nghĩa | Ví dụ tại VietHome |
|---|---|---|---|
| Sản phẩm | `Product` | Mặt hàng gốc, chưa tách theo biến thể; không dùng để đếm tồn | "Nồi chiên không dầu VH-5L" |
| Biến thể / SKU | `Sku` (`skuCode`) | Biến thể cụ thể của một sản phẩm; **đơn vị quản lý tồn** | `NCK-5L-DEN` — nồi chiên 5L màu đen |
| Mã vạch | `barcode` | Mã in trên bao bì để quét; mỗi SKU một mã, không trùng | `8936012345678` |
| Danh mục | `Category` | Nhóm phân loại dạng cây (cha – con) | Nhà bếp → Thiết bị điện → Nồi chiên |
| Đơn vị cơ sở | `baseUom` | Đơn vị nhỏ nhất dùng để lưu tồn; mọi số lượng trong hệ thống quy về đơn vị này | "cái" |
| Quy đổi đơn vị | `SkuUomConversion` (`uomCode`, `qtyInBase`) | Một đơn vị lớn bằng bao nhiêu đơn vị cơ sở, **khai báo riêng cho từng SKU** | Bình giữ nhiệt: 1 thùng = 24 cái; nồi chiên: 1 thùng = 2 cái |
| Tồn tối thiểu | `minStock` | Ngưỡng tồn khả dụng của một SKU, xuống dưới thì cảnh báo | Nồi chiên 5L tại BN: 30 |
| Nhà cung cấp | `Supplier` | Bên bán hàng cho VietHome | Hãng sản xuất nồi chiên |
| Khách hàng / Đại lý | `Customer` (`type`: `DEALER`, `PROJECT`, `OTHER`) | Bên mua hàng không qua sàn | Đại lý điện máy ở Hải Phòng |

## Kho & tồn

| Thuật ngữ (VN) | Định danh (EN) | Định nghĩa | Ví dụ tại VietHome |
|---|---|---|---|
| Kho | `Warehouse` (`code`) | Địa điểm chứa hàng; tồn được quản lý tới cấp kho | `BN` Bắc Ninh, `DN` Đà Nẵng, `BD` Bình Dương |
| Tồn thực có | `onHand` | Số lượng đang thực sự nằm trong kho | 10 cái |
| Tồn đã giữ chỗ | `reserved` | Phần tồn thực có đã hứa cho phiếu chưa hoàn tất | 8 cái đang giữ cho một đơn Shopee |
| Tồn khả dụng | `available` | `onHand − reserved`; số còn có thể nhận thêm đơn | 2 cái |
| Hàng đang đi đường | `inTransit` | Hàng đã rời kho nguồn nhưng kho đích chưa nhận; **không thuộc tồn của kho nào** | 20 nồi chiên trên xe BN → ĐN |
| Mức tồn | `StockLevel` | Một dòng tồn cho một cặp (SKU, kho), chứa `onHand` và `reserved` | (NCK-5L-DEN, BN): onHand 10, reserved 8 |
| Biến động tồn | `StockMovement` | Bản ghi **bất biến** của một lần `onHand` thay đổi: ai, khi nào, bao nhiêu, vì phiếu nào | +50 nhập từ phiếu `IN-BN-261004-0001` |
| Sổ cái tồn | ledger | Toàn bộ biến động tồn theo thời gian; cộng lại phải ra đúng tồn thực có | — |
| Loại biến động | `movementType` (`INBOUND`, `OUTBOUND`, `TRANSFER_OUT`, `TRANSFER_IN`, `ADJUSTMENT`) | Nguyên nhân của biến động | `TRANSFER_OUT` khi xe rời BN |
| Giữ chỗ | `Reservation` (`status`: `ACTIVE`, `COMMITTED`, `RELEASED`) | Bản ghi giữ một số lượng cho **một dòng phiếu**; tổng giữ chỗ đang hiệu lực = `reserved` | Giữ 8 cái cho dòng 1 của phiếu xuất |
| Tham chiếu phiếu | `referenceType`, `referenceId` | Phiếu gây ra biến động / giữ chỗ | `OUTBOUND`, id phiếu xuất |

## Phiếu & nghiệp vụ

| Thuật ngữ (VN) | Định danh (EN) | Định nghĩa | Ví dụ tại VietHome |
|---|---|---|---|
| Phiếu nhập | `InboundOrder` | Phiếu nhận hàng từ nhà cung cấp vào kho | `IN-BN-261004-0001` |
| Phiếu xuất | `OutboundOrder` | Phiếu lấy hàng khỏi kho giao cho khách / đại lý / đơn sàn | `OUT-BD-261004-0123` |
| Phiếu chuyển kho | `TransferOrder` | Phiếu đưa hàng từ kho nguồn sang kho đích | `TRF-BN-261004-0002` (BN → ĐN) |
| Phiếu kiểm kê | `Stocktake` | Phiếu đếm thực tế để so với hệ thống | `STK-DN-261004-0001` |
| Điều chỉnh tồn | `Adjustment` | Thay đổi tồn thủ công không qua phiếu nhập/xuất/chuyển, **luôn kèm lý do** | −2 vì hàng vỡ |
| Mã lý do | `reasonCode` (`DAMAGED`, `LOST`, `FOUND`, `COUNT_CORRECTION`, `OTHER`) | Lý do bắt buộc của điều chỉnh | `DAMAGED` |
| Nhận thiếu (nhập) | `shortQty` | Phần nhà cung cấp giao thiếu so với dự kiến khi phiếu nhập được đóng | Dự kiến 100, nhận 96 → thiếu 4 |
| Xuất thiếu | short pick | Lấy được ít hơn số yêu cầu khi hoàn tất phiếu xuất; phải ghi lý do | Yêu cầu 5, chỉ tìm được 4 |
| Chênh lệch chuyển kho | transit discrepancy | Phần đã xuất từ kho nguồn nhưng kho đích không nhận được | Xuất 20, nhận 18 → chênh 2 |
| Xử lý chênh lệch | `resolution` (`WRITE_OFF`, `FOUND`) | `WRITE_OFF`: ghi nhận mất + bên chịu trách nhiệm; `FOUND`: tìm thấy, nhận bổ sung vào kho đích | 1 cái `WRITE_OFF` do nhà vận chuyển |
| Bên chịu trách nhiệm | `responsible` (`CARRIER`, `SOURCE_WAREHOUSE`, `DESTINATION_WAREHOUSE`) | Ai chịu phần hàng mất khi chuyển kho | `CARRIER` |
| Kiểm kê vòng | cycle count | Kiểm kê một phần (hoặc cả kho) **mà không dừng nhập/xuất** | Đếm 30 SKU nồi chiên ở ĐN mỗi tuần |
| Đếm mù | blind count | Người đếm không nhìn thấy số trên hệ thống | — |
| Số hệ thống lúc đếm | `systemQtyAtCount` | Tồn thực có được chụp lại đúng lúc nhập số đếm của một dòng | 50 |
| Giữ chỗ quá hạn | stale reservation | Phiếu xuất đã giữ chỗ nhưng chưa bắt đầu lấy hàng quá 24h (đơn sàn) / 48h (đơn tay) | Đơn đại lý giữ 3 ngày chưa lấy |
| Trạng thái phiếu | `status` | Vị trí của phiếu trong vòng đời; danh sách đầy đủ ở `state-machines.md` | `CONFIRMED` |

## Kênh bán & phân quyền

| Thuật ngữ (VN) | Định danh (EN) | Định nghĩa | Ví dụ tại VietHome |
|---|---|---|---|
| Kênh bán | `Channel` (`code`) | Nguồn đơn bên ngoài gọi API của hệ thống | `shopee`, `tiktok` |
| Client kênh | channel client | Tài khoản máy (Keycloak client) mà một kênh dùng để gọi API | `channel-shopee` |
| Mã đơn bên ngoài | `externalOrderId` | Mã đơn trên hệ thống của kênh; mỗi kênh không trùng | Mã đơn Shopee |
| Vai trò | role (`ADMIN`, `MANAGER`, `STAFF`, `VIEWER`) | Nhóm quyền của một người dùng | `STAFF` |
| Phạm vi kho | warehouse scope | Danh sách kho một người dùng (hoặc client kênh) được thao tác | Staff A: chỉ `DN` |

## Kỹ thuật cần hiểu nghĩa nghiệp vụ

| Thuật ngữ (VN) | Định danh (EN) | Định nghĩa | Ví dụ tại VietHome |
|---|---|---|---|
| Khóa chống trùng | `Idempotency-Key` (header HTTP) | Mã do bên gọi tạo cho mỗi yêu cầu; gửi lại cùng mã thì nhận lại kết quả cũ, không làm hai lần | Sàn gửi lại đơn do mạng chập chờn |
| Khóa lệnh tồn | command key | Mã nội bộ cho mỗi lệnh thay đổi tồn, dạng `{REFERENCE_TYPE}:{referenceId}:{ACTION}`, chống thực hiện một lệnh hai lần | `OUTBOUND:<id>:RESERVE` |
| Cảnh báo tồn thấp | low-stock alert | Cảnh báo bật khi tồn khả dụng < tồn tối thiểu; chỉ bật lại sau khi đã hồi phục trên ngưỡng | Nồi chiên BN còn 25 < 30 |
| Đối soát | reconciliation | Việc định kỳ kiểm tra tồn có khớp sổ cái và giữ chỗ không; lệch thì cảnh báo, không tự sửa | Chạy hằng đêm |
| Module | module | Một phần của ứng dụng sở hữu riêng dữ liệu và nghiệp vụ của nó (giải thích ở `context-map.md`) | `inventory` |
| Sự kiện nghiệp vụ | domain event | Thông báo "một việc đã xảy ra" để phần khác phản ứng | `StockCommitted` |
