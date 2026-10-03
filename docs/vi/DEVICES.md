# Danh sách thiết bị

[Mục lục](../README_VI.md)

## Các thiết bị cần sao lưu: tệp devicelist.cfg

Đúng như tên gọi, `devicelist.cfg` liệt kê các thiết bị để sao lưu hàng loạt và dữ liệu cần thiết để kết nối tới chúng.
Đặt tệp ngay bên cạnh `mikrotik-backup.sh`.
Bạn có thể tạo `devicelist.cfg` thủ công hoặc thông qua BackUP Master.
Lựa chọn thứ ba hữu ích khi Oxidized chạy trên cùng máy chủ. Sau khi bạn thêm các thiết lập tương ứng vào tệp tùy chọn,
script sẽ tự động tạo lại `devicelist.cfg` trong mỗi lần chạy bằng dữ liệu cần thiết từ các tệp cấu hình Oxidized.

<br />

## Tạo và chỉnh sửa danh sách

Để tạo danh sách qua BackUP Master, hãy chạy:

```bash
mikrotik-backup.sh -b
```

Điền tên thiết bị, địa chỉ, tên đăng nhập, mật khẩu và cổng SSH → chọn **2. Save device to devicelist.cfg**.
BackUP Master sẽ tạo tệp với mục cần thiết hoặc thêm hay cập nhật một mục trong tệp hiện có.

Bạn có thể chỉnh sửa danh sách hoàn chỉnh bằng trình soạn thảo văn bản thông thường. BackUP Master không nạp các mục hiện có vào biểu mẫu.

*(Lưu ý: Khi BackUP Master lưu cổng `22`, nó ghi một trường trống. Sao lưu hàng loạt sẽ dùng `SshPort` trong thiết lập script cho mục đó. Cổng không chuẩn được ghi rõ.)*

<br />

## Định dạng tệp

Ghi mỗi thiết bị trên một dòng riêng. Phân tách các trường bằng **ký tự TAB**, không dùng dấu cách. Các trường có thứ tự như sau:

| Vị trí | Trường | Mục đích |
|---|---|---|
| 1 | Tên | Tên thiết bị; bắt buộc |
| 2 | Địa chỉ | Địa chỉ IP hoặc tên DNS của thiết bị; bắt buộc |
| 3 | Tên đăng nhập | Người dùng trên thiết bị RouterOS; nếu bỏ trống, kế thừa từ `Login` trong `option.cfg` |
| 4 | Mật khẩu | Mật khẩu thiết bị RouterOS; nếu bỏ trống, kế thừa từ `Password` trong `option.cfg` |
| 5 | Cổng | Cổng SSH từ `1` đến `65535`; nếu bỏ trống, kế thừa từ `SshPort`, có giá trị mặc định là `22` |
| 6 | Dấu hiệu thiết bị | `MikroTik`; có thể để trống. Không phân biệt chữ hoa/chữ thường |

Các trường từ vị trí thứ bảy trở đi không được sử dụng. Những mục có dấu hiệu thiết bị khác sẽ bị bỏ qua.

### Danh sách ví dụ

Các trường trong ví dụ này được phân tách bằng ký tự TAB thực sự:

```text
Router-A	xxx.xxx.xxx.1	UserName	MySuperPassword	1922	MikroTik
Router-B	xxx.xxx.xxx.2	UserName	MySuperPassword		MikroTik
```

Cổng bị bỏ trống ở dòng thứ hai: có hai ký tự TAB giữa mật khẩu và `MikroTik`. Hãy thay địa chỉ và thông tin xác thực bằng dữ liệu của bạn.

### Dùng chung tên đăng nhập, mật khẩu và cổng

Nếu mọi thiết bị dùng cùng thông tin xác thực, hãy chỉ định chúng một lần trong `option.cfg`:

```ini
Login=UserName
Password=MySuperPassword
SshPort=22
```

Khi đó, `devicelist.cfg` chỉ cần tên và địa chỉ của mỗi thiết bị:

```text
Router-A	xxx.xxx.xxx.1
Router-B	xxx.xxx.xxx.2
```

Thông tin xác thực được chỉ định trong mục riêng của thiết bị sẽ ghi đè các giá trị dùng chung.

*(Lưu ý: Tệp danh sách thiết bị chứa mật khẩu. Hãy hạn chế quyền truy cập như mô tả trong [SECURITY.md](SECURITY.md).)*

<br />

## Cách đọc danh sách

Các dòng trống và dòng có ký tự khác khoảng trắng đầu tiên là `#` sẽ bị bỏ qua. Hãy đặt chú thích trên dòng riêng; ký tự `#` bên trong một trường là một phần của giá trị.

Khoảng trắng ở đầu và cuối được loại bỏ khỏi tên, địa chỉ, cổng và dấu hiệu. Tên đăng nhập và mật khẩu được đọc nguyên văn, bao gồm khoảng trắng và dấu nháy. Tệp dùng kiểu kết thúc dòng Windows (CRLF) được hỗ trợ.

Nếu một dòng—tức một mục thiết bị—vi phạm cú pháp bắt buộc, script sẽ bỏ qua dòng đó trong khi thực thi và đưa ra cảnh báo rằng mục này không hợp lệ.

