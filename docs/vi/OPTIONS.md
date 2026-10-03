# Cấu hình

[Mục lục](../README_VI.md)

## Trước hết, đôi lời

Tệp `option.cfg` tùy chọn cho phép bạn thay đổi các thiết lập mặc định mà script sử dụng.
Để script nạp những thiết lập được liệt kê trong tệp này khi thực thi,
`option.cfg` phải nằm bên cạnh `mikrotik-backup.sh` trong cùng thư mục.

Cấu trúc tệp rất đơn giản: một danh sách các mục `Key=value`. Đây không phải shell script.
Tệp không thực hiện khai triển biến hay chạy lệnh.

## Khi nào cấu hình dùng được cho một lần chạy

Chỉ cần một dòng hợp lệ và được nhận diện là cấu hình đã có thể sử dụng.
Bạn không cần liệt kê mọi thiết lập: nếu giá trị mặc định phù hợp, tùy chọn đó không cần xuất hiện trong `option.cfg`.

Tuy nhiên, nếu tệp trống hoặc chỉ chứa chú thích, khóa không xác định hay giá trị không hợp lệ, script sẽ không có gì để nạp từ tệp.
Khi đó, các thiết lập vẫn giữ giá trị mặc định.

**Và đây là điểm dễ bỏ sót!!!**
Nếu bạn chạy script không kèm đối số trong trạng thái đó, quá trình sao lưu sẽ không bắt đầu. Thay vào đó, script cố mở Trình chỉnh sửa cấu hình.
Điều tương tự xảy ra khi hoàn toàn không có `option.cfg`.
Hãy lưu các thiết lập cần thiết rồi chạy lại script.
*(Lưu ý: Trình chỉnh sửa cần terminal. Nếu script chạy mà không có terminal—ví dụ do bộ lập lịch khởi chạy—script sẽ thoát với lỗi `31`.
Hãy chuẩn bị `option.cfg` trước khi cấu hình chạy tự động.)*

**Thứ tự đọc các tham số tùy chọn:**
Script áp dụng các nguồn tham số theo thứ tự ưu tiên. Nếu không có `option.cfg`, script dùng các giá trị mặc định được tích hợp.
Nếu tệp tồn tại và được đọc thành công, các tham số <mark>hợp lệ</mark> trong tệp sẽ thay thế giá trị mặc định tương ứng.

Và quan trọng nhất!!! Nếu cùng một tham số được cung cấp qua CLI, giá trị CLI được ưu tiên.
Vì vậy, đối với một lần chạy thông thường cho một thiết bị hoặc theo lô, thứ tự ưu tiên là:
**Giá trị tích hợp** → **Các dòng dùng được trong option.cfg** → **CLI**

*(Lưu ý: Tệp không tồn tại không giống với tệp không đọc được.
Nếu `option.cfg` tồn tại nhưng script không thể đọc, quá trình thực thi kết thúc với
lỗi cấu hình `21`; script không tiếp tục bằng các giá trị mặc định.)*

## Cách đọc tệp

Mỗi dòng được tách tại dấu `=` đầu tiên. Tên khóa không phân biệt chữ hoa/chữ thường, nhưng dấu gạch nối và dấu gạch dưới không thể thay thế cho nhau.
Các dòng trống và dòng có ký tự khác khoảng trắng đầu tiên là `#` sẽ bị bỏ qua. Một dòng không xác định hoặc không hợp lệ không làm mất hiệu lực các dòng đúng bên cạnh.
Khi một khóa xuất hiện nhiều lần, giá trị hợp lệ cuối cùng được sử dụng.

Khoảng trắng ở đầu và cuối được loại bỏ khỏi các giá trị thông thường.
**Quan trọng:** đối với `Login`, `Password` và `encrypt`, mọi thứ sau dấu `=` đầu tiên được giữ nguyên từng ký tự.
Đừng thêm dấu nháy theo cú pháp shell: dấu nháy sẽ trở thành một phần của giá trị.
Đừng đặt chú thích sau mật khẩu. Hãy dùng một dòng riêng cho chú thích.

