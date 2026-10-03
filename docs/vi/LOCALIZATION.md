# Bản địa hóa

[Mục lục](../README_VI.md)

## Ngôn ngữ của giao diện và nhật ký

Tiếng Nga (`ru`) và tiếng Anh (`en`) được tích hợp trong script. Hai ngôn ngữ này không cần tệp dịch riêng. Phiên bản 2.3.1 cung cấp các bản dịch bên ngoài cho giao diện và nhật ký: `de.lang`, `es.lang`, `lv.lang`, `pl.lang` và `uk.lang`.

Ngôn ngữ của tài liệu và việc có bản dịch runtime bên ngoài là hai vấn đề độc lập. Vì vậy, tài liệu có thể tồn tại bằng một ngôn ngữ dù bản phân phối không có tệp `.lang` tương ứng.

Ngôn ngữ đã chọn được dùng trong trình đơn, trợ giúp, thông báo của script và các mục nhật ký. Không có thiết lập ngôn ngữ riêng cho nhật ký.

<br />

## Chọn ngôn ngữ

Thiết lập `Language` trong `option.cfg` điều khiển việc lựa chọn. Giá trị mặc định là `auto`:

| Giá trị | Ngôn ngữ được dùng |
|---|---|
| `auto` | Được xác định từ locale của hệ điều hành |
| `ru` | Tiếng Nga tích hợp |
| `en` | Tiếng Anh tích hợp |
| Mã hai chữ cái khác, chẳng hạn `de` | Bản dịch từ tệp tương ứng, chẳng hạn `de.lang` |

Để chọn tiếng Nga lâu dài, hãy đặt giá trị sau trong `option.cfg`:

```ini
Language=ru
```

Cho một lần chạy, bạn có thể chọn ngôn ngữ qua CLI:

```bash
mikrotik-backup.sh --language=ru --help
```

Tùy chọn `--language` được ưu tiên hơn thiết lập trong tệp tùy chọn nhưng không thay đổi chính tệp đó. Hãy dùng `auto` hoặc mã ngôn ngữ hai chữ cái; chữ hoa/chữ thường không quan trọng.

### Tự động lựa chọn

Với `auto`, script lấy giá trị không trống đầu tiên từ `LC_ALL`, `LC_MESSAGES` và `LANG`, theo thứ tự đó.

Ví dụ, `ru_RU.UTF-8` chọn tiếng Nga, còn `de_DE.UTF-8` chọn bản dịch tiếng Đức từ `de.lang`. Tiếng Anh được dùng cho `C`, `C.UTF-8`, `POSIX` hoặc khi không xác định được ngôn ngữ.

Thông báo cũng vẫn hiển thị bằng tiếng Anh nếu bản dịch bên ngoài đã chọn không dùng được.

<br />

## Kết nối bản dịch bên ngoài

Thư mục `lang/` chứa các bản dịch bên ngoài dựng sẵn `de.lang`, `es.lang`, `lv.lang`, `pl.lang` và `uk.lang`, cùng mẫu chuẩn `en.lang`. Để dùng một bản dịch bên ngoài, hãy sao chép tệp cần thiết vào thư mục chứa `mikrotik-backup.sh`.

Ví dụ, chạy lệnh sau trong thư mục script để cài tiếng Đức:

```bash
cp -- lang/de.lang de.lang
```

Sau đó chọn `de` trong thiết lập hoặc chỉ định khi khởi động script:

```bash
mikrotik-backup.sh --language=de --help
```

Tên tệp gồm hai chữ cái Latin và phần mở rộng `.lang`—ví dụ `de.lang`. Nó phải là tệp thông thường có thể đọc được, không phải liên kết tượng trưng.

*(Lưu ý: Thư mục `lang/` lưu bộ sưu tập bản dịch. Script không tự động nạp chúng từ thư mục đó: tệp cần dùng phải được đặt bên cạnh chính script.)*

`en.lang` chứa đủ 245 khóa của phiên bản 2.3.1 và là mẫu chuẩn để tạo bản dịch của bên thứ ba. Tệp này không thay thế tiếng Anh tích hợp và không được dùng như một ngôn ngữ runtime bên ngoài. Tệp `ru.lang`, nếu được tạo, cũng không thay thế tiếng Nga tích hợp và sẽ bị bỏ qua.

<br />

## Chọn ngôn ngữ trong Trình chỉnh sửa cấu hình

Mở trình chỉnh sửa bằng:

```bash
mikrotik-backup.sh -e
```

Di chuyển tới hàng ngôn ngữ → nhấn **Enter** cho tới khi giá trị cần dùng xuất hiện → chọn “Save.”

