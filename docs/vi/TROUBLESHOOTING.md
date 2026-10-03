# Khắc phục sự cố

[Mục lục](../README_VI.md)

## Bắt đầu từ đâu

Nếu quá trình sao lưu không bắt đầu hoặc kết thúc với lỗi, trước hết hãy kiểm tra nhật ký. `main.log` chứa các giai đoạn tổng thể của lần chạy, còn chi tiết sao lưu một thiết bị cụ thể được ghi vào nhật ký thiết bị riêng.

Tìm các mục được đánh dấu `[ER]` và mã lỗi. Các mã được giải thích [bên dưới](#result-codes), còn vị trí nhật ký được mô tả trong [LOGGING.md](LOGGING.md).

Dùng các lệnh sau để hiển thị phiên bản script đã cài và tài liệu tùy chọn:

```bash
mikrotik-backup.sh --version
mikrotik-backup.sh --help
```

Để lặp lại một lần chạy hàng loạt đã cấu hình với đầu ra chi tiết:

```bash
mikrotik-backup.sh --log-level=3
printf 'Exit code: %s\n' "$?"
```

Lệnh thứ hai hiển thị kết quả của lần chạy đã hoàn tất. Nó không thay đổi mức ghi nhật ký trong `option.cfg`.

<br />

## Script không bắt đầu sao lưu

### Trình chỉnh sửa mở thay vì sao lưu

Khi script được khởi động không kèm tùy chọn, điều này có nghĩa là `option.cfg` không có trong thư mục script hoặc không chứa thiết lập dùng được. Tệp trống, chỉ có chú thích hoặc chỉ có thiết lập không xác định đều không làm thay đổi kết quả này.

Mở Trình chỉnh sửa cấu hình, chọn các thiết lập cần thiết, lưu tệp rồi chạy lại script:

```bash
mikrotik-backup.sh -e
```

Lưu một thiết bị qua BackUP Master sẽ tạo `devicelist.cfg`, nhưng không thay thế việc chuẩn bị `option.cfg`.

*(Lưu ý: Nếu một lần chạy như vậy do bộ lập lịch khởi động, trình chỉnh sửa không thể mở và script thoát với mã `31`. Phải chuẩn bị trước các thiết lập cho lần chạy tự động.)*

### Lỗi tùy chọn, mã 12

Kiểm tra tên tùy chọn, giá trị và tổ hợp hành động. Nguyên nhân có thể gồm tùy chọn không xác định, giá trị trống, yêu cầu nhiều hành động khác nhau cùng lúc hoặc thông tin xác thực chưa đầy đủ cho kết nối một thiết bị.

Một lần chạy CLI cho một thiết bị cần địa chỉ, tên đăng nhập và mật khẩu. Thông tin xác thực bị thiếu không được lấy từ `option.cfg` để điền vào.

Tùy chọn kết nối dạng ngắn phải dùng dấu `=`: `-a=`, `-u=` và `-p=`. Lưu ý rằng `-p` chỉ định mật khẩu; hãy dùng `--port` cho cổng SSH.

Mọi tùy chọn được chấp nhận và ví dụ được liệt kê trong [CLI.md](CLI.md).

### Không thể đọc option.cfg, mã 21

Hãy bảo đảm `option.cfg` là tệp thông thường mà người dùng chạy script có thể đọc. Liên kết tượng trưng có thể đọc được trỏ tới một tệp như vậy cũng được phép.

Tệp không tồn tại và tệp không đọc được là hai tình huống khác nhau. Nếu tệp tồn tại nhưng không thể đọc, script không tiếp tục bằng các thiết lập mặc định.

### Thiếu phần phụ thuộc, mã 30

Kiểm tra các tiện ích chính bằng:

```bash
command -v ssh scp sshpass timeout sleep sha256sum realpath flock
```

Vận hành hàng loạt với `UseNetFolder=true` còn yêu cầu `findmnt`. Vào ngày lưu trữ vào kho hằng tháng, cần `zip`, `unzip` và GNU `mv`. Việc sao chép lệnh console từ BackUP Master yêu cầu GNU `base64` hỗ trợ `--wrap=0`.

**Chỉ cài một tiện ích là chưa đủ.** OpenSSH đã cài phải hỗ trợ các tùy chọn đang dùng và `scp -O`; GNU `timeout` phải hỗ trợ `--signal` và `--kill-after`.

Danh sách phần phụ thuộc đầy đủ và lệnh cài đặt nằm trong [INSTALL.md](INSTALL.md#phần-phụ-thuộc).

### Trình đơn không mở, mã 31

Trình đơn, trình chỉnh sửa và BackUP Master yêu cầu terminal cùng tiện ích `stty` hoạt động đúng. Đừng khởi động chúng qua pipe hoặc khi đầu vào hay đầu ra chuẩn bị chuyển hướng.

Nếu thông báo cho biết terminal quá nhỏ, hãy phóng to cửa sổ. Các màn hình chính cần chiều rộng tối thiểu 46 cột, còn phần hướng dẫn tích hợp cần 80 cột. Danh sách dài trong trình chỉnh sửa và BackUP Master cuộn bằng phím mũi tên; toàn bộ biểu mẫu không cần vừa màn hình cùng lúc.

Các nút điều khiển giao diện được mô tả trong [INTERACTIVE.md](INTERACTIVE.md).

<br />

## Danh sách thiết bị không nạp được

### Tệp devicelist.cfg, mã 22 và 23

Kiểm tra vị trí tệp và quyền truy cập. `devicelist.cfg` phải nằm bên cạnh `mikrotik-backup.sh`, bất kể bạn khởi động script từ thư mục nào.

Các trường được phân tách bằng ký tự TAB thực sự, không phải dấu cách. Một thiết bị phải có tên, địa chỉ, tên đăng nhập, mật khẩu và cổng SSH hợp lệ. Thông tin xác thực dùng chung có thể đến từ `option.cfg` khi trường tương ứng trong mục thiết bị để trống.

Mục không hợp lệ bị bỏ qua kèm cảnh báo. Nếu không còn thiết bị đủ điều kiện, sẽ không có gì để sao lưu và script thoát với lỗi danh sách.

Đồng thời hãy kiểm tra kết nối trùng lặp và các thiết bị khác nhau có cùng tên. Định dạng tệp, cách kế thừa thông tin xác thực và quy tắc xử lý trùng lặp được mô tả trong [DEVICES.md](DEVICES.md).

### Nhập từ Oxidized, mã 24 và 25

Mã `24` có nghĩa là không đọc được tệp `config` hoặc `router.db` trong `OxidizedHome`. Mã `25` liên quan đến nội dung của chúng: lược đồ không được hỗ trợ, dữ liệu không hợp lệ hoặc không có thiết bị MikroTik đủ điều kiện.

Kiểm tra đường dẫn, quyền truy cập cả hai tệp, nguồn `csv`, dấu phân cách, ánh xạ cột và định nghĩa mẫu `routeros`. Dữ liệu được đọc cụ thể từ `<OxidizedHome>/router.db`; thiết lập `source.csv.file` của Oxidized không thay đổi đường dẫn đó.

Với `IgnoreOxiAccess=true`, script có thể tiếp tục bằng danh sách đủ điều kiện trước đó. Tuy vậy, lỗi nhập vẫn được giữ trong kết quả lần chạy. Với `false`, danh sách cũ không được dùng cho lần chạy đó.

Cấu hình nhập được mô tả trong [DEVICES.md](DEVICES.md#nhập-từ-oxidized).

<br />

## Nơi lưu trữ và khóa đồng bộ

### Khóa đang bận, mã 32

Kiểm tra xem tác vụ khác có đang dùng cùng thư mục sao lưu hay không. Với các lần chạy của một người dùng, sao lưu hàng loạt xung đột với mọi sao lưu khác dùng cùng `BackupRoot`. Hai lần chạy một thiết bị cho cùng thiết bị cũng không thể chạy đồng thời trong nơi lưu trữ đó.

Hãy chờ tác vụ đang hoạt động hoàn tất rồi chạy lại script.

**Đừng xóa tệp khóa để “giải phóng” nơi lưu trữ.** Chúng vẫn còn sau khi script kết thúc; chính tiến trình giữ khóa. Sự hiện diện của tệp trong `/tmp/mikrotik-backup-${UID}/` không có nghĩa là khóa đang bận.

### Không có quyền truy cập thư mục

Kiểm tra đường dẫn `BackupRoot`, quyền người dùng, dung lượng trống và khả năng truy cập chính thiết bị lưu trữ. Đường dẫn tương đối được phân giải từ thư mục script. Không thể dùng thư mục gốc hệ thống tệp, `/`, để lưu bản sao lưu.

Nếu trước đây script chạy bằng root và giờ chạy bằng **bsmt**, người dùng đó có thể không truy cập được thư mục và tệp cũ. Cách chuẩn bị quyền được mô tả trong [INSTALL.md](INSTALL.md#chạy-script-tự-động).

Vận hành hàng loạt với `UseNetFolder=true` yêu cầu điểm gắn kết riêng. Kiểm tra bằng:

```bash
findmnt -T /mnt/backup/mikrotik
findmnt -T /
```

Thay đường dẫn đầu tiên bằng đường dẫn của bạn. Nếu cả hai đường dẫn thuộc cùng một mục gắn kết, thư mục thông thường trên hệ thống tệp gốc không đáp ứng `UseNetFolder=true`. Script không tự gắn kết nơi lưu trữ.

Mã `64` có nghĩa là thư mục thiết bị hoặc kho lưu trữ của nó gặp lỗi trong khi nơi lưu trữ dùng chung vẫn truy cập được. Việc xử lý các thiết bị khác có thể tiếp tục. Mã `65` có nghĩa là nơi lưu trữ dùng chung đã bị mất hoặc trạng thái trở nên không hợp lệ, và quá trình xử lý phần còn lại của lô sẽ dừng.

Các quy tắc về nơi lưu trữ mạng được mô tả trong [OPTIONS.md](OPTIONS.md#network-storage).

<br />

## Lỗi khi làm việc với thiết bị

### SSH và truyền tệp, mã 40–43

Kiểm tra địa chỉ thiết bị, khả năng truy cập dịch vụ SSH, tên đăng nhập, mật khẩu và cổng. Nếu không chỉ định cổng trong `devicelist.cfg`, giá trị `SshPort` từ thiết lập sẽ được dùng; mặc định là `22`.

Người dùng RouterOS phải có quyền cho các thao tác đã chọn: xuất cấu hình, tạo và lấy bản sao lưu, xóa tệp tạm và thực hiện mọi thao tác dọn dẹp đã bật.

**Và ở đây có một sắc thái!!!** Kết nối thành công bằng lệnh SSH thông thường của bạn không có nghĩa là script dùng cùng thiết lập. Script làm việc bằng mật khẩu và không dùng SSH agent, khóa hay `~/.ssh/config` thông thường. Tệp được lấy qua `scp -O`.

Mã `40` liên quan đến kết nối hoặc truyền tải SSH/SCP, `41` là xác thực, `42` là lệnh RouterOS hoặc phản hồi của lệnh, và `43` là truyền tệp. Thiết lập kết nối được giải thích thêm trong [SECURITY.md](SECURITY.md#kết-nối-tới-routeros).

### Lỗi đặt tên, mã 50 và 52

Mã `50` có nghĩa là tên thiết bị cuối cùng không hợp lệ. Kiểm tra nguồn tên đã chọn và nội dung trong ngoặc đơn: ở phiên bản hiện tại, đoạn đầy đủ, không trống đầu tiên trong ngoặc đơn được dùng làm tên.

Sau khi xử lý, tên phải chứa từ 1 đến 32 ký tự. Tên quá dài không bị cắt ngắn. Các tên dành riêng như `CON` và `NUL` cũng bị từ chối.

Mã `52` có nghĩa là tên cuối cùng trùng với thiết bị khác trong cùng lần chạy. Việc so sánh không phân biệt chữ hoa/chữ thường: `Router-A` và `router-a` được xem là giống nhau.

Nguồn tên và quy tắc xử lý được mô tả trong [DEVICES.md](DEVICES.md#device-names).

### Xác minh bản sao lưu thất bại, mã 51 và 53

Mã `51` áp dụng cho `.rsc`, còn mã `53` áp dụng cho `.backup`. Tệp lấy về không vượt qua xác minh—ví dụ, tệp trống hoặc kích thước không khớp với tệp trên thiết bị.

Kiểm tra giai đoạn xảy ra lỗi, cùng dung lượng trống và quyền trên cả máy chủ lẫn RouterOS. Sau một lần thử thất bại, script thử thêm một lần sau 2 giây. Hai định dạng được thử riêng, vì vậy một tệp có thể được lấy thành công trong khi tệp kia thất bại.

Cảnh báo về việc không xóa được tệp RouterOS tạm sau khi đã lấy thành công bản sao lưu không tự nó có nghĩa là bản sao lưu cục bộ bị hỏng.

<br />

## Không có bản sao lưu mới nhưng cũng không có lỗi

Trước hết, hãy kiểm tra `UseIncremental`. Khi bật so sánh, bản sao lưu mới có thể bị xóa vì trùng lặp trong khi bản trước vẫn được giữ. Đối với `.rsc`, nội dung được so sánh mà không tính ngày trong phần đầu tiêu chuẩn; đối với `.backup`, chỉ kích thước tệp được so sánh.

Với `UseIncremental=false`, bản sao lưu mới hợp lệ được giữ mà không thực hiện so sánh này.

Cũng cần nhớ rằng hai lần chạy cho cùng thiết bị vào cùng thư mục trong vòng một phút sẽ dùng cùng tên tệp. Lần chạy thứ hai không tạo phiên bản riêng.

Nếu việc lưu trữ vào kho hằng tháng đã chạy trong ngày đó, hãy kiểm tra cả tệp ZIP. Trong chế độ CLI một thiết bị, bản sao lưu mới cũng có thể nằm bên trong. Quy tắc lưu giữ đầy đủ được cung cấp trong [BACKUPS.md](BACKUPS.md).

<br />

<a id="archive-problems"></a>
## Kho lưu trữ hằng tháng không xuất hiện

Kiểm tra giá trị `MonthlyArchive` và ngày chạy theo giờ địa phương của máy chủ. `false` vô hiệu hóa lưu trữ vào kho; `true` hoặc `1` chọn ngày đầu tiên, còn số từ `2` đến `28` chọn ngày đó trong tháng.

Trong ngày đã chọn, thời điểm chạy không quan trọng. Nếu bỏ lỡ ngày đó, lần chạy thông thường sau này sẽ không thực hiện bù. Việc lưu trữ vào kho hằng tháng không được thực hiện qua BackUP Master.

Nếu không có gì để lưu trữ, script không tạo tệp ZIP trống.

### Tìm tệp ZIP ở đâu

Tên kho lưu trữ tương ứng với ngày dương lịch trước đó. Ví dụ, lần chạy vào ngày 1 tháng Mười năm 2026 tạo `30.09.2026.zip`:

| Chế độ | Vị trí |
|---|---|
| Hàng loạt | `<BackupRoot>/<DeviceName>/archive/30.09.2026.zip` |
| Một thiết bị qua CLI | `<BackupRoot>/30.09.2026.zip` |

Tên thư mục `archive/` viết thường. Lần chạy khác trong cùng ngày cập nhật cùng tệp ZIP.

### Lưu trữ vào kho kết thúc với lỗi

Đối với mã `70` và `71`, hãy kiểm tra nhật ký thiết bị, quyền truy cập thư mục kho lưu trữ, dung lượng trống và trạng thái của mọi tệp ZIP hiện có. Cần dung lượng ở cả nơi lưu trữ và `/tmp` cục bộ.

Trên đĩa cục bộ, thư mục `archive/` phải thuộc về người dùng script và có chế độ `0700`. Trong chế độ hàng loạt với nơi lưu trữ mạng đã xác minh và `UseNetFolder=true`, chỉ riêng việc NAS gán chủ sở hữu hoặc quyền khác không phải là lý do gây lỗi. Lỗi lưu trữ trong lúc tạo kho cũng có thể tạo mã `64` hoặc `65`.

Kiểm tra kho lưu trữ hiện có bằng lệnh sau, thay bằng đường dẫn thực tế:

```bash
unzip -t "/mnt/backup/mikrotik/Router-A/archive/30.09.2026.zip"
```

Các tệp nguồn không bị xóa cho tới khi một tệp ZIP đã xác minh được lưu. Nếu kho lưu trữ đã được lưu nhưng không thể xóa một số tệp nguồn, cả tệp ZIP và những tệp chưa xóa đều vẫn còn. Kho lưu trữ hiện có bị hỏng không tự động được thay bằng tệp mới.

**Đừng xóa những bản sao lưu hoặc nhật ký còn lại cho tới khi bạn đã kiểm tra nội dung kho lưu trữ.** Trình tự lưu trữ vào kho được mô tả trong [BACKUPS.md](BACKUPS.md#monthly-archive).

<br />

## Không có nhật ký hoặc đầu ra trên màn hình

Với `LogLevel=0` và không có lỗi, nhật ký mới không được tạo. Trong các trường hợp khác, hãy kiểm tra `BackupRoot`, `MainLogPath` đã chọn và quyền ghi.

Giá trị `MainLogPath=` trống giữ `main.log` trong `BackupRoot`. Nếu chỉ định thư mục riêng, thư mục đó phải tồn tại sẵn và người dùng script phải truy cập được. Thiết lập này không di chuyển nhật ký thiết bị.

Sau khi lưu trữ vào kho hằng tháng, lịch sử trước đó của thiết bị nằm trong ZIP. Công việc tiếp theo được ghi vào nhật ký mới bên cạnh các bản sao lưu.

Khi script chạy từ bộ lập lịch hoặc đầu ra bị chuyển hướng, nhật ký trên màn hình với chỉ báo và dấu màu sẽ không xuất hiện. Việc ghi tệp nhật ký không bị vô hiệu hóa vì điều này.

Lỗi ghi nhật ký không làm dừng chính quá trình sao lưu, nhưng xuất hiện trong kết quả lần chạy dưới dạng cảnh báo. Xem [LOGGING.md](LOGGING.md) để biết chi tiết.

<br />

<a id="language-problems"></a>
## Bản dịch không được áp dụng

Kiểm tra ngôn ngữ đã chọn và vị trí tệp. Ví dụ, `Language=de` yêu cầu một tệp thông thường có thể đọc, tên `de.lang`, nằm bên cạnh `mikrotik-backup.sh`, không phải trong thư mục `lang/`. Liên kết tượng trưng không được dùng làm tệp dịch.

Với `Language=auto`, môi trường hệ điều hành xác định ngôn ngữ. Bạn có thể chọn rõ ràng cho một lần chạy, ví dụ khi xem trợ giúp:

```bash
mikrotik-backup.sh --language=de --help
```

Các thông báo chưa dịch hiển thị bằng tiếng Anh. Dòng sai định dạng trong tệp bị bỏ qua. Các tệp tên `ru.lang` và `en.lang` không thay thế bản dịch tích hợp.

Định dạng dòng, tên khóa và quy tắc nạp bản dịch được mô tả trong [LOCALIZATION.md](LOCALIZATION.md).

<br />

## Một thiết lập không có hiệu lực

Kiểm tra tên thiết lập, giá trị được chấp nhận và các mục trùng lặp trong `option.cfg`. Khi một thiết lập được lặp lại, giá trị dùng được cuối cùng sẽ thắng. Tên khóa không phân biệt chữ hoa/chữ thường, nhưng dấu gạch nối và dấu gạch dưới không thể thay thế cho nhau.

Tùy chọn CLI ghi đè giá trị tương ứng từ tệp. Đối với các lần chạy thông thường cho một thiết bị và theo lô, thứ tự là:

**Giá trị tích hợp** → **Các dòng option.cfg dùng được** → **CLI**

BackUP Master điền biểu mẫu theo cách khác: các trường thông thường lấy giá trị tích hợp và CLI, không lấy từ tệp tùy chọn. `UseIncremental` là ngoại lệ. Các thiết lập ghi nhật ký từ tệp cũng được tuân theo khi sao lưu được thực hiện qua BackUP Master.

Các quy tắc đọc thiết lập nằm trong [OPTIONS.md](OPTIONS.md), còn hành vi của BackUP Master được mô tả trong [INTERACTIVE.md](INTERACTIVE.md).

<br />

<a id="result-codes"></a>
## Mã kết quả

| Mã | Ý nghĩa |
|---:|---|
| `0` | Thành công, không ghi nhận lỗi hoặc cảnh báo |
| `1` | Hoàn tất với cảnh báo và không ghi nhận lỗi thực thi |
| `12` | Lỗi trong tùy chọn CLI, giá trị hoặc tổ hợp của chúng |
| `21` | Không thể đọc `option.cfg` |
| `22` | Không thể lấy danh sách thiết bị |
| `23` | Danh sách thiết bị không hợp lệ hoặc không có mục đủ điều kiện |
| `24` | Không thể đọc tệp Oxidized |
| `25` | Lược đồ không được hỗ trợ hoặc dữ liệu Oxidized không hợp lệ; không có mục MikroTik đủ điều kiện |
| `30` | Thiếu tiện ích bắt buộc hoặc tiện ích không hỗ trợ khả năng cần thiết |
| `31` | Terminal không dùng được, lỗi `stty` hoặc kích thước cửa sổ không đủ |
| `32` | Khóa cần thiết đang do lần chạy khác giữ |
| `33` | Đường dẫn hoặc đối tượng lưu trữ không hợp lệ cho lần chạy một thiết bị |
| `34` | Không thể tạo hoặc chuẩn bị thư mục chạy cho một thiết bị |
| `35` | Lỗi khi truy cập hoặc xác minh đối tượng dịch vụ cục bộ, bao gồm khóa |
| `36` | Nơi lưu trữ của lần chạy một thiết bị không vượt qua kiểm tra khả dụng trước khi lấy tệp |
| `37` | Không thể ghi hoặc thay thế tệp dịch vụ |
| `40` | Lỗi kết nối hoặc truyền tải SSH/SCP |
| `41` | Lỗi xác thực thiết bị |
| `42` | Lỗi lệnh RouterOS hoặc phản hồi dự kiến |
| `43` | Lỗi truyền tệp SCP |
| `50` | Tên thiết bị cuối cùng không hợp lệ |
| `51` | Tệp `.rsc` không vượt qua xác minh |
| `52` | Tên thiết bị cuối cùng bị trùng |
| `53` | Tệp `.backup` không vượt qua xác minh |
| `61` | Nơi lưu trữ dùng chung không truy cập được khi chuẩn bị chạy hàng loạt |
| `62` | Không thể xác nhận hoặc kích hoạt điểm gắn kết riêng cho `UseNetFolder=true` |
| `63` | Lỗi khi chuẩn bị hoặc xác minh thư mục sao lưu hàng loạt dùng chung |
| `64` | Lỗi nơi lưu trữ thiết bị hoặc kho lưu trữ trong khi nơi lưu trữ dùng chung vẫn truy cập được |
| `65` | Nơi lưu trữ dùng chung bị mất hoặc trở nên không hợp lệ trong lần chạy; quá trình xử lý hàng loạt dừng |
| `70` | Lỗi khi tạo hoặc cập nhật kho lưu trữ |
| `71` | ZIP hoặc đối tượng kho lưu trữ đích không vượt qua xác minh |
| `80` | Lỗi nội bộ hoặc yêu cầu hệ thống chưa đáp ứng, bao gồm khả năng `C.UTF-8` |
| `81` | Lỗi nội bộ của trình điều khiển MikroTik |
| `129` | Bị kết thúc bởi tín hiệu HUP |
| `130` | Bị kết thúc bởi tín hiệu INT, ví dụ khi nhấn Ctrl+C |
| `143` | Bị kết thúc bởi tín hiệu TERM |

Mã cuối cùng phản ánh lỗi thực thi đầu tiên được ghi nhận. Cảnh báo `1` bị thay thế bởi lỗi đầu tiên như vậy, và một lần thành công sau đó không xóa lỗi. Vì vậy, mã cuối cùng không nhất thiết khớp với thông báo cuối cùng trong nhật ký.

Nếu lần thử lại lấy tệp thành công, giai đoạn có thể kết thúc bằng `[OK]` dù lỗi của lần thử đầu tiên vẫn còn trong nhật ký. Mã cuối cùng khác không từ lần chạy hàng loạt cũng không có nghĩa là mọi thiết bị đều thất bại: hãy kiểm tra riêng từng kết quả.

Đối với mã `80`, hãy chú ý các yêu cầu hệ thống: GNU Bash 4.4 trở lên và locale `C.UTF-8` hoạt động đúng. Chi tiết nằm trong [INSTALL.md](INSTALL.md#yêu-cầu-đối-với-máy-chủ).

<br />

## Nếu bạn cần trợ giúp

Hãy cung cấp phiên bản script, hệ điều hành và phiên bản Bash, cách khởi động script, mã thoát và đoạn nhật ký liên quan. Đối với sự cố của một thiết bị, hãy kèm nhật ký thiết bị; đối với lỗi khi chuẩn bị lần chạy, hãy bắt đầu bằng `main.log`.

**Đừng gửi mật khẩu thật hoặc toàn bộ tệp thiết lập đang dùng.** Trước khi gửi nhật ký, ảnh chụp màn hình hoặc lệnh, hãy kiểm tra dữ liệu nhạy cảm. Các lưu ý về bảo vệ mật khẩu được mô tả trong [SECURITY.md](SECURITY.md).

Bạn có thể liên hệ với tác giả theo thông tin trong [mô tả sản phẩm](../README_VI.md#liên-hệ-với-tác-giả).