Tệp hỗ trợ một BOM ở đầu và kiểu kết thúc dòng CRLF.
Cho phép liên kết tượng trưng có thể đọc được trỏ tới một tệp thông thường.
Sự cố truy cập hoặc loại đối tượng không phù hợp không được xem như tệp trống
và sẽ gây lỗi cấu hình.

## Tạo, chỉnh sửa và lưu 'option.cfg'

Cách dễ nhất để tạo tệp là chạy script với `-e`:

```bash
./mikrotik-backup.sh -e
```

Trình chỉnh sửa cấu hình sẽ mở và liệt kê các tùy chọn chính.
Nếu mọi dòng không vừa cửa sổ terminal, danh sách sẽ tự động cuộn khi bạn di chuyển lên xuống bằng phím mũi tên.
Các mục **Save** và **Cancel** nằm ở cuối cùng danh sách đó.
Di chuyển trong trình đơn, nhập các thiết lập bạn cần → chọn **Save** → và (bạn thật tuyệt) tệp đã được tạo.

Hãy nhớ rằng trong lúc bạn làm việc ở trình đơn tương tác, trình chỉnh sửa chỉ thay đổi thiết lập trong bộ nhớ.
Chỉ sau khi bạn chọn **Save**, nó mới ghi toàn bộ tệp ở dạng *chuẩn hóa*.

Nếu `option.cfg` chưa tồn tại, ban đầu trình chỉnh sửa điền các giá trị mặc định vào các trường.
Nếu tệp đã tồn tại và bạn đã thay đổi một số tham số, Trình chỉnh sửa cấu hình sẽ điền giá trị của bạn thay vì giá trị mặc định.

Cách thứ hai để tạo 'option.cfg' là làm thủ công. Đúng vậy: tự tay mở trình soạn thảo văn bản yêu thích và nhập các thiết lập bạn cần.
Tìm chúng ở đâu? Ngay bên dưới:

## Thiết lập và giá trị mặc định

| Khóa | Mặc định | Giá trị và mục đích |
|---|---|---|
| `Language` | `auto` | `auto` hoặc hai chữ cái ASCII, chẳng hạn `ru`, `en` hoặc `de` |
| `SshPort` | `22` | Cổng `1`–`65535`; bị ẩn trong trình chỉnh sửa, hiển thị trong BackUP Master |
| `UseOxidized` | `false` | Nhập thiết bị từ Oxidized |
| `IgnoreOxiAccess` | `true` | Cho phép dùng DeviceList trước đó sau khi đọc/phân tích Oxidized thất bại; chỉ có trong tệp |
| `OxidizedHome` | Trống | Thư mục chứa `config` và `router.db` |
| `UseIdentityName` | `true` | Dùng Identity hiện tại của RouterOS làm tên thiết bị |
| `backup_type` | `both` | `configuration`, `binary` hoặc `both` |
| `UseIncremental` | `true` | So sánh bản sao lưu mới đã xác minh với bản trước; với `false`, giữ mọi bản sao lưu mới mà không so sánh |
| `export_format` | `compact` | `compact`, `terse` hoặc `verbose` |
| `show_sensitive` | `true` | Bao gồm giá trị nhạy cảm trong `.rsc` |
| `encrypt` | Trống | Mật khẩu dùng để mã hóa `.backup`; để trống nghĩa là không mã hóa |
| `encrypt_type` | `aes-sha256` | Thuật toán cố định; chỉ có trong tệp |
| `clear_dns_cache` | `true` | Xóa bộ nhớ đệm DNS trước khi sao lưu nhị phân |
| `clear_console_history` | `true` | Xóa lịch sử console trước khi sao lưu nhị phân |
| `BackupRoot` | `backups` | Thư mục gốc để lưu bản sao lưu |
| `UseNetFolder` | `false` | Yêu cầu một điểm gắn kết riêng trong chế độ hàng loạt |
| `MonthlyArchive` | `false` | Vô hiệu hóa lưu trữ vào kho (`false`) hoặc đặt ngày trong tháng từ `1` đến `28` |
| `LogLevel` | `2` | Mức `0`, `1`, `2` hoặc `3` |
| `MainLogPath` | Trống | Thư mục chỉ dành cho `main.log`; để trống nghĩa là `BackupRoot` hiện tại |
| `Login` | Trống | Tên đăng nhập chung được các trường DeviceList trống kế thừa; chỉ có trong tệp |
| `Password` | Trống | Mật khẩu chung được các trường DeviceList trống kế thừa; chỉ có trong tệp |

