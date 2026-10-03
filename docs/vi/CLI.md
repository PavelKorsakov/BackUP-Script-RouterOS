# Dòng lệnh

[Mục lục](../README_VI.md)

## Cú pháp

```text
mikrotik-backup.sh [action] [parameters]
```

Tham số dòng lệnh có thể dùng dạng dài: `--parameter value` hoặc `--parameter=value`.
Chúng cũng có thể dùng dạng ngắn: `-p=value`. Tuy nhiên, nếu **giá trị** bắt đầu bằng `-`, chỉ dạng có dấu `=` mới được chấp nhận: `--parameter=-value`.

Tham số không xác định, đối số vị trí, hoặc giá trị bị thiếu, để trống rõ ràng hay không hợp lệ sẽ tạo mã lỗi `12` và dừng script.

<br />

## Hành động

| Hành động | Mục đích |
|---|---|
| `-i` | Trình đơn tương tác chính |
| `-b` | BackUP Master |
| `-e` | Trình chỉnh sửa cấu hình (`option.cfg`) |
| `-h`, `--help` | Trợ giúp tùy chọn CLI |
| `-v`, `--version` | Phiên bản script |

Script không cho phép dùng nhiều hơn một tùy chọn hành động cùng lúc. Ví dụ, `mikrotik-backup.sh -i -b` dừng với mã lỗi `12`.

<br />

## Tham số

| Tham số | Giá trị | Mục đích |
|---|---|---|
| `--device-name` | Tên | Tên thiết bị khi `UseIdentityName=false` |
| `--address` | Địa chỉ hoặc tên DNS | Địa chỉ thiết bị RouterOS |
| `--user` | Tên đăng nhập | Người dùng trên thiết bị RouterOS |
| `--password` | Mật khẩu | Mật khẩu thiết bị RouterOS |
| `--port` | `1`–`65535` | Cổng SSH của thiết bị; mặc định `22` |
| `--language` | `auto` hoặc hai chữ cái ASCII | Ngôn ngữ của giao diện hiện tại và nhật ký script |
| `--use-oxidized` | Giá trị Boolean* | Nhập danh sách thiết bị từ Oxidized |
| `--oxidized-home` | Đường dẫn | Thư mục thiết lập Oxidized chứa `config` và `router.db` |
| `--use-identity-name` | Giá trị Boolean* | Lấy tên từ RouterOS Identity |
| `--backup-root` | Đường dẫn | Thư mục gốc để lưu bản sao lưu |
| `--use-net-folder` | Giá trị Boolean* | Kiểm tra điểm gắn kết trong chế độ hàng loạt |
| `--monthly-archive` | `false` hoặc số từ `1` đến `28`* | Bật lưu trữ vào kho hằng tháng theo lịch |
| `--log-level` | `0`, `1`, `2`, `3` | Mức chi tiết cho nhật ký và đầu ra terminal |
| `--main-log-path` | Đường dẫn | Thư mục chỉ dành cho `main.log` |
| `--backup-type` | `configuration`,`binary`,`both` | Các định dạng sao lưu cần lấy về |
| `--export-format` | `compact`, `terse`, `verbose` | Định dạng xuất văn bản |
| `--show-sensitive` | Giá trị Boolean* | Bao gồm giá trị nhạy cảm trong dữ liệu xuất |
| `--encrypt` | Mật khẩu không trống | Mã hóa `.backup` bằng AES-SHA256 |
| `--clear-dns-cache` | Giá trị Boolean* | Xóa bộ nhớ đệm DNS trước khi sao lưu nhị phân |
| `--clear-console-history` | Giá trị Boolean* | Xóa lịch sử console trước khi sao lưu nhị phân |

`*` Giá trị Boolean là `true` hoặc `false`; script cũng chấp nhận `yes`/`no`, `1`/`0` và `on`/`off`, không phân biệt chữ hoa/chữ thường.
Đối với `backup-type`, `config` và `conf` cũng được chấp nhận như từ đồng nghĩa của `configuration`.

Các dạng kết nối ngắn:

```text
-a=VALUE    tương đương --address VALUE
-u=VALUE    tương đương --user VALUE
-p=VALUE    tương đương --password VALUE
```

<br />

<a id="execution-mode"></a>
## Chạy script từ dòng lệnh

