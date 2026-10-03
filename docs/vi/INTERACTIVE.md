# Giao diện tương tác

[Mục lục](../README_VI.md)

## Trình đơn chính

Trình đơn chính cho phép bạn cấu hình script, tạo bản sao lưu, chuẩn bị danh sách thiết bị hoặc mở phần trợ giúp tích hợp. Để mở, hãy chạy:

```bash
mikrotik-backup.sh -i
```

| Mục | Nội dung được mở hoặc thực hiện |
|---|---|
| `1` | BackUP Master để làm việc với một thiết bị |
| `2` | Sao lưu hàng loạt bằng danh sách thiết bị |
| `3` | Trình chỉnh sửa cấu hình để tạo hoặc thay đổi `option.cfg` |
| `4` | Tài liệu tùy chọn CLI |
| `5` | Hướng dẫn sử dụng script |
| `6` | Thoát về console |

Mục `2` xuất hiện khi `devicelist.cfg` chứa ít nhất một mục đủ điều kiện. Nếu danh sách chưa tồn tại hoặc không chứa thiết bị phù hợp, mục này bị ẩn. Số của các mục khác không thay đổi.

Sau khi sao lưu hàng loạt, kết quả được hiển thị và script đưa bạn trở về console.

*(Lưu ý: Chạy script không kèm tùy chọn không mở trình đơn chính. Nếu thiếu `option.cfg` hoặc tệp không chứa thiết lập dùng được, Trình chỉnh sửa cấu hình sẽ mở; nếu đã có thiết lập chuẩn bị sẵn, script tiếp tục sao lưu hàng loạt.)*

<br />

## Điều khiển

Di chuyển giữa các mục bằng phím mũi tên **Up** và **Down**, rồi chọn một mục bằng **Enter**. Nếu một hành động có số bên cạnh, bạn cũng có thể chọn bằng phím số tương ứng.

Trong trình chỉnh sửa và BackUP Master, phần mô tả của trường đang chọn xuất hiện phía trên danh sách. Nếu mọi hàng không vừa cửa sổ terminal, danh sách sẽ cuộn khi bạn di chuyển bằng phím mũi tên. Tiêu đề và phần mô tả vẫn hiển thị, còn hàng được chọn luôn nằm trong cửa sổ.

Các hành động lưu, thực thi và thoát nằm ở cuối cùng danh sách đó. Những hàng bị làm mờ không dùng được với thiết lập đã chọn và sẽ bị bỏ qua khi điều hướng.

Cần có terminal và tiện ích `stty`. Cả đầu vào chuẩn và đầu ra chuẩn đều phải được kết nối với terminal. Các màn hình chính yêu cầu chiều rộng tối thiểu 46 cột; phần hướng dẫn tích hợp yêu cầu 80 cột. Nếu cửa sổ quá nhỏ, script báo lỗi `31`; hãy phóng to cửa sổ rồi chạy lại.

<br />

## Trình chỉnh sửa cấu hình

Mở trình chỉnh sửa qua mục `3` trong trình đơn chính hoặc trực tiếp bằng:

```bash
mikrotik-backup.sh -e
```

Nếu `option.cfg` đã được chuẩn bị, biểu mẫu sẽ được điền bằng thiết lập của bạn. Nếu tệp chưa tồn tại, các giá trị mặc định được dùng.

Trình chỉnh sửa cho phép bạn chọn ngôn ngữ, nguồn danh sách thiết bị, thiết lập sao lưu, nơi lưu trữ, lưu trữ vào kho hằng tháng và ghi nhật ký. Các thiết lập cùng giá trị được chấp nhận được mô tả trong [OPTIONS.md](OPTIONS.md).

### Thay đổi thiết lập

Thay đổi công tắc Yes/No, loại sao lưu, định dạng xuất và mức nhật ký bằng cách nhấn **Enter** trên hàng tương ứng. Chọn đường dẫn hoặc ngày lưu trữ hằng tháng sẽ mở lời nhắc nhập giá trị.

Trường “Use incremental backups” (`UseIncremental`) nằm ngay sau loại sao lưu. “Yes” bật so sánh; “No” giữ mọi bản sao lưu mới hợp lệ mà không so sánh với bản trước.

Đối với lưu trữ vào kho hằng tháng, nhập `false` để vô hiệu hóa hoặc một số từ `1` đến `28`. Biểu mẫu hiển thị trạng thái bị vô hiệu hóa là “No” và trạng thái được bật là ngày đã chọn trong tháng.

Các trường không áp dụng cho chế độ đã chọn sẽ bị làm mờ. Ví dụ, khi chỉ chọn `.rsc`, mã hóa bản sao lưu nhị phân và các thao tác dọn dẹp trước đó sẽ không dùng được; khi chỉ chọn `.backup`, các thiết lập xuất văn bản sẽ không dùng được. Việc chuyển chế độ đặt lại các thiết lập không áp dụng về giá trị mặc định.

Mật khẩu mã hóa được nhập và hiển thị dưới dạng dấu hoa thị.