Với `Language=auto`, locale của hệ điều hành chọn ngôn ngữ giao diện và nhật ký.
Bản dịch bên ngoài dùng mã ngôn ngữ hai chữ cái của locale đó: ví dụ, `de_DE.UTF-8` yêu cầu `de.lang` bên cạnh script.
Nếu không có bản dịch phù hợp, tiếng Anh được sử dụng.

`MonthlyArchive` tuân theo quy tắc hơi khác: `false`/`no`/`0`/`off` vô hiệu hóa việc lưu trữ vào kho; `true`/`yes`/`1`/`on` có nghĩa là ngày đầu tiên của tháng; còn giá trị từ `2` đến `28` chọn ngày cần dùng.

Khi Trình chỉnh sửa cấu hình lưu tệp, nó ghi
`MonthlyArchive=false` hoặc con số đã chọn.

Các tham số Boolean chấp nhận `true`/`false`, `yes`/`no`, `1`/`0` và `on`/`off`
mà không phân biệt chữ hoa/chữ thường. Trình chỉnh sửa ghi `true`/`false`.

Các trường như `IgnoreOxiAccess`, `encrypt_type`, `SshPort`, `Login` và `Password` không xuất hiện trong Trình chỉnh sửa cấu hình.

Khi lưu tệp, trình chỉnh sửa ghi `IgnoreOxiAccess`, `encrypt_type` và `SshPort`.
Nó chỉ giữ lại `Login` và `Password` nếu các dòng đó đã có trong `option.cfg`, kể cả những dòng có giá trị trống.

Các trường `SshPort`, `Login` và `Password` có thể hữu ích khi tất cả thiết bị của bạn dùng cùng cổng SSH và cùng người dùng—cùng tên và mật khẩu. Trong trường hợp đó, mỗi mục trong `devicelist.cfg` chỉ cần hai giá trị: **tên** thiết bị và **địa chỉ IP** của thiết bị.

## Ví dụ không dọn dẹp hoặc xuất dữ liệu nhạy cảm

Đây là ví dụ về một chính sách đã chọn, **không phải danh sách giá trị mặc định của nhà sản xuất**:

```ini
Language=ru
SshPort=22
UseOxidized=false
IgnoreOxiAccess=true
OxidizedHome=
UseIdentityName=true
backup_type=both
UseIncremental=true
export_format=compact
show_sensitive=false
encrypt=
encrypt_type=aes-sha256
clear_dns_cache=false
clear_console_history=false
BackupRoot=backups
UseNetFolder=false
MonthlyArchive=false
LogLevel=2
MainLogPath=
```

19 khóa đầu tiên được hiển thị theo thứ tự ghi chuẩn hóa.
Mọi dòng `Login` và `Password` hiện có, tương thích sẽ được giữ lại sau chúng.

Các thiết lập bị thiếu dùng giá trị tích hợp, không dùng giá trị trong ví dụ bên cạnh.
Ví dụ, tệp chỉ chứa `Language=ru` không vô hiệu hóa việc dọn dẹp và không thay đổi `show_sensitive=true`.

## Đường dẫn

