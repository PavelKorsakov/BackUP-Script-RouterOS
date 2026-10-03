# Bản phát hành

[Mục lục](../README_VI.md)

## Phiên bản 2.3.1

**Bản phát hành bảo trì và sửa lỗi sau phiên bản 2.3.0 đã được công bố.**

Kiến trúc một tệp và yêu cầu tối thiểu GNU Bash 4.4 không thay đổi. `UseIncremental` hiện là thiết lập boolean chuẩn: `false` bỏ qua bước so sánh sau khi sao lưu và lưu giữ gia tăng, đồng thời giữ lại mọi hiện vật mới đã được tạo và xác thực thành công. Thiết lập này không có tùy chọn CLI riêng.

Thứ tự lịch của việc lưu trữ hằng tháng đã được sửa, và cách xử lý metadata cho nơi lưu trữ mạng đủ điều kiện đã được tăng cường trong khi vẫn giữ kiểm tra metadata nghiêm ngặt đối với hệ thống tệp cục bộ. Trình chỉnh sửa cấu hình và BackUP Master giờ dùng viewport đã được chấp nhận trên terminal thấp hơn, nên không cần hiển thị đồng thời mọi dòng của biểu mẫu.

Tiếng Nga và tiếng Anh vẫn được tích hợp. Phiên bản 2.3.1 cung cấp bản dịch runtime bên ngoài cho tiếng Đức, Tây Ban Nha, Latvia, Ba Lan và Ukraina (`de`, `es`, `lv`, `pl`, `uk`), cùng `en.lang` là mẫu dịch chuẩn đầy đủ gồm 245 khóa. Tài liệu người dùng có sẵn bằng 11 ngôn ngữ.

Thông báo vẫn chưa được triển khai và nằm ngoài phạm vi của bản phát hành này.

<br />

Xem [INSTALL.md](INSTALL.md) để biết cách lấy tệp, xác minh checksum và chuẩn bị script để sử dụng.