Script có thể sao lưu một thiết bị, nhưng cần ít nhất ba tham số cho lần chạy như vậy:
**địa chỉ IP**, **tên đăng nhập** và **mật khẩu** của thiết bị. Nói cách khác, lệnh này đã có thể sử dụng:

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword
```

Mọi tham số khác được liệt kê ở trên đều là tùy chọn trong trường hợp này.
*(Lưu ý rất quan trọng: script KHÔNG được thiết kế để kết hợp bộ ba kết nối này với một tùy chọn **hành động**.)*

**Thêm một chi tiết nữa!!!**
Đối với lần chạy một thiết bị, cả ba tham số kết nối phải được cung cấp qua CLI. Script không lấy tên đăng nhập hay mật khẩu bị thiếu từ `option.cfg`.

<br />

## Thứ tự ưu tiên thiết lập

Sao lưu thông thường cho một thiết bị và theo lô dùng thứ tự được mô tả trong [OPTIONS.md](OPTIONS.md):
**Giá trị tích hợp** → **Các dòng dùng được trong option.cfg** → **CLI**

Nếu một tham số đã có trong `option.cfg` nhưng một lần chạy cụ thể cần giá trị khác, hãy truyền giá trị đó qua CLI. Bạn không cần viết lại tệp cấu hình.

Lần chạy một thiết bị không dùng danh sách thiết bị hoặc dữ liệu nhập từ Oxidized. Các thiết lập khác trong `option.cfg` vẫn áp dụng trừ khi tham số dòng lệnh thay thế chúng.

**BackUP Master có thứ tự riêng để điền biểu mẫu.**
Các trường thông thường dùng giá trị tích hợp và tham số CLI đã cung cấp, không dùng `option.cfg`. `UseIncremental` là ngoại lệ: giá trị này được kế thừa từ tệp hoặc nhận giá trị mặc định.
`LogLevel` và `MainLogPath` đã chọn được giữ lại cho lần chạy, còn lưu trữ vào kho hằng tháng bị vô hiệu hóa. Xem [INTERACTIVE.md](INTERACTIVE.md) để biết chi tiết về chính BackUP Master.

<br />

## Tham số dòng lệnh theo mục đích

### Kết nối và tên thiết bị

| Tùy chọn | Giá trị | Mục đích |
|---|---|---|
| `--address` | Địa chỉ IP hoặc tên DNS | Địa chỉ thiết bị RouterOS |
| `--user` | Tên đăng nhập | Người dùng trên thiết bị RouterOS |
| `--password` | Mật khẩu | Mật khẩu thiết bị RouterOS |
| `--port` | `1` đến `65535` | Cổng SSH của thiết bị; mặc định `22` |
| `--device-name` | Tên | Tên thiết bị khi `UseIdentityName=false` |
| `--use-identity-name` | `true` / `false` | Lấy tên từ RouterOS Identity |

Để dùng tên của riêng bạn, hãy chỉ định đồng thời `--use-identity-name false` và `--device-name NAME`.

<br />

### Định dạng và nội dung bản sao lưu

| Tùy chọn | Giá trị | Mục đích |
|---|---|---|
| `--backup-type` | `configuration`, `binary`, `both` | Các định dạng sao lưu cần lấy về |
| `--export-format` | `compact`, `terse`, `verbose` | Định dạng xuất văn bản |
| `--show-sensitive` | `true` / `false` | Bao gồm giá trị nhạy cảm trong dữ liệu xuất |
| `--encrypt` | Mật khẩu không trống | Mã hóa `.backup` bằng AES-SHA256 |
| `--clear-dns-cache` | `true` / `false` | Xóa bộ nhớ đệm DNS trước khi sao lưu nhị phân |
| `--clear-console-history` | `true` / `false` | Xóa lịch sử console trước khi sao lưu nhị phân |

Đối với `--backup-type`, `config` và `conf` cũng có nghĩa là `configuration`.

*(Lưu ý: `UseIncremental` không có tùy chọn CLI riêng. Hãy đặt giá trị này trong `option.cfg`, Trình chỉnh sửa cấu hình hoặc BackUP Master. Mục đích của nó được mô tả trong [OPTIONS.md](OPTIONS.md).)*

<br />

### Nơi lưu trữ, kho lưu trữ và nhật ký

| Tùy chọn | Giá trị | Mục đích |
|---|---|---|
| `--backup-root` | Đường dẫn | Thư mục gốc để lưu bản sao lưu |
| `--use-net-folder` | `true` / `false` | Kiểm tra điểm gắn kết trong chế độ hàng loạt |
| `--monthly-archive` | `false` hoặc số từ `1` đến `28` | Bật lưu trữ vào kho hằng tháng theo lịch |
| `--log-level` | `0`, `1`, `2`, `3` | Mức chi tiết cho nhật ký và đầu ra terminal |
| `--main-log-path` | Đường dẫn thư mục | Thư mục chỉ dành cho `main.log` |

`--monthly-archive` có quy tắc riêng: `true`/`yes`/`1`/`on` nghĩa là ngày đầu tiên của tháng, còn `false`/`no`/`0`/`off` vô hiệu hóa việc lưu trữ vào kho. Giá trị từ `2` đến `28` chọn ngày cần dùng.

Tùy chọn này chọn ngày lưu trữ vào kho; nó không thực hiện lưu trữ ngay lập tức. Xem [BACKUPS.md](BACKUPS.md#kho-lưu-trữ-hằng-tháng) để biết quy tắc của chế độ này.

Đối với `--main-log-path`, hãy chỉ định một thư mục, không phải đường dẫn đầy đủ kết thúc bằng `main.log`. Thiết lập này không ảnh hưởng đến nhật ký thiết bị.

<br />

### Nguồn danh sách thiết bị và ngôn ngữ

| Tùy chọn | Giá trị | Mục đích |
|---|---|---|
| `--use-oxidized` | `true` / `false` | Nhập danh sách thiết bị từ Oxidized |
| `--oxidized-home` | Đường dẫn | Thư mục thiết lập Oxidized chứa `config` và `router.db` |
| `--language` | `auto` hoặc mã hai chữ cái | Ngôn ngữ của giao diện hiện tại và nhật ký script |

Với `--language auto`, locale của hệ điều hành chọn ngôn ngữ. Bạn có thể chọn rõ ràng, chẳng hạn `ru`, `en` hoặc `de`. Tiếng Nga và tiếng Anh không cần tệp dịch riêng; các bản dịch khác được nạp từ tệp bên cạnh script. Nếu không có bản dịch phù hợp, tiếng Anh được sử dụng.
Xem [LOCALIZATION.md](LOCALIZATION.md) để biết chi tiết.

<br />

## Ví dụ

**Hãy chú ý!!!**
Theo mặc định, xuất dữ liệu nhạy cảm, xóa bộ nhớ đệm DNS và xóa lịch sử console trước khi sao lưu nhị phân đều được bật. Các ví dụ một thiết bị dưới đây vô hiệu hóa việc dọn dẹp và xuất dữ liệu nhạy cảm.

*(Lưu ý: Mật khẩu cung cấp qua CLI có thể hiển thị trong lịch sử shell và các đối số tiến trình. Điều này cũng áp dụng cho mật khẩu mã hóa `.backup`, mật khẩu này có thể hiển thị trong các đối số của tiến trình con `ssh`. Xem [SECURITY.md](SECURITY.md) để biết chi tiết.)*

### Chỉ cấu hình `.rsc`, không có dữ liệu nhạy cảm

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --backup-type=configuration --show-sensitive=false
```

