# MikroTik Backup Script

**Sao lưu các thiết bị MikroTik RouterOS.**

Script này tạo bản sao lưu cho các thiết bị chạy RouterOS, theo cách thủ công hoặc tự động thông qua bộ lập lịch *(do bạn tự cấu hình riêng)*.
Tệp `mikrotik-backup.sh` là một script độc lập, mặc dù một số tính năng có thể được cấu hình qua `option.cfg`.

<br>

## Tính năng của script

| Tính năng | Cách hoạt động |
|---|---|
| Chế độ một thiết bị | Tạo bản sao lưu của một thiết bị bằng các tùy chọn CLI |
| Xử lý hàng loạt | Xử lý lần lượt các thiết bị được liệt kê trong DeviceList; có thể nhập danh sách từ Oxidized |
| Định dạng sao lưu | Tạo tệp `.rsc`, `.backup` hoặc lần lượt cả hai định dạng |
| Chế độ sao lưu | Hỗ trợ xuất theo dạng compact, terse và verbose, cùng với mã hóa bản sao lưu nhị phân |
| Sao lưu gia tăng | Có thể chỉ giữ bản sao lưu khi phát hiện thay đổi |
| Kho lưu trữ hằng tháng | Có thể đưa các bản sao lưu và nhật ký cũ vào kho lưu trữ tại một mốc lịch |
| Ghi nhật ký | Ghi các giai đoạn chung vào `main.log` và thao tác với thiết bị vào `devicename.log` |
| Trình đơn cấu hình | Cung cấp trình đơn tương tác để thiết lập và vận hành thuận tiện |
| Bản địa hóa | Tích hợp tiếng Nga và tiếng Anh, đồng thời hỗ trợ các tệp bản địa hóa bên ngoài |
| Nơi lưu bản sao lưu | Có thể dùng bất kỳ thư mục sao lưu nào, kể cả NAS |
| Làm việc với NAS | Kiểm tra khả năng truy cập nơi lưu trữ trước khi tạo bản sao lưu |

<br>

## Yêu cầu hệ thống và bắt đầu sử dụng

