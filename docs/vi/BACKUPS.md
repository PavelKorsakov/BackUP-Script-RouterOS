# Bản sao lưu và kho lưu trữ

[Mục lục](../README_VI.md)

## Định dạng sao lưu

Script có thể lưu cấu hình thiết bị dưới dạng văn bản, tạo bản sao lưu nhị phân hoặc lấy về cả hai định dạng.
Tham số `backup_type` trong `option.cfg` chọn định dạng:

| Giá trị | Nội dung được lưu |
|---|---|
| `configuration` | Cấu hình RouterOS trong tệp `.rsc` |
| `binary` | Bản sao lưu nhị phân trong tệp `.backup` |
| `both` | Cả hai định dạng: `.rsc` trước, sau đó `.backup` |

Giá trị mặc định là `both`. Bạn có thể thay đổi trong tệp tùy chọn, Trình chỉnh sửa cấu hình, BackUP Master hoặc bằng `--backup-type`.

### Cấu hình văn bản: .rsc

Tham số `export_format` chọn định dạng xuất. Các giá trị hợp lệ là `compact`, `terse` và `verbose`; mặc định là `compact`.

Tham số `show_sensitive` xác định dữ liệu xuất có bao gồm dữ liệu nhạy cảm, kể cả mật khẩu, hay không. Tham số này được bật theo mặc định.
Để vô hiệu hóa, thêm nội dung sau vào `option.cfg`:

```ini
show_sensitive=false
```

### Bản sao lưu nhị phân: .backup

Bạn có thể mã hóa bản sao lưu nhị phân. Đặt mật khẩu cần dùng trong `encrypt`:

```ini
encrypt=MySuperPassword
```

Với giá trị `encrypt=` trống, tệp được lưu mà không mã hóa. Đây là giá trị mặc định.

*(Lưu ý: Mã hóa AES-SHA256 chỉ áp dụng cho `.backup`. Nó không mã hóa cấu hình văn bản, nhật ký hoặc kho lưu trữ ZIP.)*

Theo mặc định, script xóa bộ nhớ đệm DNS và lịch sử console của RouterOS trước khi tạo bản sao lưu nhị phân. Nếu bạn không cần các thao tác này, hãy vô hiệu hóa tham số tương ứng:

```ini
clear_dns_cache=false
clear_console_history=false
```

Các thao tác dọn dẹp này không được thực hiện khi chỉ lấy về cấu hình văn bản.

<br />

## Tên tệp và vị trí

Theo mặc định, bản sao lưu được lưu trong thư mục `backups` bên cạnh script. Đặt thư mục khác bằng `BackupRoot` trong tệp tùy chọn.

Khi chạy cho một thiết bị, các tệp được đặt trực tiếp trong thư mục đó:

```text
backups/
├── main.log
├── Router-A_YYYY-MM-DD_HH-MM.rsc
├── Router-A_YYYY-MM-DD_HH-MM.backup
└── Router-A_YYYY-MM-DD_HH-MM.log
```

Trong chế độ hàng loạt, mỗi thiết bị có thư mục con riêng:

```text
backups/
├── main.log
└── Router-A/
    ├── Router-A_YYYY-MM-DD_HH-MM.rsc
    ├── Router-A_YYYY-MM-DD_HH-MM.backup
    ├── Router-A.log
    └── archive/
        └── DD.MM.YYYY.zip
```

