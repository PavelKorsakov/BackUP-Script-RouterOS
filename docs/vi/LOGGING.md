# Ghi nhật ký

[Mục lục](../README_VI.md)

## Nhật ký chính và nhật ký thiết bị

Script ghi lại tiến trình tổng thể trong nhật ký chính `main.log`, còn chi tiết công việc với từng thiết bị được lưu trong nhật ký thiết bị riêng.

Trong `main.log`, bạn có thể xem danh sách thiết bị được chuẩn bị như thế nào, theo dõi quá trình xử lý hàng loạt và xem kết quả truy vấn thiết bị. Những lỗi xảy ra trước khi xác định được một thiết bị cụ thể cũng được ghi ở đây.

Nhật ký thiết bị chứa thông tin về việc lấy tệp `.rsc` và `.backup`, các lần thử lại, so sánh bản sao lưu và lưu trữ vào kho. Nói cách khác, nếu cần biết điều gì đã xảy ra khi sao lưu một thiết bị cụ thể, hãy xem nhật ký của thiết bị đó. Những chi tiết này không được lặp lại trong `main.log`.

<br />

## Nơi lưu nhật ký

Theo mặc định, nhật ký chính được lưu trong thư mục `backups` bên cạnh script. Nhật ký thiết bị được lưu cùng với bản sao lưu tương ứng:

| Nhật ký | Vị trí |
|---|---|
| Nhật ký chính | `<BackupRoot>/main.log` |
| Thiết bị trong chế độ hàng loạt | `<BackupRoot>/<DeviceName>/<DeviceName>.log` |
| Thiết bị trong lần chạy một thiết bị | `<BackupRoot>/<DeviceName>_YYYY-MM-DD_HH-MM.log` |

Trong chế độ hàng loạt, các mục mới được nối vào cùng nhật ký thiết bị. Đối với sao lưu một thiết bị, tên nhật ký chứa cùng ngày giờ như tên tệp sao lưu của lần chạy đó.

### Thư mục riêng cho main.log

Nếu muốn giữ nhật ký chính tách biệt khỏi bản sao lưu, hãy chỉ định thư mục trong thiết lập `MainLogPath` của `option.cfg`:

```ini
MainLogPath=/var/log/mikrotik-backup
```

Khi đó, nhật ký được ghi vào `/var/log/mikrotik-backup/main.log`. Nhật ký thiết bị vẫn ở vị trí thông thường.

Giá trị `MainLogPath=` trống dùng `BackupRoot` hiện tại. Đường dẫn tương đối, chẳng hạn `MainLogPath=logs`, chỉ tới thư mục bên cạnh script, không phải bên trong nơi lưu bản sao lưu.

*(Lưu ý: `MainLogPath` chỉ định một thư mục, không phải tên tệp đầy đủ. Thư mục phải tồn tại sẵn và người dùng chạy script phải có quyền ghi.)*

<br />

## Mức chi tiết của nhật ký

Thiết lập `LogLevel` điều khiển lượng thông tin được hiển thị và ghi lại. Giá trị mặc định là `2`:

| Giá trị | Tiến trình trên terminal | Các mục trong tệp nhật ký |
|---|---|---|
| `0` | Chỉ lỗi | Chỉ lỗi |
| `1` | Các giai đoạn chính và kết quả | Nhật ký ngắn gọn |
| `2` | Các giai đoạn chính và kết quả | Nhật ký chi tiết |
| `3` | Các giai đoạn chính và thao tác con hiện tại | Nhật ký chi tiết |

**Lỗi được ghi lại ở mọi mức.** Nhật ký ngắn gọn chứa các giai đoạn chính và kết quả; nhật ký chi tiết còn ghi các thao tác được thực hiện trong những giai đoạn đó.

Bạn có thể thay đổi mức trong `option.cfg` hoặc thông qua Trình chỉnh sửa cấu hình:

```ini
LogLevel=3
```

Để thay đổi cho một lần chạy của quy trình sao lưu hàng loạt đã cấu hình, hãy dùng CLI:

```bash
mikrotik-backup.sh --log-level=3
```

Thao tác này không thay đổi giá trị trong tệp tùy chọn. Tương tự, `--main-log-path` có thể đặt vị trí nhật ký chính cho lần chạy hiện tại.

BackUP Master không có trường riêng cho `LogLevel` hoặc `MainLogPath`. Nó dùng các thiết lập ghi nhật ký đang có hiệu lực cho lần chạy hiện tại.

<br />

## Hình thức của các mục nhật ký

Nhật ký là các tệp văn bản thông thường. Mỗi mục bao gồm ngày và giờ theo đồng hồ của máy chủ chạy script. Màu sắc và chỉ báo tiến trình không được ghi vào tệp.

Ví dụ về các mục trong `main.log`:

```text
[2026-10-01 01:00:00] [PID:12345] Xử lý thiết bị theo lô
[2026-10-01 01:00:15] [PID:12345] [OK] Xử lý thiết bị theo lô
```

Nhật ký chính còn bao gồm PID của tiến trình. Nhờ đó, bạn có thể phân biệt các mục do nhiều phiên bản script chạy đồng thời ghi ra.