```ini
BackupRoot=backups
MainLogPath=logs
```

Các mục này có nghĩa là thư mục `backups` và `logs` bên cạnh script.
Đường dẫn tuyệt đối giữ nguyên ý nghĩa. `$HOME` và `~` không được khai triển
thành biến hoặc thư mục home.

Nếu thiếu `BackupRoot`, thư mục này sẽ được tạo trong khi thực thi nếu quyền cho phép.
Không được dùng thư mục gốc hệ thống tệp, `/`, làm nơi lưu trữ.
Đối với các thư mục hiện có, chương trình không tự động sửa chủ sở hữu hoặc quyền.

`MainLogPath` không trống phải chỉ tới một **thư mục hiện có và có thể ghi**.
Việc tạo chính tệp `main.log` được hoãn cho tới khi mục nhật ký đầu tiên được ghi;
điều này không tạo thư mục mẹ của tệp. Nếu không thể ghi nhật ký, quá trình
sao lưu vẫn tiếp tục kèm cảnh báo. Thiết lập này không di chuyển nhật ký thiết bị.

<a id="network-storage"></a>
## Mạng và nơi lưu trữ riêng

`UseNetFolder=true` áp dụng trong chế độ hàng loạt. Đường dẫn phải thuộc phạm vi của một mục gắn kết
khác với mục dành cho `/`. Nơi lưu trữ riêng có thể là nơi lưu trữ mạng,
ổ đĩa cục bộ hoặc bind mount; tên tùy chọn không giới hạn loại hệ thống tệp.

Một thư mục thông thường trên cùng hệ thống tệp gốc không đáp ứng yêu cầu này.
Script kiểm tra khả năng truy cập và trạng thái gắn kết, nhưng không gọi `mount`, `umount`
hay `sudo`, và không âm thầm chuyển sang nơi lưu trữ cục bộ.

## Các tham số liên quan

Với `UseIncremental=false`, script không so sánh bản sao lưu mới với bản trước và giữ mọi tệp mới đã được tạo và xác minh thành công.
Thiết lập này không ảnh hưởng đến chính việc tạo bản sao lưu hay việc lưu trữ vào kho hằng tháng.
Mặc định là `UseIncremental=true`. Nếu `option.cfg` của bạn chưa chứa tham số này, cơ chế so sánh vẫn được bật.

`backup_type=configuration` không dùng mã hóa bản sao lưu nhị phân
hoặc các thao tác dọn dẹp trước khi sao lưu nhị phân. `backup_type=binary` không dùng `export_format`
hoặc `show_sensitive`. `UseOxidized=false` không dùng `OxidizedHome`.

Với `UseIdentityName=true`, việc không đọc được Identity sẽ không được thay thế
bằng `--device-name` hay tên từ DeviceList. Để dùng tên đã chỉ định, hãy vô hiệu hóa
`UseIdentityName`: xem [quy tắc đặt tên](DEVICES.md#tên-thiết-bị).

Với `MonthlyArchive=true`, việc lưu trữ vào kho chạy khi script khởi động vào ngày đã chọn trong tháng,
theo giờ địa phương của máy chủ. Thời điểm trong ngày không quan trọng.
Nếu script không chạy vào ngày đó, lần lưu trữ bị bỏ lỡ sẽ không được thực hiện bù.

[BACKUPS.md](BACKUPS.md#kho-lưu-trữ-hằng-tháng) giải thích những tệp nào được đưa vào kho lưu trữ, kho được tạo ở đâu và được đặt tên như thế nào.
Khoảng dữ liệu, mốc giới hạn và các lần bị bỏ lỡ cũng được định nghĩa trong
[BACKUPS.md](BACKUPS.md#kho-lưu-trữ-hằng-tháng).

Cấu hình có thể chứa bí mật. Hãy hạn chế quyền truy cập vào tệp và không commit
tệp vào kho mã công khai: [SECURITY.md](SECURITY.md).