Các tùy chọn xoay vòng theo thứ tự sau:

```text
auto → ru → en → các ngôn ngữ bên ngoài được phát hiện theo thứ tự bảng chữ cái → auto
```

Ngôn ngữ biểu mẫu thay đổi ngay lập tức. Cho tới khi bạn lưu, đây chỉ là bản xem trước; “Cancel” khôi phục ngôn ngữ giao diện trước đó. Nếu `--language` được chỉ định khi khởi động, tùy chọn CLI đó có hiệu lực trở lại sau khi bạn rời trình chỉnh sửa.

Các chú thích trong `option.cfg` đã lưu dùng ngôn ngữ do chính thiết lập `Language` chọn, không dùng tùy chọn CLI tạm thời. Với `auto`, locale của hệ điều hành cũng được dùng cho các chú thích này.

Để biết thêm về trình chỉnh sửa, hãy xem [INTERACTIVE.md](INTERACTIVE.md).

<br />

## Tạo và chỉnh sửa bản dịch

Nếu bản dịch bạn cần chưa tồn tại, bạn có thể tự chuẩn bị. Hãy lấy `lang/en.lang` của cùng phiên bản script rồi lưu một bản sao thành `<xx>.lang`, trong đó `xx` là mã hai chữ cái của ngôn ngữ mới. Mẫu của phiên bản 2.3.1 chứa đủ 245 khóa.

Định dạng rất đơn giản: mỗi thông báo có một dòng riêng. Ví dụ, mẫu tiếng Anh chứa:

```text
msg_version_en="MikroTik Backup Script"
msg_menu_title_en="Main menu"
```

Mỗi khóa bắt đầu bằng `msg_`, tiếp theo là tên thông báo (`version`, `menu_title`) và hậu tố ngôn ngữ `_en`.

Đối với ngôn ngữ mới, hãy thay hậu tố `_en` bằng `_xx` trong mọi khóa và chỉ dịch các giá trị trong dấu nháy. Đừng thay đổi tên thông báo và hãy giữ nguyên chính xác mọi placeholder. Để sửa một bản dịch hiện có, chỉ cần thay đổi văn bản cần thiết ở bên phải dấu `=`.

Bạn không cần dịch toàn bộ tệp cùng lúc: các thông báo bị thiếu sẽ hiển thị bằng tiếng Anh. Script không dùng khóa mới tùy ý.

### Quy tắc định dạng tệp

Lưu tệp dưới dạng UTF-8. Đặt mọi giá trị trong dấu nháy kép và bảo đảm giá trị không trống. Đừng thêm khoảng trắng trước khóa, quanh dấu `=` hoặc sau dấu nháy đóng.

Dùng `\"` cho dấu nháy kép bên trong văn bản và `\\` cho dấu gạch chéo ngược. Các escape khác, bao gồm `\n` và `\t`, không được hỗ trợ. Cho phép ký tự `=` bên trong dấu nháy.

Các dòng trống bị bỏ qua. Định dạng `.lang` không có chú thích; ký tự `#` bên trong dấu nháy là một phần của văn bản. Hỗ trợ kiểu kết thúc dòng Windows (CRLF) và một BOM ở đầu tệp.

Dòng sai định dạng bị bỏ qua trong khi các bản dịch hợp lệ khác vẫn được dùng. Nếu một thông báo được chỉ định nhiều lần, mục hợp lệ cuối cùng sẽ có hiệu lực. Không cho phép ký tự điều khiển và mã màu terminal trong bản dịch.

*(Lưu ý: Tệp bản địa hóa được xử lý như dữ liệu văn bản. Biến không được khai triển và lệnh shell không được chạy từ tệp.)*

### Phần giữ chỗ trong thông báo

Một số chuỗi chứa giá trị trong dấu ngoặc nhọn, ví dụ:

```text
msg_log_batch_device_position_en="Processing device {index} of {total}"
```

Khi chạy, script thay `{index}` và `{total}` bằng số thứ tự thiết bị và tổng số thiết bị. Đừng dịch các dấu này: hãy giữ đúng một lần mỗi phần giữ chỗ từ chuỗi nguồn. Bạn có thể thay đổi vị trí của chúng trong câu.

Nếu các phần giữ chỗ không hợp lệ, thông báo tiếng Anh được dùng thay cho chuỗi đó.

Sau khi lưu tệp, hãy kiểm tra bản dịch trong phần trợ giúp và trình đơn tương tác với ngôn ngữ đó được chọn. Các nguyên nhân khiến bản dịch không nạp được được mô tả trong mục [Khắc phục sự cố](TROUBLESHOOTING.md#language-problems).