PID không được thêm vào nhật ký thiết bị. Đây là một đoạn trích từ nhật ký chi tiết:

```text
[2026-10-01 01:00:05] Đang lấy bản sao lưu nhị phân
[2026-10-01 01:00:06] [1] Đang xóa bộ nhớ đệm DNS
[2026-10-01 01:00:07] [2] Đang xóa lịch sử console
[2026-10-01 01:00:12] [OK] Đang lấy bản sao lưu nhị phân
```

`[OK]` có nghĩa là thao tác đã hoàn tất thành công. Lỗi được đánh dấu bằng `[ER]` và bao gồm mã lỗi, ví dụ `[53]`. Các thao tác con được đánh số `[1]`, `[2]` và tiếp tục như vậy, bắt đầu lại trong mỗi giai đoạn chính.

Nếu một lần thử lại thành công sau lần thử thất bại, nhật ký giữ lại cả lỗi trước đó và kết quả thành công sau này.

Các mục nhật ký dùng cùng ngôn ngữ với giao diện, được chọn bằng thiết lập `Language`. Để biết thêm về cách chọn ngôn ngữ và dùng bản dịch, hãy xem [LOCALIZATION.md](LOCALIZATION.md).

<br />

## Đầu ra terminal

Trong lần chạy thủ công, tiến trình hiển thị trên màn hình. Khi một thao tác đang diễn ra, chỉ báo chờ xuất hiện bên cạnh. Khi hoàn tất, chỉ báo đổi thành `[OK]` màu xanh lục hoặc `[ER]` màu đỏ kèm mã lỗi.

Mức `1` và `2` hiển thị các giai đoạn chính. Ở mức `3`, thao tác con hiện tại cũng được hiển thị bên dưới giai đoạn đang thực hiện và thay đổi theo tiến trình. Trong chế độ hàng loạt, màn hình còn xác định thiết bị đang được xử lý.

*(Lưu ý: Khi script chạy không có terminal—ví dụ từ bộ lập lịch hoặc khi đầu ra bị chuyển hướng—phần hiển thị trên màn hình này không xuất hiện. Việc ghi tệp nhật ký vẫn tiếp tục ở mức đã chọn.)*

<br />

## Tích lũy và lưu trữ nhật ký vào kho

Tệp nhật ký được tạo khi mục đầu tiên được ghi. Với `LogLevel=0` và không có lỗi, tệp nhật ký mới không được tạo, còn các tệp hiện có vẫn không thay đổi.

Nhật ký chính và nhật ký thiết bị ở chế độ hàng loạt được nối thêm thay vì bị ghi đè sau mỗi lần chạy. Một dòng trống phân tách các lần chạy kế tiếp nhau.

`main.log` không được đưa vào kho lưu trữ cũng không bị xóa theo tuổi. Bạn tự bố trí việc xoay vòng tệp.

Khi bật lưu trữ vào kho hằng tháng, toàn bộ nhật ký thiết bị tích lũy ở chế độ hàng loạt được đưa vào ZIP cùng với các bản sao lưu của thiết bị đó. Sau khi kho lưu trữ được lưu thành công, nhật ký đã lưu trữ bị xóa khỏi thư mục thiết bị; kết quả lưu trữ và công việc tiếp theo sau đó được ghi vào một tệp nhật ký mới.

Nếu cùng một tệp ZIP được cập nhật lần nữa, lịch sử bên trong sẽ được mở rộng thay vì bị thay bằng nhật ký mới. Nếu không thể lưu kho lưu trữ, nhật ký trước đó vẫn được giữ nguyên và lỗi được ghi vào đó.

Nhật ký từ các lần chạy CLI cho một thiết bị được lưu trữ cùng bản sao lưu trong thư mục dùng chung. Việc lưu trữ vào kho ở cả hai chế độ được mô tả trong [BACKUPS.md](BACKUPS.md#monthly-archive).

<br />

## Nếu không thể ghi nhật ký

Không đủ quyền, thư mục không truy cập được hoặc lỗi ghi nhật ký khác không làm dừng chính quá trình sao lưu. Script ghi nhận cảnh báo và tiếp tục khi có thể.

`main.log` không truy cập được sẽ được báo một lần trong mỗi lần chạy, còn nhật ký thiết bị không truy cập được sẽ được báo một lần trong khi xử lý thiết bị đó. Nếu nhật ký chính dùng được, lỗi ghi nhật ký thiết bị sẽ được ghi vào đó.

Nếu không có lỗi nào khác, lần chạy thoát với mã `1`, nghĩa là hoàn tất kèm cảnh báo. Cảnh báo này không thay thế lỗi từ chính thao tác sao lưu.

Để biết mã kết quả và cách tìm nguyên nhân lỗi, hãy xem [TROUBLESHOOTING.md](TROUBLESHOOTING.md#result-codes).

*(Lưu ý: Mức chi tiết `3` không ghi mật khẩu hoặc toàn bộ lệnh kết nối vào nhật ký. Để biết cách bảo vệ thông tin xác thực và tệp script, hãy xem [SECURITY.md](SECURITY.md).)*