Tên tệp sao lưu chứa tên thiết bị cùng ngày và giờ từ đồng hồ của máy chủ chạy script. Cả hai định dạng trong cùng một thao tác sao lưu dùng chung dấu thời gian.
Cách tạo tên thiết bị được mô tả trong [DEVICES.md](DEVICES.md#device-names).

**Hãy chú ý!!!**
Nếu bạn sao lưu cùng một thiết bị vào cùng một thư mục hai lần trong vòng một phút, tên tệp sẽ trùng nhau. Tệp mang tên đó bị thay thế; lần chạy thứ hai không tạo một phiên bản riêng.

Bạn cũng có thể dùng thư mục mạng làm nơi lưu trữ. Trong chế độ hàng loạt, đặt `UseNetFolder=true` để kiểm tra nơi lưu trữ đó. Cách chuẩn bị thư mục được mô tả trong [INSTALL.md](INSTALL.md), còn thiết lập đường dẫn nằm trong [OPTIONS.md](OPTIONS.md#network-storage).

[LOGGING.md](LOGGING.md) giải thích chi tiết vị trí và nội dung nhật ký.

<br />

## Sao lưu gia tăng

Tính năng này tránh giữ các bản sao lưu trùng lặp khi không phát hiện thay đổi. Tham số `UseIncremental` điều khiển tính năng:

| Giá trị | Cách giữ bản sao lưu |
|---|---|
| `true` (mặc định) | Nếu bản sao lưu mới được xác định là trùng lặp, tệp mới bị xóa và bản trước được giữ lại |
| `false` | Mọi bản sao lưu mới hợp lệ đều được giữ lại mà không so sánh với bản trước |

Khi phát hiện thay đổi hoặc không có bản sao lưu trước đó, tệp mới được giữ lại. Nếu không thể hoàn tất so sánh, tệp cũng được giữ lại nhưng script đưa ra cảnh báo.

**Và đây là điểm dễ bỏ sót!!!**
Cách so sánh khác nhau theo định dạng:

| Định dạng | Nội dung được so sánh |
|---|---|
| `.rsc` | Nội dung tệp. Ngày và giờ trong phần đầu tiêu chuẩn của RouterOS bị bỏ qua |
| `.backup` | Chỉ kích thước tệp tính theo byte |

Vì vậy, hai tệp nhị phân có cùng kích thước được xem là trùng lặp ngay cả khi nội dung khác nhau. Hãy tính đến điều này khi chọn thiết lập lưu giữ.

Script so sánh với bản sao lưu cũ gần nhất của cùng thiết bị và định dạng trong thư mục thiết bị đó. Các bản sao lưu đã được đóng gói vào ZIP không tham gia so sánh.

Script giữ các tệp `.rsc` và `.backup` thông thường, không tạo tệp thay đổi riêng. Vô hiệu hóa `UseIncremental` không vô hiệu hóa việc lấy và xác minh bản sao lưu, ghi nhật ký hay lưu trữ vào kho hằng tháng.

<br />

<a id="monthly-archive"></a>
## Kho lưu trữ hằng tháng

Tính năng này bị vô hiệu hóa theo mặc định. Đặt `MonthlyArchive` trong `option.cfg` để chọn ngày đưa các bản sao lưu và nhật ký đã tích lũy vào kho lưu trữ:

| Giá trị | Hành vi |
|---|---|
| `false` (mặc định) | Lưu trữ vào kho bị vô hiệu hóa |
| `true` hoặc `1` | Việc lưu trữ vào kho chạy vào ngày đầu tiên của tháng |
| `2` đến `28` | Việc lưu trữ vào kho chạy vào ngày được chỉ định trong tháng |

Thời điểm chạy trong ngày đã chọn không quan trọng. Hãy cấu hình lịch riêng như mô tả trong [INSTALL.md](INSTALL.md#chạy-script-tự-động).

### Nội dung được đưa vào kho lưu trữ

Trong chế độ hàng loạt, thứ tự công việc thay đổi vào ngày đó: trước tiên script gom các tệp đã tích lũy của thiết bị vào một tệp ZIP, sau đó mới tạo bản sao lưu mới. Các bản sao lưu do lần chạy hiện tại tạo vẫn nằm ngoài kho lưu trữ.

Kho lưu trữ bao gồm các tệp thông thường nằm trực tiếp trong thư mục thiết bị, kể cả toàn bộ nhật ký thiết bị tích lũy. Phạm vi không chỉ giới hạn ở `.rsc` và `.backup`: những tệp thông thường khác mà bạn đặt trong thư mục cũng có thể được đưa vào kho lưu trữ.

Thư mục con, liên kết tượng trưng, đối tượng phục vụ lần chạy hiện tại và các tệp ZIP mà script đã tạo trước đó sẽ không được đóng gói lại. **Nhật ký chính, `main.log`, không được đưa vào kho lưu trữ.**

Sau khi tệp ZIP hoàn chỉnh được xác minh và lưu, các tệp nguồn có trong đó sẽ bị xóa khỏi thư mục thiết bị. Nếu không có gì để lưu trữ, script không tạo ZIP trống.

### Tên và vị trí kho lưu trữ

Tệp ZIP được đặt tên theo ngày dương lịch trước đó ở định dạng `DD.MM.YYYY.zip`. Ví dụ, lần chạy vào ngày 1 tháng Mười năm 2026 tạo `30.09.2026.zip`; lần chạy vào ngày 15 tháng Mười tạo `14.10.2026.zip`.

| Chế độ | Vị trí kho lưu trữ |
|---|---|
| Hàng loạt | `<BackupRoot>/<DeviceName>/archive/DD.MM.YYYY.zip` |
| CLI một thiết bị | `<BackupRoot>/DD.MM.YYYY.zip` |

Lần chạy lặp lại trong cùng ngày sẽ cập nhật kho lưu trữ có cùng tên.

### Chế độ một thiết bị và BackUP Master

Khi CLI chạy cho một thiết bị, thứ tự bị đảo ngược: sao lưu chạy trước, sau đó mới lưu trữ vào kho. Vì vậy, bản sao lưu mới của lần chạy hiện tại cũng có thể được đưa vào ZIP.

Ở chế độ này, các tệp `.rsc`, `.backup` và `.log` nằm trực tiếp trong `BackupRoot` được đưa vào kho lưu trữ, ngoại trừ `main.log`. Nếu kết quả từ các lần chạy một thiết bị cho nhiều thiết bị dùng chung một thư mục, các tệp của chúng sẽ vào cùng một kho lưu trữ.

Lưu trữ vào kho hằng tháng không chạy khi dùng BackUP Master.

### Nếu bỏ lỡ một lần chạy

Nếu script không chạy vào ngày đã chọn, lần lưu trữ bị bỏ lỡ sẽ không được thực hiện bù. Lần thử tiếp theo diễn ra vào đúng ngày hằng tháng đã được ấn định trong tháng kế tiếp.

Toàn bộ tệp đã tích lũy sẽ được đưa vào một kho lưu trữ duy nhất ở lần thử tiếp theo đó, kể cả khi chúng thuộc hai, ba hoặc nhiều tháng. Script không tạo tệp ZIP riêng cho các tháng bị bỏ lỡ.

### Nếu lưu trữ vào kho thất bại

Các tệp nguồn không bị xóa cho tới khi một tệp ZIP đã xác minh được lưu thành công. Tương tự, kho lưu trữ hiện có nhưng bị hỏng sẽ không bị tệp mới ghi đè.

Nếu tệp ZIP đã được lưu nhưng không thể xóa một số tệp nguồn, kho lưu trữ hoàn chỉnh vẫn được giữ nguyên, cùng với những tệp không thể xóa. Hãy kiểm tra nhật ký để tìm nguyên nhân lỗi.

*(Lưu ý: Kho lưu trữ được dựng trong thư mục cục bộ `/tmp` ngay cả khi chính các bản sao lưu được lưu trên NAS. Vì vậy, ngoài nơi lưu trữ cũng cần có dung lượng trống.)*

<br />

## Nếu sao lưu thất bại

Sau một lần lấy tệp không thành công, script thử thêm một lần sau 2 giây. Việc thử lại cho `.rsc` và `.backup` được thực hiện riêng biệt.

Lỗi thông thường khi lấy một định dạng không hủy lần thử lấy định dạng còn lại. Nếu một thiết bị không truy cập được, script tiếp tục với các thiết bị còn lại. Nếu mất nơi lưu trữ dùng chung, quá trình xử lý hàng loạt sẽ dừng.

Thông báo lỗi và mã kết quả được mô tả trong [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

<br />

## Lưu giữ và khôi phục

Các tệp ZIP cũ không bị xóa theo tuổi hoặc số lượng. Bạn tự quyết định thời gian lưu giữ và chính sách luân chuyển bên ngoài.

Script tạo bản sao lưu nhưng không khôi phục RouterOS. Hãy kiểm thử việc khôi phục riêng trên thiết bị phù hợp.

*(Lưu ý: Bản sao lưu và kho lưu trữ có thể chứa mật khẩu cùng dữ liệu bí mật khác. Hãy hạn chế quyền truy cập nơi lưu trữ như mô tả trong [SECURITY.md](SECURITY.md).)*