### Cả hai định dạng, tên thiết bị tùy chỉnh và không dọn dẹp

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --use-identity-name=false --device-name=edge-router --backup-type=both --show-sensitive=false --clear-dns-cache=false --clear-console-history=false
```

### Bản sao lưu nhị phân được mã hóa

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --backup-type=binary --encrypt='ENCRYPTION_PASSWORD' --clear-dns-cache=false --clear-console-history=false
```

### Chạy hàng loạt với thư mục riêng và nhật ký chi tiết

Ví dụ này giả định `option.cfg` và danh sách thiết bị đã được chuẩn bị:

```bash
mikrotik-backup.sh --backup-root=/srv/mikrotik-backups --log-level=3
```

Các thiết lập còn lại cho lần chạy hàng loạt này đến từ `option.cfg` và các giá trị tích hợp.

<br />

## Nếu một lệnh bị từ chối

Tùy chọn không xác định, đối số vị trí thừa hoặc giá trị bị thiếu hay không hợp lệ sẽ gây lỗi `12`. Không có quá trình sao lưu nào bắt đầu. Dùng `-h` để kiểm tra chính tả tùy chọn.

**Không thể truyền giá trị trống qua CLI.**
`--encrypt=''` và `--main-log-path=''` bị từ chối. Hãy đặt giá trị trống `encrypt=` và `MainLogPath=` trong `option.cfg` hoặc thông qua Trình chỉnh sửa cấu hình.

Các mã kết quả và ý nghĩa của chúng được liệt kê trong mục [Khắc phục sự cố](TROUBLESHOOTING.md#result-codes).
