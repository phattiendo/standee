TÀI LIỆU KIẾN TRÚC HỆ THỐNG SLIDESHOW & SDP (SMART DIGITAL SIGNAGE)
I. CẤU TRÚC THƯ MỤC (FOLDER STRUCTURE)
Hệ thống tuân thủ kiến trúc phân lớp (Layered Architecture), đảm bảo tính tách biệt và dễ mở rộng.   

Plaintext
lib/
├── core/
│   ├── network/
│   │   ├── dio_client.dart (Gọi API REST)
│   │   └── socket_client.dart (Quản lý WebSocket Weather)
│   ├── connectivity/
│   │   └── connectivity_service.dart (Theo dõi trạng thái mạng) [cite: 3]
│   └── constants/
│       └── api_constants.dart [cite: 3]
├── data/
│   ├── models/
│   │   └── media_item_model.dart (Mở rộng enum: image, video, sdp) [cite: 3, 10]
│   ├── datasources/
│   │   ├── remote_media_datasource.dart [cite: 3]
│   │   └── local_media_datasource.dart (Hive storage) [cite: 3]
│   └── repositories/
│       └── media_repository.dart [cite: 3]
├── presentation/
│   ├── controllers/
│   │   └── slideshow_controller.dart (Logic điều khiển & Preload) [cite: 4]
│   ├── widgets/
│   │   ├── slideshow_widget.dart [cite: 4]
│   │   ├── media_image_widget.dart [cite: 4]
│   │   ├── media_video_widget.dart [cite: 4]
│   │   └── media_sdp_widget.dart (Native UI cho Dashboard)
│   └── screens/
│       └── slideshow_screen.dart [cite: 4]
└── main.dart
II. DANH SÁCH THƯ VIỆN SỬ DỤNG (LIBRARIES)

dio: Xử lý các cuộc gọi API REST (AQI, Speedtest).   


cached_network_image: Cache ảnh (.webp, .png) vào ổ đĩa.   


hive: Cơ sở dữ liệu local để lưu trữ offline-first.   


connectivity_plus: Phát hiện thay đổi trạng thái mạng.   

web_socket_channel: Kết nối thời gian thực cho dữ liệu thời tiết.

syncfusion_flutter_gauges: Vẽ đồng hồ đo tốc độ mạng và chỉ số AQI.

III. CHIẾN THUẬT XỬ LÝ DỮ LIỆU & TỐI ƯU (ALGORITHMS)
1. Cơ chế Preload "Thông minh"
Thay vì chỉ preload ảnh, hệ thống phân loại nội dung tiếp theo để chuẩn bị tài nguyên:   


Ảnh/Video: Sử dụng precacheImage hoặc khởi tạo bộ giải mã video trước khi hiển thị.  

SDP (Special Dynamic Poster): Thực hiện gọi API lấy dữ liệu Air Quality và Internet Speed trước 2 giây. Khi đến lượt hiển thị, dữ liệu đã nằm sẵn trong RAM, loại bỏ hiện tượng "Loading".

2. Hiệu ứng Chuyển cảnh (Transitions)
Sử dụng AnimatedSwitcher để thực hiện hiệu ứng Fade-in/Fade-out mượt mà.   

Trong SDP, sử dụng Stack để chồng các lớp thông tin (Thời tiết, AQI) lên trên ảnh nền .webp. Ảnh nền được preload như một poster bình thường.

3. Tối ưu hóa Bộ nhớ (RAM Management)
Giới hạn Cache: Sử dụng memCacheWidth/Height cho ảnh nền .webp để tiết kiệm RAM.

Dọn dẹp định kỳ: Sau khi hoàn thành một chu kỳ lặp (A -> B -> 1 -> C), gọi PaintingBinding.instance.imageCache.clear() để giải phóng các bitmap cũ không còn sử dụng.

IV. XỬ LÝ CÁC TÌNH HUỐNG (EDGE CASES)
1. Mất kết nối mạng (Offline Handling)

Poster: Duy trì vòng lặp bằng danh sách lưu trong Hive và ảnh trong Disk Cache.   

SDP: Hiển thị dữ liệu cuối cùng được ghi nhận (Last Known Value) từ Hive. Giao diện hiển thị trạng thái "Ngoại tuyến" để đảm bảo tính minh bạch.


Tự động phục hồi: Sử dụng thuật toán Exponential Backoff để thử lại kết nối WebSocket ngay khi phát hiện có mạng trở lại.   

2. Xử lý định dạng tệp và GPU
Hỗ trợ .webp: Tận dụng giải mã phần cứng của Flutter cho tệp .webp để đạt hiệu năng cao nhất.


Thiết bị cấu hình yếu: Bao bọc các thành phần chuyển động (như kim đồng hồ Speedtest) bằng RepaintBoundary để cô lập việc vẽ lại, tránh lag toàn bộ hệ thống.   

V. LUỒNG ỨNG DỤNG (APPLICATION FLOW)
Khởi tạo App & Load cache từ Hive.   

Hiển thị Slide cũ ngay lập tức (Offline-first).   

Gửi yêu cầu API lấy danh sách Media mới nhất.   

Kích hoạt Timer 10 giây cho vòng lặp vô hạn.   

Thực hiện Preload gối đầu cho Item tiếp theo trong danh sách.


Tài liệu này được thiết kế để đảm bảo hệ thống chạy 24/7 ổn định, chuyên nghiệp và sẵn sàng cho môi trường thực tế (Production-ready).