### Lưu và hủy

Chọn các thiết lập cần thiết → di chuyển tới “Save” → nhấn **Enter**. Các thiết lập đã chọn được dùng để tạo hoặc ghi đè `option.cfg`.

Cho tới khi bạn lưu, các thay đổi chỉ tồn tại trong bộ nhớ. “Cancel” giữ nguyên tệp hiện có. Nếu bạn đã thay đổi bất cứ điều gì, trình chỉnh sửa yêu cầu xác nhận rằng bạn muốn bỏ các thay đổi đó.

Trình chỉnh sửa được mở từ trình đơn chính sẽ quay lại đó. Khi bạn chạy riêng trình chỉnh sửa bằng `-e`, việc đóng nó sẽ đưa bạn về console.

*(Lưu ý: `SshPort`, `IgnoreOxiAccess`, `encrypt_type`, `Login` và `Password` không hiển thị trong biểu mẫu. Các thiết lập và quy tắc giữ lại chúng được mô tả trong [OPTIONS.md](OPTIONS.md).)*

### Chọn ngôn ngữ

Trên hàng ngôn ngữ, mỗi lần nhấn **Enter** sẽ chọn tùy chọn tiếp theo:

```text
auto → ru → en → các ngôn ngữ bên ngoài được phát hiện theo thứ tự bảng chữ cái → auto
```

Ngôn ngữ biểu mẫu thay đổi ngay để bạn có thể xem trước. “Save” ghi ngôn ngữ đã chọn vào `option.cfg`; thao tác hủy khôi phục ngôn ngữ giao diện trước đó. Nếu `--language` được chỉ định rõ khi khởi động, tùy chọn đó có hiệu lực trở lại sau khi bạn rời trình chỉnh sửa.

Cách kết nối bản dịch bên ngoài được mô tả trong [LOCALIZATION.md](LOCALIZATION.md).

<br />

## BackUP Master

BackUP Master cho phép bạn điền thiết lập cho một thiết bị, tạo bản sao lưu, lưu thiết bị vào danh sách hoặc chuẩn bị lệnh để chạy từ console.

Chọn mục `1` trong trình đơn chính hoặc chạy:

```bash
mikrotik-backup.sh -b
```

Khác với Trình chỉnh sửa cấu hình, BackUP Master không điền các trường thông thường từ `option.cfg`. Giá trị của chúng đến từ giá trị mặc định tích hợp và các tùy chọn được truyền rõ qua CLI. `UseIncremental` là ngoại lệ: giá trị đến từ tệp tùy chọn hoặc mặc định là `true` khi không có thiết lập đó.

Các mục hiện có trong `devicelist.cfg` cũng không được nạp vào biểu mẫu. Bạn tự điền tên, địa chỉ, tên đăng nhập và mật khẩu cho thiết bị đã chọn.

### Các trường của BackUP Master

Các trường xuất hiện theo thứ tự sau. Đây là tên của chúng trong giao diện tiếng Anh:

| Trường | Mục đích |
|---|---|
| Device name | Tên dùng trong danh sách thiết bị và cho bản sao lưu khi việc lấy RouterOS Identity bị vô hiệu hóa |
| IP address | Địa chỉ IP hoặc tên DNS của thiết bị |
| User | Người dùng trên thiết bị RouterOS |
| Password | Mật khẩu thiết bị RouterOS |
| SSH port | Cổng kết nối; mặc định là `22` |
| Backup type | Cấu hình `.rsc`, bản sao lưu nhị phân `.backup` hoặc cả hai định dạng |
| Use incremental backups | So sánh bản sao lưu mới với bản trước hoặc giữ lại mà không so sánh |
| Export format | `compact`, `terse` hoặc `verbose` |
| Sensitive data | Bao gồm giá trị nhạy cảm trong dữ liệu xuất văn bản |
| Encryption password | Mã hóa bản sao lưu nhị phân; giá trị trống sẽ vô hiệu hóa mã hóa |
| Clear DNS cache | Xóa bộ nhớ đệm DNS trước khi tạo bản sao lưu nhị phân |
| Clear console history | Xóa lịch sử console trước khi tạo bản sao lưu nhị phân |
| Backup directory | Thư mục lưu tệp |
| This is a network directory | Giá trị `UseNetFolder`; việc xác minh điểm gắn kết áp dụng trong chế độ hàng loạt |
| Use RouterOS Identity | Lấy tên từ thiết bị thay vì dùng tên nhập trong biểu mẫu |

Công tắc, loại sao lưu và định dạng xuất được thay đổi bằng **Enter**; các giá trị khác được nhập vào trường tương ứng. Cả hai mật khẩu đều được che bằng dấu hoa thị.

**Xin lưu ý!!!**
Dữ liệu nhạy cảm trong phần xuất văn bản, việc xóa bộ nhớ đệm DNS và xóa lịch sử console trước khi sao lưu nhị phân đều được bật theo mặc định. Hãy chọn thiết lập cần dùng trước khi thực hiện sao lưu.