Nếu một dòng bị lặp vì bất kỳ lý do gì—nghĩa là cả bốn tham số kết nối (**địa chỉ, tên đăng nhập, mật khẩu và cổng**) đều trùng khớp—script chỉ kết nối tới thiết bị đó một lần, dùng dữ liệu của mục cuối cùng.
Nếu các kết nối khác nhau có cùng tên, mục dùng được đầu tiên sẽ được sử dụng và mục xung đột bị bỏ qua.

<br />

<a id="device-names"></a>
## Tên thiết bị

Tên được dùng trong tên tệp sao lưu và, ở chế độ hàng loạt, cho thư mục con của thiết bị.
Thiết lập `UseIdentityName` trong `option.cfg` xác định nguồn lấy tên:

| Giá trị | Nguồn tên |
|---|---|
| `true` (mặc định) | Giá trị Identity trên chính thiết bị RouterOS |
| `false` | Tên từ `devicelist.cfg`, trường trong BackUP Master hoặc `--device-name` khi chạy CLI cho một thiết bị |

### Tên trong ngoặc đơn

Nếu tên ban đầu chứa ngoặc đơn, script dùng nội dung của nhóm đầy đủ, không trống đầu tiên. Nếu không có nhóm như vậy, script dùng toàn bộ tên.

| Tên ban đầu | Tên sao lưu |
|---|---|
| `Филиал (Core East)` | `Core_East` |
| `Branch () (Core)` | `Core` |
| `Филиал (Core (East) West)` | `Core_East_West` |

### Ký tự được phép

Tên cuối cùng giữ lại các chữ cái, kể cả chữ cái Cyrillic, chữ số, dấu chấm, dấu gạch nối và dấu gạch dưới. Khoảng trắng và ký tự không hợp lệ được thay bằng `_`. Dấu gạch dưới lặp lại, ở đầu hoặc cuối sẽ bị loại bỏ; dấu chấm và dấu gạch nối ở đầu cùng dấu chấm ở cuối tên cũng bị loại bỏ.

Ví dụ, `ЦОД Москва №1` trở thành `ЦОД_Москва_1`.

Tên cuối cùng phải dài **từ 1 đến 32 ký tự**. Tên quá dài không bị cắt ngắn; nó gây lỗi. Không cho phép các tên dành riêng `CON`, `PRN`, `AUX`, `NUL`, `COM1`–`COM9` và `LPT1`–`LPT9`.

Các tên cuối cùng phải là duy nhất mà không phân biệt chữ hoa/chữ thường: `Router-A` và `router-a` được xem là một. Thiết bị thứ hai có tên đó sẽ bị bỏ qua trong lần chạy hiện tại.

*(Lưu ý: Thay đổi tên cuối cùng cũng làm thay đổi thư mục con của thiết bị. Các bản sao lưu cũ không được tự động di chuyển.)*

<br />

## Nhập từ Oxidized

Nếu bạn đã duy trì danh sách thiết bị trong Oxidized, script có thể lấy danh sách từ đó. Thêm nội dung sau vào `option.cfg`:

```ini
UseOxidized=true
OxidizedHome=/var/lib/oxidized
IgnoreOxiAccess=true
```

Đặt `OxidizedHome` thành thư mục chứa `config` và `router.db`. Script tạo `devicelist.cfg` từ chúng. Script không sửa đổi các tệp Oxidized.

*(Lưu ý: Thao tác nhập sẽ thay thế `devicelist.cfg`; nó không bổ sung tệp. Các mục được thêm thủ công sẽ mất vào lần cập nhật Oxidized thành công tiếp theo.)*

### Thiết lập nguồn

Cấu hình Oxidized phải dùng nguồn `csv` với dấu phân cách một ký tự. `source.csv.map` xác định thứ tự cột, đánh số từ không:

| Trường ánh xạ | Giá trị được dùng |
|---|---|
| `name` | Tên thiết bị; cột bắt buộc |
| `ip` | Địa chỉ thiết bị; nếu bỏ qua, giá trị `name` được dùng |
| `username` | Tên đăng nhập; nếu bỏ qua, dùng `Login` chung từ `option.cfg` |
| `password` | Mật khẩu; nếu bỏ qua, dùng `Password` chung từ `option.cfg` |
| `port` | Cổng SSH; nếu bỏ qua, dùng `SshPort` |
| `model` | Mẫu thiết bị; nếu không có cột này, dùng tham số `model` ở cấp gốc |

Các quy tắc `model_map` được áp dụng tới kết quả khớp đầu tiên. Chỉ các thiết bị có mẫu cuối cùng là `routeros` mới được nhập. Nếu có cột `model`, tham số ở cấp gốc không thay thế các giá trị trống trong cột đó.

Dữ liệu luôn được đọc từ `<OxidizedHome>/router.db`. Tham số `source.csv.file` của Oxidized không thay đổi đường dẫn này.

### Nếu thao tác nhập thất bại

Nếu các tệp Oxidized không truy cập được, định dạng không được hỗ trợ hoặc không tìm thấy thiết bị phù hợp, `devicelist.cfg` trước đó được giữ nguyên.

Với `IgnoreOxiAccess=true`, script có thể dùng danh sách dùng được trước đó. Với `false`, script không thực hiện sao lưu từ danh sách cũ.

Lỗi nhập ảnh hưởng đến kết quả lần chạy ngay cả khi quá trình sao lưu bằng danh sách trước đó thành công.

Xem [Khắc phục sự cố](TROUBLESHOOTING.md) để biết chi tiết về lỗi danh sách và lỗi nhập.
