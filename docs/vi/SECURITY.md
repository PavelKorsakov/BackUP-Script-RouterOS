# Bảo mật

[Mục lục](../README_VI.md)

## Tài khoản

Script không yêu cầu quyền **root**. Người dùng thông thường chỉ cần quyền truy cập các tệp thiết lập và quyền ghi vào nơi lưu trữ cùng nhật ký đã chọn.

Việc tạo người dùng **bsmt** chuyên dụng và cấu hình script chạy dưới tài khoản đó được mô tả trong [INSTALL.md](INSTALL.md#chạy-script-tự-động).

Trên thiết bị RouterOS, bạn cũng nên tạo người dùng sao lưu chuyên dụng và giới hạn đăng nhập của người dùng đó theo địa chỉ IP của máy chủ chạy script. Quyền của tài khoản phải cho phép các thao tác đã chọn: lấy cấu hình, tạo và tải xuống bản sao lưu, xóa tệp tạm và thực hiện mọi thao tác dọn dẹp đã bật.

<br />

## Kết nối tới RouterOS

Script kết nối qua SSH bằng xác thực mật khẩu. Khóa SSH và agent không được sử dụng. Tệp được lấy bằng giao thức SCP cũ, tức `scp -O`.

Script dùng thiết lập kết nối riêng. Nó không đọc `~/.ssh/config` của người dùng hay cấu hình SSH hệ thống vì client được khởi động với `-F /dev/null`. Agent, X11 và chuyển tiếp cổng đều bị vô hiệu hóa.

**Xin lưu ý!!! Việc xác minh khóa máy chủ bị vô hiệu hóa.**

Cấu hình hiện tại dùng các thiết lập sau:

```text
StrictHostKeyChecking=no
UserKnownHostsFile=/dev/null
GlobalKnownHostsFile=/dev/null
CheckHostIP=no
UpdateHostKeys=no
```

Các tệp `known_hosts` thông thường không được đọc hay thay đổi. Do đó, script không xác minh máy chủ phản hồi có đúng là thiết bị dự kiến hay là một máy giả mạo. Hãy tính đến điều này khi bố trí quyền truy cập mạng tới router.

<br />

<a id="secrets"></a>
## Mật khẩu khi khởi động script

Mật khẩu được truyền qua `--password` hoặc `-p=` trở thành một phần của lệnh khởi chạy. Nó có thể hiển thị trong các đối số tiến trình và được lưu vào lịch sử shell. Điều tương tự áp dụng cho mật khẩu mã hóa được truyền qua `--encrypt`.

### Nhập mật khẩu qua BackUP Master

Để tránh đặt mật khẩu SSH trên dòng lệnh, hãy khởi động BackUP Master:

```bash
mikrotik-backup.sh -b
```

Điền thông tin xác thực thiết bị vào biểu mẫu rồi chọn hành động cần thiết. Cả hai mật khẩu được hiển thị bằng dấu hoa thị, và các giá trị nhập vào biểu mẫu không đi vào lịch sử lệnh shell.

Khi kết nối, chính script truyền mật khẩu SSH cho `sshpass` qua một bộ mô tả tệp (`-d`), không qua đối số `sshpass -p` hay biến môi trường `SSHPASS`.

### Mật khẩu mã hóa .backup

Mật khẩu mã hóa được đưa vào lệnh RouterOS truyền cho tiến trình con `ssh`. Vì vậy, người dùng trên máy chủ có đủ quyền kiểm tra đối số tiến trình có thể nhìn thấy mật khẩu trong lúc bản sao lưu nhị phân được tạo.

Nhập mật khẩu qua BackUP Master hoặc lưu trong `option.cfg` không thay đổi cách truyền mật khẩu. Mã hóa tệp không bảo vệ dữ liệu khỏi chính quản trị viên của máy chủ sao lưu.

### Sao chép lệnh console

Hành động “Copy console command” trong BackUP Master gửi một lệnh chứa thông tin xác thực kết nối—và nếu đã đặt cho bản sao lưu nhị phân, cả mật khẩu mã hóa—tới clipboard.

Hãy nhớ điều này khi dùng lịch sử clipboard và khi dán lệnh vào shell. Việc mật khẩu được che bằng dấu hoa thị trong biểu mẫu không có nghĩa là nó cũng được che trong lệnh đã sao chép.

<br />

## Các tệp chứa dữ liệu nhạy cảm

| Tệp | Nội dung có thể chứa |
|---|---|
| `devicelist.cfg` | Địa chỉ thiết bị, tên đăng nhập và mật khẩu SSH ở dạng văn bản thuần |
| `option.cfg` | Giá trị `Login` và `Password` dùng chung cùng mật khẩu mã hóa `encrypt` |
| `.rsc` và `.backup` | Cấu hình thiết bị, mật khẩu và dữ liệu nhạy cảm khác |
| ZIP hằng tháng | Cùng các bản sao lưu và nhật ký đó được gom vào một kho lưu trữ |

Đừng đặt tệp thiết lập đang dùng hoặc bản sao lưu trong kho mã công khai hay thư mục có thể truy cập công khai.

### Dữ liệu nhạy cảm trong tệp .rsc

Theo mặc định, `show_sensitive=true`, vì vậy dữ liệu xuất văn bản bao gồm các giá trị nhạy cảm. Để vô hiệu hóa, hãy đặt giá trị sau trong `option.cfg`:

```ini
show_sensitive=false
```

Ngay cả khi đó, tệp vẫn là cấu hình thiết bị của bạn: địa chỉ, cấu trúc mạng, chú thích và những chuỗi khác do người dùng cung cấp không biến mất khỏi tệp.

### Mã hóa bản sao lưu nhị phân

Theo mặc định, `encrypt` trống và `.backup` được lưu không mã hóa. Để bật mã hóa, hãy đặt mật khẩu trong tệp tùy chọn hoặc trường tương ứng của BackUP Master:

```ini
encrypt=MySuperPassword
```

Thuật toán AES-SHA256 được sử dụng. Nó **chỉ mã hóa `.backup`**, không mã hóa `.rsc`, `option.cfg`, danh sách thiết bị, nhật ký hay chính tệp ZIP. Vì vậy, quyền truy cập kho lưu trữ hằng tháng phải được hạn chế cẩn thận như quyền truy cập các tệp bên trong.

<br />

## Quyền đối với tệp và nơi lưu trữ

Script chạy với `umask 077`. Các thư mục lưu trữ cục bộ do script tạo nhận chế độ `0700`, còn `option.cfg` và `devicelist.cfg` được ghi với chế độ `0600` khi lưu bằng chương trình.

Chủ sở hữu và quyền của những thư mục lưu trữ hiện có do quản trị viên tạo không được tự động thay đổi. Nếu bạn chuẩn bị thư mục thủ công, bạn phải tự cấu hình quyền truy cập.

Thư mục kho lưu trữ hằng tháng cục bộ, `archive/`, phải có chế độ `0700` và thuộc về người dùng chạy script. Yêu cầu này cũng áp dụng cho thư mục hiện có. Các tệp lưu trữ cục bộ do script tạo có chế độ `0600`.

Trong chế độ hàng loạt, khi dùng nơi lưu trữ mạng đã xác minh với `UseNetFolder=true`, máy chủ NAS có thể quyết định chủ sở hữu và quyền của đối tượng lưu trữ. Chỉ riêng sự khác biệt so với các giá trị cục bộ không làm dừng việc lưu trữ vào kho. Hãy cấu hình quyền truy cập nơi lưu trữ mạng thông qua hệ điều hành và NAS.

Ví dụ về cách chuẩn bị thư mục và cấp quyền cho người dùng **bsmt** được cung cấp trong [INSTALL.md](INSTALL.md).

*(Lưu ý: Script đọc cấu hình, danh sách thiết bị, bản dịch và mọi thiết lập Oxidized mà nó dùng dưới dạng dữ liệu; script không thực thi chúng như shell script.)*

<br />

## Những thay đổi được thực hiện trên thiết bị

Theo mặc định, bộ nhớ đệm DNS và lịch sử console của RouterOS bị xóa trước khi tạo bản sao lưu nhị phân. Nếu không cần các hành động này, hãy vô hiệu hóa chúng trong `option.cfg`:

```ini
clear_dns_cache=false
clear_console_history=false
```

Bạn có thể vô hiệu hóa các tính năng tương tự qua Trình chỉnh sửa cấu hình, BackUP Master hoặc tùy chọn CLI tương ứng. Các thao tác dọn dẹp này không được thực hiện khi chỉ lấy `.rsc`.

<br />

## Nhật ký và chia sẻ thông tin chẩn đoán

Mức chi tiết `LogLevel=3` thêm thông tin về các giai đoạn xử lý; nó không xuất mật khẩu hay toàn bộ lệnh kết nối.

Chẩn đoán SSH đã xử lý sẽ che chính xác các giá trị đã biết của địa chỉ, tên đăng nhập, mật khẩu SSH và mật khẩu mã hóa. Điều này không làm sạch nội dung bản sao lưu và không bảo đảm loại bỏ mọi bí mật khỏi văn bản tùy ý.

Các tệp tạm chứa chẩn đoán chưa xử lý có thể bao gồm dữ liệu nhạy cảm. Chúng được tạo với chế độ `0600` và bị xóa trong quá trình dọn dẹp thông thường.

Trước khi gửi nhật ký, ảnh chụp màn hình hoặc đầu ra lệnh cho người khác, hãy kiểm tra nội dung. Đầu ra đầy đủ từ `devicelist.cfg`, danh sách tiến trình hoặc nội dung clipboard có thể làm lộ dữ liệu không xuất hiện trong nhật ký thông thường.

Để biết thêm về mục nhật ký, hãy xem [LOGGING.md](LOGGING.md); để được trợ giúp điều tra lỗi, hãy xem [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

<br />

## Các lần chạy đồng thời

Các lần chạy của cùng người dùng với cùng `BackupRoot` dùng cơ chế khóa đồng bộ:

| Các lần chạy đồng thời | Điều gì xảy ra |
|---|---|
| Một lần chạy hàng loạt và một lần chạy hàng loạt hoặc một thiết bị khác | Lần chạy thứ hai không lấy được khóa |
| Hai lần chạy một thiết bị cho cùng thiết bị | Lần chạy thứ hai không lấy được khóa |
| Các lần chạy một thiết bị cho những thiết bị khác nhau | Chúng có thể chạy đồng thời |

Nếu khóa đang bận, script thoát với mã `32`. Các thư mục gốc lưu trữ khác nhau không được phối hợp như một vùng lưu trữ duy nhất khi thư mục này nằm lồng trong thư mục kia.

Các tệp khóa được giữ trong `/tmp/mikrotik-backup-${UID}/` và vẫn còn sau khi script kết thúc. Chỉ riêng sự hiện diện của chúng không có nghĩa là script vẫn đang chạy.

**Đừng xóa các tệp này để “xóa một khóa bị treo”.** Khóa gắn với một bộ mô tả tệp đang mở của tiến trình, không gắn với sự tồn tại của tệp. Các khóa này cũng không bảo vệ dữ liệu khỏi một chương trình không liên quan sửa đổi dữ liệu trực tiếp.

<br />

## Kiểm thử khôi phục

Việc xác minh checksum của script và lấy thành công tệp sao lưu không thể thay thế việc kiểm thử khôi phục.

Bản thân script không khôi phục RouterOS. Bạn phải xác minh riêng rằng bản sao lưu có thể dùng trên thiết bị phù hợp và quyết định thời gian lưu giữ. Xem [BACKUPS.md](BACKUPS.md) để biết thêm thông tin.
