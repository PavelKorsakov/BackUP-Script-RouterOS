# Cài đặt

[Mục lục](../README_VI.md)

## Yêu cầu đối với máy chủ

Script yêu cầu Linux với GNU Bash **4.4 trở lên** và các tiện ích tệp GNU tiêu chuẩn.
Bản thân script không cần biên dịch, Python, container hay cơ sở dữ liệu.
Tuy nhiên, script cần các tiện ích được liệt kê trong mục [Phần phụ thuộc](#phần-phụ-thuộc).

Việc xử lý tên thiết bị cần locale **`C.UTF-8`** hoạt động đúng để đếm ký tự nhiều byte, nhận diện chữ cái và chuyển đổi chữ hoa/chữ thường.
Script kiểm tra các khả năng này trước khi làm việc với thiết bị. Đây là yêu cầu hệ thống, không phải một chương trình riêng có tên `C.UTF-8`.

Đương nhiên, máy chủ phải có sẵn kết nối mạng tới dịch vụ SSH của RouterOS và quyền ghi vào nơi lưu trữ đã chọn.

**Đặc biệt khuyến nghị!!!**
Script kết nối tới thiết bị RouterOS qua SSH bằng xác thực mật khẩu, không dùng xác thực bằng khóa.
(*Xem [SECURITY.md](SECURITY.md) để biết chính sách truyền tải chính xác.*)
Vì vậy, bạn nên tạo một người dùng chuyên dụng trên thiết bị và giới hạn đăng nhập của người dùng đó theo địa chỉ IP của máy chủ chạy script này.

<br />

## Phần phụ thuộc

### Bắt buộc để sao lưu

**Tất cả** các tiện ích sau đều bắt buộc để tạo bản sao lưu:

| Tiện ích | Mục đích |
|---|---|
| `ssh`, `scp`, `sshpass` | Kết nối tới RouterOS, chạy lệnh và lấy tệp về |
| GNU `timeout`, `sleep` | Giới hạn thời gian thao tác và tạo khoảng dừng |
| `sha256sum` | Tính checksum |
| `realpath` | Phân giải đường dẫn tuyệt đối |
| `flock` | Khóa đồng bộ để ngăn các lần chạy đồng thời xung đột với nhau |

**Nếu thiếu một tiện ích bắt buộc, script sẽ báo các phần phụ thuộc chưa được đáp ứng
và dừng lần thử sao lưu.
Mã lỗi phần phụ thuộc là `30`. Đây là hành vi dự kiến.**

Danh sách này giống nhau cho sao lưu một thiết bị và sao lưu hàng loạt, bất kể
script tạo tệp `.rsc`, `.backup` hay cả hai định dạng.

Chỉ có các lệnh trùng tên là chưa đủ. OpenSSH đã cài đặt phải
hỗ trợ những tùy chọn mà script sử dụng, bao gồm chế độ SCP cũ được chọn bằng `scp -O`.
GNU `timeout` phải hỗ trợ `--signal` và `--kill-after`.
Các khả năng này được kiểm tra cục bộ, không cần kết nối tới router.

<br />

### Bắt buộc cho từng tính năng cụ thể

Các công cụ này không thuộc danh sách bắt buộc chung. Chúng chỉ cần thiết
khi sử dụng tính năng tương ứng.

| Tính năng | Yêu cầu | Điều gì xảy ra nếu thiếu |
|---|---|---|
| Chế độ hàng loạt với `UseNetFolder=true` | `findmnt` | Sao lưu không bắt đầu ở chế độ này; lỗi phần phụ thuộc `30` |
| Lần chạy đến kỳ lưu trữ vào kho hằng tháng | Info-ZIP `zip`, `unzip`, GNU `mv` | Lần chạy dừng trong bước kiểm tra phần phụ thuộc, trước mọi thao tác sao lưu; lỗi `30` |
| Trình đơn tương tác, Trình chỉnh sửa cấu hình và BackUP Master | `stty` và terminal trên đầu vào, đầu ra chuẩn | Màn hình tương tác không mở; lỗi terminal `31` |
| **Copy console command** trong BackUP Master | GNU `base64` có hỗ trợ `--wrap=0` | Không thể sao chép lệnh; lỗi `30` |

Ví dụ, thiếu `zip` không cản trở một lần sao lưu thông thường khi chưa đến kỳ lưu trữ vào kho hằng tháng.
Thiếu `base64` không cản trở việc tạo bản sao lưu.
*(Lưu ý: Tiện ích này là bắt buộc khi bạn chọn **Copy console command**.)*

Quy trình kiểm tra phần phụ thuộc chung chạy trước khi sao lưu, không phải mỗi lần chương trình mở.
Do đó, trợ giúp, thông tin phiên bản hoặc trình đơn vẫn có thể dùng được ngay cả khi chưa cài các tiện ích sao lưu.

<br />

### Môi trường Linux cơ bản

Script cũng giả định rằng các lệnh hệ thống thông thường để làm việc với tệp
và thư mục đều có sẵn, bao gồm `date`, `stat`, `mkdir`, `cp`, `ln` và `rm`.

Chúng là một phần của môi trường hệ điều hành cơ bản. Danh sách phần phụ thuộc
được kiểm tra trước không phải là danh sách đầy đủ mọi lệnh bên ngoài mà
script sử dụng. Nếu thiếu một lệnh hệ thống cơ bản, thao tác tương ứng có thể thất bại
thay vì tạo thông báo phần phụ thuộc chưa được đáp ứng.

<br />

### Cài đặt các gói bắt buộc trên Debian/Ubuntu

Ví dụ này cài đặt các công cụ bắt buộc và công cụ tùy chọn nêu trên:
*(Lưu ý: Ở đây và trong các phần dưới, người dùng được giả định có quyền quản trị viên.)*

```bash
sudo apt-get update
sudo apt-get install bash openssh-client sshpass coreutils util-linux zip unzip
```

<br />

## Lấy các tệp script

Cách cài đặt chính cho phiên bản 2.3.1 là asset GitHub Release đầy đủ `mikrotik-backup-2.3.1.zip`. Gói này được giải nén trực tiếp vào thư mục cài đặt mà không có thêm thư mục bao ngoài.
*(Lưu ý: Với các ví dụ đặt tệp dưới `/opt`, hãy chạy lệnh bằng quyền cho phép tạo và ghi vào thư mục đó.)*

### Cách 1: Gói phát hành đầy đủ

Tải `mikrotik-backup-2.3.1.zip` từ GitHub Release của MikroTik Backup Script 2.3.1, rồi chạy:

```bash
mkdir -m 700 -- /opt/mikrotik-backup
unzip -q -- mikrotik-backup-2.3.1.zip -d /opt/mikrotik-backup
cd -- /opt/mikrotik-backup
sha256sum --check SHA256SUMS
```

Sau khi giải nén, cấu trúc sẵn sàng sử dụng là:

```text
mikrotik-backup.sh
SHA256SUMS
README.md
lang/
docs/
```

Nếu xác minh checksum thất bại, đừng chạy script cho đến khi tìm ra nguyên nhân.

<br />

### Cách 2: Cài đặt độc lập tối thiểu

Tải hai asset `mikrotik-backup.sh` và `SHA256SUMS` từ cùng Release vào một thư mục được bảo vệ, xác minh chúng rồi đặt quyền thực thi cho script:

```bash
mkdir -m 700 -- /opt/mikrotik-backup
cd -- /opt/mikrotik-backup
# Tải cả hai asset của Release vào thư mục này.
sha256sum --check SHA256SUMS
chmod 700 -- mikrotik-backup.sh
```

Để dùng ngôn ngữ runtime bên ngoài, hãy dùng gói đầy đủ hoặc lấy tệp `.lang` tương ứng từ mã nguồn có tag của cùng phiên bản.

<br />

### Tùy chọn nâng cao: Git hoặc gói mã nguồn

Bản clone Git hoặc gói **Code → Download ZIP** của kho này cũng là cây mã nguồn đầy đủ của sản phẩm. Cấu trúc hữu ích ở thư mục gốc là:

```text
mikrotik-backup.sh
README.md
lang/
docs/
```

`SHA256SUMS` là asset của Release và có thể không có trong bản checkout mã nguồn. Với cài đặt thông thường, vẫn nên dùng gói Release theo phiên bản vì nó chứa tệp checksum và khớp chính xác với phiên bản đã công bố.

<br />

## Các tệp bên cạnh script

Sau khi giải nén gói Release đầy đủ, thư mục đã chọn chứa script và các tệp đi kèm:

```text
mikrotik-backup/
├── mikrotik-backup.sh
├── SHA256SUMS
├── README.md
├── lang/
└── docs/
```

| Tệp hoặc thư mục | Mục đích |
|---|---|
| mikrotik-backup.sh | Bản thân script sao lưu |
| SHA256SUMS | Checksum dùng để xác minh các tệp đã tải xuống |
| README.md | Mô tả sản phẩm và liên kết tới tài liệu chi tiết |
| lang/ | Các tệp bản địa hóa. Sao chép tệp ngôn ngữ cần dùng từ thư mục này vào thư mục của script. |
| docs/ | Tài liệu chi tiết về cài đặt, cấu hình và sử dụng |

Để vận hành thực tế, chỉ cần `mikrotik-backup.sh`.
Để thay đổi thiết lập, hãy tạo **option.cfg** và đặt bên cạnh script.
Nếu định truy vấn và sao lưu lần lượt nhiều thiết bị, hãy tạo thêm **devicelist.cfg** bên cạnh script.
Nếu muốn trình đơn và mục nhật ký hiển thị bằng ngôn ngữ của bạn, cần có tệp bản địa hóa tên `<xx>.lang`. Hãy đặt tệp đó trong cùng thư mục với `mikrotik-backup.sh`.
Tiếng Nga và tiếng Anh không cần tệp bản địa hóa riêng vì cả hai được tích hợp trong script.

**Trong chế độ tương tác, script có thể tạo và lưu:**
Danh sách thiết bị—**devicelist.cfg**—thông qua BackUP Master.
Tệp cấu hình—**option.cfg**—thông qua Trình chỉnh sửa cấu hình.
Bạn cũng có thể tự chuẩn bị chúng:
*Định dạng danh sách thiết bị TSV được mô tả chi tiết trong [DEVICES.md](DEVICES.md).*
*Định dạng tệp cấu hình `Key=value` được mô tả chi tiết trong [OPTIONS.md](OPTIONS.md).*

<br />

## Chuẩn bị nơi lưu trữ và nhật ký

Với thiết lập sao lưu mặc định, script tạo thư mục `./backups` bên cạnh chính nó và lưu các bản sao lưu thiết bị tại đó.
Khác biệt duy nhất giữa các chế độ là lần chạy cho một thiết bị đặt các tệp được tạo trực tiếp trong `./backups`, còn chế độ hàng loạt tạo thư mục con mang tên thiết bị dưới `./backups` và lưu bản sao lưu của thiết bị đó tại đây.

Script tự tạo các thư mục lưu trữ cần thiết với quyền phù hợp.
*(Script không tự động đổi chủ sở hữu hoặc chế độ truy cập của các thư mục hiện có do quản trị viên tạo.)*

Theo mặc định, nhật ký chính của script, `main.log`, được lưu trong `./backups`.
Trong chế độ hàng loạt, nhật ký thiết bị được lưu trong thư mục con của thiết bị đó.

Bạn cũng nên biết rằng khi thư mục sao lưu nằm trên nơi lưu trữ mạng,
script có thể kiểm tra khả năng truy cập thư mục đó trong quá trình xử lý hàng loạt. Tùy chọn này bị vô hiệu hóa theo mặc định và phải được cấu hình trước khi dùng.
*(Cách gắn kết thư mục không quan trọng.)*

Tất cả tùy chọn này có thể thay đổi bằng cách đặt các tham số cần thiết trong `option.cfg`.
Xem [Cấu hình](OPTIONS.md) để biết hướng dẫn và cú pháp tham số.

<br />

## Chạy script tự động

Trước khi bật lịch chạy, hãy chuẩn bị thiết lập và danh sách thiết bị.
Nếu không, lần chạy tự động không thể thực hiện sao lưu hàng loạt.

Bạn không bắt buộc phải tạo người dùng riêng để chạy script, nhưng chạy những thao tác như thế này bằng **root** được xem là cách làm không tốt. Ví dụ sau tạo một người dùng chuyên dụng.

Tạo người dùng **bsmt** *(bạn có thể chọn tên khác; hãy thay **bsmt** trong các ví dụ)* và chỉ cấp các quyền cần thiết:

```bash
(
    set -e

    SCRIPT_DIR="/opt/mikrotik-backup"

    sudo useradd \
        --system \
        --user-group \
        --home-dir "$SCRIPT_DIR" \
        --no-create-home \
        --shell /usr/sbin/nologin \
        bsmt

    sudo chown bsmt:bsmt \
        "$SCRIPT_DIR" \
        "$SCRIPT_DIR/mikrotik-backup.sh"

    sudo chmod 0700 \
        "$SCRIPT_DIR" \
        "$SCRIPT_DIR/mikrotik-backup.sh"

    sudo find "$SCRIPT_DIR" -maxdepth 1 -type f \
        \( -name 'option.cfg' -o -name 'devicelist.cfg' -o -name '*.lang' \) \
        -exec chown bsmt:bsmt {} + \
        -exec chmod 0600 {} +
)
```

<br />

**Nếu script đã từng được chạy bằng root**

*(Lưu ý: Nếu trước đây bạn đã chạy script bằng **root**, các thư mục, bản sao lưu
và nhật ký mà script tạo có thể không truy cập được đối với **bsmt**.
Hãy chuyển nơi lưu trữ hiện có cho người dùng đó trước khi bật lịch chạy.)*

Ví dụ này dùng thư mục cục bộ `/opt/mikrotik-backup/backups`.
Lệnh sau thay đổi chủ sở hữu và nhóm của thư mục cùng toàn bộ nội dung bên trong:

```bash
sudo chown -hR -P -- bsmt:bsmt "/opt/mikrotik-backup/backups"
```

*(Lưu ý: Hãy chỉ định thư mục sao lưu của script này, không phải thư mục dùng chung còn chứa dữ liệu của các chương trình khác.
Nếu nơi lưu trữ hoặc nhật ký chính nằm ở chỗ khác, hãy cấu hình quyền truy cập riêng cho từng vị trí theo quyền và thiết lập của nơi lưu trữ đã chọn, dựa trên cùng mẫu này.)*

Ví dụ này mở Trình chỉnh sửa cấu hình dưới người dùng **bsmt** sau khi người dùng đó được cấp quyền truy cập thư mục và tệp của script:
*(Lưu ý: Chạy lệnh bằng root hoặc bằng người dùng được phép thực hiện qua sudo.)*

```bash
sudo -u bsmt /usr/bin/bash /opt/mikrotik-backup/mikrotik-backup.sh -e
```

<br />

**Tạo lịch chạy cho script**

Ví dụ sau tạo lịch bằng systemd,
nhưng bạn có thể dùng crontab hoặc bất kỳ phương thức nào mình muốn.

Chúng ta sẽ tạo một service chạy script bằng người dùng chuyên dụng và một timer khởi động service theo lịch.
*(Ví dụ chạy mỗi ngày lúc 1 giờ sáng, nhưng lịch chạy hoàn toàn do bạn quyết định.)*

```bash
(
    set -e

    sudo tee /etc/systemd/system/mikrotik-backup.service >/dev/null <<'EOF'
[Unit]
Description=MikroTik backup
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
User=bsmt
Group=bsmt
WorkingDirectory=/opt/mikrotik-backup
ExecStart=/usr/bin/bash /opt/mikrotik-backup/mikrotik-backup.sh
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
UMask=0077
NoNewPrivileges=true
Restart=no
TimeoutStartSec=infinity
StandardInput=null
StandardOutput=journal
StandardError=journal
EOF

    sudo tee /etc/systemd/system/mikrotik-backup.timer >/dev/null <<'EOF'
[Unit]
Description=Daily MikroTik backup

[Timer]
OnCalendar=*-*-* 01:00:00
AccuracySec=1s
Persistent=false
Unit=mikrotik-backup.service

[Install]
WantedBy=timers.target
EOF

    sudo chmod 0644 \
        /etc/systemd/system/mikrotik-backup.service \
        /etc/systemd/system/mikrotik-backup.timer

    sudo systemd-analyze verify \
        /etc/systemd/system/mikrotik-backup.service \
        /etc/systemd/system/mikrotik-backup.timer

    sudo systemctl daemon-reload
    sudo systemctl enable --now mikrotik-backup.timer

    systemctl list-timers --all mikrotik-backup.timer
)
```

*`Persistent=false` không bật lần chạy bù sau khoảng thời gian timer bị tắt.
`Restart=no` không lên lịch tự động khởi động lại service sau lỗi.*
