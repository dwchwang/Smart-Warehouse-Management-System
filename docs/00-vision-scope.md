# Vision & phạm vi — Smart WMS v1

> Tài liệu này trả lời: **hệ thống phục vụ ai, giải quyết nỗi đau nào, v1 làm gì và không làm gì, thế nào là thành công.**
> Mọi tài liệu sau (user story, quy tắc nghiệp vụ, API) đều phải truy được về một nỗi đau `P1`–`P5` ở đây.

## Bối cảnh

**VietHome Distribution** (doanh nghiệp giả định) phân phối **đồ gia dụng & thiết bị nhà bếp**: nồi chiên không dầu, máy xay, bộ nồi, bình giữ nhiệt, đồ nhựa gia dụng.

| Khía cạnh | Hiện trạng |
|---|---|
| Nguồn hàng | ~40 nhà cung cấp / hãng |
| Kênh bán | Sàn TMĐT (Shopee, TikTok Shop) ~60% số đơn, đơn lẻ nhỏ · ~200 đại lý, đặt theo thùng · Bán buôn dự án (khách sạn, chuỗi), đơn lớn, không đều |
| Kho | **Bắc Ninh** (kho tổng miền Bắc, lớn nhất) · **Đà Nẵng** (nhỏ) · **Bình Dương** (miền Nam) |
| Danh mục | ~350 sản phẩm, ~1.500 SKU (biến thể theo màu / dung tích) |
| Nhân sự | ~25 nhân viên kho, 3 quản lý kho, 2 kế toán, 1 admin IT |
| Tải | ~1.000 phiếu xuất/ngày; ngày sale đôi (9.9, 11.11, 12.12) gấp ~10 lần, dồn vào vài giờ |
| Công cụ hiện tại | Excel + phần mềm bán hàng rời rạc, không nối với nhau |

## Nỗi đau

| ID | Nỗi đau | Hậu quả kinh doanh | Phần hệ thống giải quyết |
|---|---|---|---|
| P1 | **Bán vượt tồn** ngày sale: nhận đơn rồi mới biết hết hàng | Hủy đơn, bị sàn phạt, mất điểm shop, khách bỏ đi | Giữ chỗ (reserve/release) + kiểm soát đồng thời |
| P2 | **Tồn trên hệ thống lệch thực tế**, không biết lệch từ lúc nào, do ai | Không tin được số liệu, đặt hàng sai, mất thời gian đối chiếu | Sổ cái biến động tồn bất biến + audit người/lý do/phiếu |
| P3 | **Hàng "biến mất" khi chuyển kho** (đường BN → ĐN mất 2–3 ngày) | Thất thoát không ai chịu trách nhiệm | Chuyển kho có trạng thái đang đi đường + quy trình xử lý chênh lệch |
| P4 | **Hàng giá trị cao thất thoát**, cuối tháng kiểm kê mới biết | Mất tiền, phát hiện muộn, khó truy | Kiểm kê vòng (cycle count) thường xuyên + điều chỉnh có lý do |
| P5 | **Nhân viên kho này sửa nhầm tồn kho khác** | Sai số liệu lan sang kho không liên quan | Phân quyền theo vai trò + phạm vi kho |

## Mục tiêu sản phẩm v1

1. **0 trường hợp tồn âm**, kể cả khi nhiều người (hoặc nhiều đơn từ sàn) cùng xuất một SKU. *(P1)*
2. **Mọi thay đổi tồn truy được** người làm, lý do và phiếu gốc; tồn hiện tại luôn khớp tổng sổ cái. *(P2)*
3. **Mỗi đơn vị hàng chuyển kho có chỗ đứng rõ ràng**: ở kho nguồn, đang đi đường, ở kho đích, hoặc đã ghi nhận mất kèm bên chịu trách nhiệm. *(P3)*
4. **Kiểm kê một nhóm SKU mà không phải dừng bán hàng**, chênh lệch được duyệt và ghi lại. *(P4)*
5. **Người dùng chỉ thao tác được trên kho được giao.** *(P5)*

## Phạm vi v1

### Làm

- Master data: danh mục (cây), sản phẩm, SKU, quy đổi đơn vị **theo từng SKU**, barcode, nhà cung cấp, khách hàng / đại lý, kho.
- Nhập kho, xuất kho, chuyển kho, kiểm kê vòng, điều chỉnh tồn.
- Xem tồn (thực có / đã giữ chỗ / khả dụng) và lịch sử biến động.
- Cảnh báo tồn thấp trong ứng dụng.
- API cho kênh bán bên ngoài: tạo đơn, hủy đơn, xem đơn, xem tồn khả dụng.
- Giao diện web (Next.js) cho toàn bộ chức năng trên.
- Phân quyền 5 vai trò + phạm vi kho.

Quy tắc nền: số lượng là **số nguyên**, lưu theo **đơn vị cơ sở** (cái); tồn quản lý tới **cấp kho**.

### Không làm (v2 hoặc sau)

- Vị trí trong kho (khu / kệ / ô), lô & hạn dùng, số serial.
- Kết nối API sàn thật; app TMĐT flash sale riêng (v2).
- Dashboard thời gian thực, thông báo email, báo cáo phân tích nâng cao.
- Kiểm kê toàn kho có khóa kho.
- Giá trị tồn kho, giá vốn.
- Kiến trúc microservice và hạ tầng đi kèm (message broker, cache phân tán).

## Người dùng

| Vai trò | Ở VietHome là ai | Một ngày làm việc |
|---|---|---|
| **Admin** | Admin IT | Tạo SKU mới khi có hàng mới, gán nhân viên vào kho, cấu hình kênh bán |
| **Manager** | 3 quản lý kho (mỗi kho một người) | Duyệt kiểm kê, xử lý hàng chuyển kho bị thiếu, xử lý đơn giữ chỗ quá lâu, điều chỉnh tồn hàng hỏng |
| **Staff** | ~25 nhân viên kho | Nhận hàng NCC, lấy hàng và xuất đơn, đếm hàng khi kiểm kê |
| **Viewer** | 2 kế toán | Xem tồn và lịch sử biến động của mọi kho để đối chiếu |
| **Channel client** | Hệ thống của sàn / đại lý (máy gọi máy) | Đẩy đơn mới, hủy đơn, hỏi còn hàng không |

## Tiêu chí thành công v1

v1 được coi là thành công khi demo được **5 kịch bản** sau, mỗi kịch bản có test tự động chứng minh:

1. **Hai người cùng xuất một SKU** đang còn 10 cái, mỗi người 8 cái → một người thành công, người kia bị báo thiếu hàng; tồn không bao giờ âm. *(P1)*
2. **Chuyển 20 nồi chiên BN → ĐN, kho ĐN chỉ nhận 18** → phiếu vào trạng thái chênh lệch; Manager ghi nhận 1 cái mất do nhà vận chuyển, 1 cái tìm thấy sau; tồn hai kho và sổ cái khớp. *(P3)*
3. **Kiểm kê vòng phát hiện thiếu 3 cái** trong khi kho vẫn xuất hàng bình thường → Manager duyệt, tồn được điều chỉnh đúng phần chênh lệch. *(P4, P2)*
4. **Sàn gửi cùng một đơn hai lần** (do mạng chập chờn) → chỉ tạo một phiếu xuất, chỉ giữ chỗ một lần. *(P1)*
5. **Nhân viên kho Đà Nẵng cố thao tác phiếu của kho Bình Dương** → bị từ chối. *(P5)*