**Bắt buộc:**
GNU Bash 4.4 trở lên và các tiện ích đã cài đặt sau: **SSH**, **SCP** và **SSHPass**.
Chỉ cần **zip** cho việc tạo kho lưu trữ bản sao lưu hằng tháng. Danh sách đầy đủ các tiện ích bắt buộc và lệnh cài đặt nằm trong mục [Phần phụ thuộc](vi/INSTALL.md#phần-phụ-thuộc).
*(Lưu ý: Nếu thiếu một tiện ích bắt buộc, script sẽ kết thúc với lỗi. Đây là hành vi dự kiến.)*

**Tùy chọn:**
**autofs**, **davfs2**, **rclone** và các công cụ khác để gắn kết nơi lưu trữ bên ngoài.

**Cài đặt:**
Xem [Cài đặt](vi/INSTALL.md) để biết cách tải xuống và thiết lập.

Chạy các lệnh sau trong thư mục chứa những tệp đã tải xuống:

Khối lệnh bên dưới giả định các tệp được lấy từ GitHub Release. Bản checkout mã nguồn bằng Git không chứa `SHA256SUMS` được tạo cho Release; với bản checkout mã nguồn, hãy bắt đầu bằng `chmod 700 mikrotik-backup.sh`, rồi tiếp tục kiểm tra phiên bản và trợ giúp.

```bash
sha256sum -c SHA256SUMS &&
chmod 700 mikrotik-backup.sh &&
./mikrotik-backup.sh --language en --version &&
./mikrotik-backup.sh --language ru --help
```

Nếu việc xác minh checksum **không thành công**, **đừng chạy tệp!!!**

<br>

## Các cách chạy script

**Chạy tệp KHÔNG kèm tùy chọn bổ sung** *(khi không có `option.cfg` hoặc tệp này không hợp lệ)*
Nếu không có `option.cfg` bên cạnh script hoặc tệp không chứa thiết lập nào có thể sử dụng, Trình chỉnh sửa cấu hình sẽ mở để bạn tạo hoặc chỉnh sửa `option.cfg`.

**Chạy tệp KHÔNG kèm tùy chọn bổ sung** *(khi có các tệp `option.cfg` và `devicelist.cfg` hợp lệ)*
Nếu đã có thiết lập có thể sử dụng, script sẽ bắt đầu xử lý hàng loạt.

**Chạy script với một tùy chọn:**

| Tác vụ | Lệnh |
|---|---|
| Mở trình đơn tương tác | `./mikrotik-backup.sh -i` |
| Mở BackUP Master | `./mikrotik-backup.sh -b` |
| Tạo hoặc chỉnh sửa `option.cfg` | `./mikrotik-backup.sh -e` |
| Hiển thị trợ giúp CLI đầy đủ | `./mikrotik-backup.sh -h` |
| Chạy sao lưu một thiết bị | Cung cấp đủ bộ ba CLI: địa chỉ thiết bị, người dùng và mật khẩu |

Tùy chọn quan trọng nhất ở đây là `-i`, dùng để mở trình đơn tương tác. Từ đó, bạn có thể:

- dùng BackUP Master để nhập tham số thiết bị, tạo bản sao lưu và tạo hoặc bổ sung `devicelist.cfg` bằng các tham số thiết bị đã chọn;
- dùng Trình chỉnh sửa cấu hình để tạo hoặc chỉnh sửa `option.cfg`;
- xem trợ giúp CLI;
- đọc hướng dẫn ngắn về các tính năng của script.

Để xem tài liệu CLI đầy đủ, bao gồm chính xác các dạng `-a=...`, `-u=...` và `-p=...`, hãy xem [tài liệu dòng lệnh](vi/CLI.md).

<br>

## Kết quả nằm ở đâu, hay “Bản sao lưu của tôi đâu rồi???”

Theo mặc định, các bản sao lưu thiết bị được lưu trong thư mục `backups` bên cạnh script. Nếu thư mục chưa tồn tại, script sẽ tạo nó.
*(Lưu ý: Đường dẫn tương đối `backups` được phân giải từ thư mục của script, không phải từ thư mục làm việc hiện tại!)*

Khi chạy cho một thiết bị, script không tạo thư mục con riêng cho thiết bị:

```text
backups/
├── main.log
├── Router-A_YYYY-MM-DD_HH-MM.rsc
├── Router-A_YYYY-MM-DD_HH-MM.backup
└── Router-A_YYYY-MM-DD_HH-MM.log
```

Trong chế độ hàng loạt, mỗi thiết bị có thư mục riêng:

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

Các bố cục này chỉ là ví dụ, không phải lời đảm bảo rằng mọi tệp đều tồn tại sau mỗi lần chạy.
Nhật ký được tạo khi mục nhật ký áp dụng đầu tiên được ghi.
Tùy chọn `MainLogPath` trong `option.cfg` có thể chuyển `main.log` sang `/var/log/` hoặc bất kỳ thư mục phù hợp nào khác.
Xem [Cấu hình](vi/OPTIONS.md) để biết chi tiết về cách cấu hình thư mục sao lưu, kho lưu trữ và nhật ký.

<br>

## Lưu trữ vào kho hằng tháng

Tính năng này bị vô hiệu hóa theo mặc định. Nếu script chạy theo lịch, hãy đặt `MonthlyArchive=true|1...28` trong `option.cfg` để chọn thời điểm đưa toàn bộ bản sao lưu của giai đoạn trước vào kho lưu trữ.

Vào ngày đó, một lần chạy hàng loạt sẽ đổi thứ tự công việc: trước tiên đưa toàn bộ dữ liệu đủ điều kiện đã tích lũy trong thư mục sao lưu vào kho lưu trữ, sau đó tạo bản sao lưu cho ngày hiện tại.

Kho lưu trữ được đặt tên theo ngày dương lịch trước đó. Ví dụ, lần chạy vào ngày 1 tháng Mười sẽ tạo `30.09.YYYY.zip`.

*(Lưu ý: Nếu script KHÔNG chạy hằng ngày, bạn phải tạo một tác vụ lập lịch riêng cho ngày cần thiết. Không cần tác vụ riêng nếu script chạy hằng ngày hoặc thường xuyên hơn.)*

Một lần lưu trữ hằng tháng bị bỏ lỡ—bất kể vì lý do gì—sẽ không được các lần chạy hằng ngày thực hiện bù.
Lần lưu trữ hằng tháng theo lịch tiếp theo sẽ gom toàn bộ dữ liệu cũ đã tích lũy vào một kho lưu trữ, kể cả khi phần tồn đọng kéo dài qua nhiều tháng. `main.log` không được đưa vào kho lưu trữ.

Xem [Kho lưu trữ hằng tháng](vi/BACKUPS.md#kho-lưu-trữ-hằng-tháng) để biết đầy đủ quy tắc, ví dụ và hành vi khi có lỗi.

<br>

## Tài liệu chi tiết

| Chủ đề | Trang |
|---|---|
| Yêu cầu, phần phụ thuộc và vị trí tệp | [Cài đặt](vi/INSTALL.md) |
| Tham số và lựa chọn chế độ | [CLI](vi/CLI.md) |
| Giá trị mặc định và `option.cfg` | [Cấu hình](vi/OPTIONS.md) |
| DeviceList, tên và Oxidized | [Thiết bị](vi/DEVICES.md) |
| Định dạng, so sánh, lưu trữ và kho ZIP | [Bản sao lưu](vi/BACKUPS.md) |
| Mức nhật ký, đường dẫn và thông báo | [Ghi nhật ký](vi/LOGGING.md) |
| Trình đơn, trình chỉnh sửa và BackUP Master | [Giao diện tương tác](vi/INTERACTIVE.md) |
| Chọn ngôn ngữ và tệp `.lang` | [Bản địa hóa](vi/LOCALIZATION.md) |
| Thông tin xác thực, SSH và quyền truy cập | [Bảo mật](vi/SECURITY.md) |
| Chẩn đoán theo triệu chứng hoặc mã kết quả | [Khắc phục sự cố](vi/TROUBLESHOOTING.md) |
| Xác minh bản phát hành và cập nhật | [Bản phát hành](vi/RELEASES.md) |
| Lịch sử phát triển và kế hoạch | [Lộ trình](vi/ROADMAP.md) |

<br>

## Phạm vi và giới hạn

Script tạo bản sao lưu nhưng không khôi phục cấu hình router.
Phiên bản hiện tại không gửi thông báo qua email hoặc ứng dụng nhắn tin và không xóa tệp ZIP cũ theo tuổi tệp.
Quản trị viên chịu trách nhiệm về quy trình khôi phục, chính sách lưu giữ bên ngoài và việc theo dõi kết quả.

Cấu hình SSH dùng xác thực bằng mật khẩu và vô hiệu hóa việc xác minh khóa máy chủ.
Mã hóa tệp `.backup` không mã hóa tệp `.rsc`, tệp cấu hình hoặc kho lưu trữ ZIP.
Hãy đọc [mô hình bảo mật](vi/SECURITY.md) trước khi sử dụng trong môi trường vận hành thực tế.

<br>

## Tài liệu bằng ngôn ngữ khác

[English](../README.md).
[Русский](README_RU.md).
[Latviešu](README_LV.md).
[Українська](README_UK.md).
[Deutsch](README_DE.md).
[Bahasa Indonesia](README_ID.md).
[Português (Brasil)](README_PT-BR.md).
[Tiếng Việt](README_VI.md).
[Español](README_ES.md).
[Polski](README_PL.md).
[বাংলা](README_BN.md).

## Liên hệ với tác giả

Gửi đề xuất tính năng, báo cáo lỗi và câu hỏi về script tới [backup-scripts@korsakov.dev](mailto:backup-scripts@korsakov.dev),
hoặc liên hệ với tác giả qua Telegram: [@PavelKorsakoff](https://t.me/PavelKorsakoff).