BackUP Master không có trường cho `MonthlyArchive`, `LogLevel` hoặc `MainLogPath`. Lưu trữ vào kho hằng tháng bị vô hiệu hóa khi thực hiện sao lưu qua BackUP Master, còn thiết lập ghi nhật ký đến từ `option.cfg` cùng mọi tùy chọn CLI đã truyền cho lần chạy.

### 1. Execute backup

Điền địa chỉ, tên đăng nhập và mật khẩu; kiểm tra cổng và thiết lập sao lưu → chọn “1. Execute backup.”

Khi bật việc lấy RouterOS Identity, tên sao lưu được lấy từ thiết bị. Khi tính năng này bị vô hiệu hóa, bạn phải điền trường “Device name”.

Quá trình sao lưu một thiết bị bắt đầu. Khi hoàn tất, kết quả và mã tương ứng được hiển thị, rồi script đưa bạn trở về console. Script không quay lại biểu mẫu BackUP Master, dù sao lưu thành công hay thất bại.

Vị trí tệp và quy tắc lưu giữ được mô tả trong [BACKUPS.md](BACKUPS.md); thông báo tiến trình được giải thích trong [LOGGING.md](LOGGING.md).

### 2. Save device to devicelist.cfg

Cần có tên thiết bị, địa chỉ, tên đăng nhập, mật khẩu và cổng SSH để lưu. Cho tới khi điền đủ mọi trường bắt buộc, hành động tương ứng vẫn không dùng được.

BackUP Master tạo tệp, thêm mục mới hoặc cập nhật mục hiện có cùng tên. Nếu các mục xung đột hoặc việc lưu thất bại, danh sách trước đó vẫn không thay đổi. Biểu mẫu vẫn mở sau khi lưu.

**Chỉ dữ liệu thiết bị được lưu vào `devicelist.cfg`.** Thiết lập sao lưu từ biểu mẫu không được ghi vào `option.cfg`, và hành động này không bắt đầu sao lưu.

*(Lưu ý: Cổng `22` được lưu dưới dạng trường trống. Trong lần chạy hàng loạt sau này, mục đó dùng `SshPort` từ thiết lập script. Cổng không chuẩn được ghi rõ.)*

Định dạng danh sách và quy tắc cập nhật được mô tả trong [DEVICES.md](DEVICES.md).

### 3. Copy console command

BackUP Master dựng lệnh khởi chạy từ biểu mẫu đã điền và gửi lệnh tới clipboard. Không có quá trình sao lưu nào bắt đầu, và BackUP Master kết thúc bằng cách trở về console.

Tính năng này yêu cầu GNU `base64` hỗ trợ `--wrap=0` và terminal hỗ trợ OSC 52. Nếu làm việc qua terminal multiplexer, nó cũng phải chuyển tiếp lệnh. Nếu không hỗ trợ truyền vào clipboard, lệnh sẽ không được in dưới dạng văn bản thuần trên màn hình.

Các tham số khớp với giá trị tích hợp có thể bị lược khỏi lệnh. Khi bạn chạy lệnh sau này, thiết lập từ `option.cfg` vẫn áp dụng, vì vậy kết quả có thể khác với việc thực hiện sao lưu trực tiếp qua BackUP Master.

Thiết lập `UseIncremental` không được đưa vào lệnh: nó không có tùy chọn CLI riêng. Khi lệnh đã sao chép được chạy, giá trị đến từ `option.cfg` hoặc từ giá trị mặc định.

*(Lưu ý: Lệnh được đưa vào clipboard chứa mật khẩu. Hãy nhớ điều này khi dùng lịch sử clipboard và khi dán lệnh vào shell. Xem [SECURITY.md](SECURITY.md) để biết chi tiết.)*

### 0. Return to Main Menu

Kết quả phụ thuộc vào cách bạn mở BackUP Master:

| Cách mở | Nơi quay về |
|---|---|
| Từ trình đơn chính bằng `-i` | Trình đơn chính |
| Chạy riêng bằng `-b` | Console |

Các giá trị biểu mẫu chưa lưu sẽ bị loại bỏ. Mục đã lưu trong `devicelist.cfg` vẫn còn đó.

<br />

## Trợ giúp và hướng dẫn

Mục `4` trong trình đơn chính mở tài liệu tùy chọn dòng lệnh, còn mục `5` mở hướng dẫn ngắn về cách dùng script.

Nếu văn bản không vừa theo chiều dọc, nó được chia thành các trang. Di chuyển giữa chúng bằng **PageUp / PageDown**; số trang hiện tại được hiển thị trên màn hình.

Mục `0` quay lại trình đơn chính và mục `6` thoát script. Bạn có thể chọn các hành động này bằng phím mũi tên và **Enter**, hoặc bằng phím số tương ứng.

Trợ giúp CLI tương tự cũng có thể mở trực tiếp từ console:

```bash
mikrotik-backup.sh -h
```
