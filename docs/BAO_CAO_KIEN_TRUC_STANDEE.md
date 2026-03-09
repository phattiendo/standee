# Báo cáo kiến trúc ứng dụng Standee (Digital Signage)

**Mục đích tài liệu:** Báo cáo mentor về cấu trúc dự án, thư viện sử dụng, luồng hoạt động và cách vận hành hiện tại của ứng dụng Standee (màn hình trình chiếu digital signage).

---

## 1. Tổng quan ứng dụng

Standee là ứng dụng Flutter chạy trên thiết bị digital signage (màn hình quảng cáo/trình chiếu), với các chức năng chính:

- **Trình chiếu slideshow**: poster (ảnh), video, SDP (màn hình động với dữ liệu thời tiết, chất lượng không khí, tốc độ…).
- **Offline-first**: dữ liệu media (ảnh, video) tải về và lưu trên bộ nhớ thiết bị (ROM), phát từ file local.
- **Một player video duy nhất**: tránh tạo/hủy player mỗi video để giảm lag và ổn định RAM.
- **Nhạc nền**: phát khi đang ở poster/SDP, tắt khi vào slide video.

---

## 2. Thư viện sử dụng (pubspec.yaml)

| Thư viện | Phiên bản | Vai trò |
|----------|-----------|--------|
| **flutter** | SDK | Nền tảng UI |
| **dio** | ^5.7.0 | HTTP client: gọi API, tải file (playlist, media) |
| **connectivity_plus** | ^6.1.1 | Theo dõi trạng thái mạng (online/offline) |
| **cached_network_image** | ^3.3.1 | Hiển thị ảnh từ mạng, cache ảnh |
| **image** | ^4.1.7 | Xử lý ảnh (resize khi tải về) |
| **media_kit** / **media_kit_video** / **media_kit_libs_android_video** | ^1.1.11 / ^1.2.5 / ^1.3.6 | Phát video: một Player, H264, phát từ file |
| **hive** / **hive_flutter** | ^2.2.3 / ^1.1.0 | Lưu cache local: playlist, version API |
| **path_provider** | ^2.1.5 | Lấy đường dẫn thư mục app (lưu ROM) |
| **web_socket_channel** / **stomp_dart_client** | ^3.0.1 / ^2.0.0 | WebSocket, STOMP: dữ liệu realtime (SDP, weather, AQI…) |
| **flutter_svg** | ^2.0.10+1 | Hiển thị SVG |
| **intl** | ^0.20.2 | Định dạng ngày/giờ |
| **carousel_slider** | ^5.0.0 | Thành phần slideshow (có thể dùng) |
| **just_audio** | ^0.9.40 | Phát nhạc nền |
| **flutter_bloc** / **equatable** | ^8.1.6 / ^2.0.5 | Quản lý state toàn app (Bloc), so sánh state |

---

## 3. Cấu trúc thư mục (lib/)

```
lib/
├── main.dart                    # Điểm vào: khởi tạo MediaKit, Hive, cấu hình fullscreen, giới hạn image cache, BlocProvider
│
├── bloc/app/                    # State toàn ứng dụng
│   ├── app_bloc.dart            # Xử lý AppStarted, Retry, Update → emit AppState tương ứng
│   ├── app_event.dart           # Các event: AppStarted, AppRetryRequested, AppCheckUpdateRequested, ...
│   └── app_state.dart           # Các state: AppInitial, AppLoading, AppReady, AppOffline, AppUpdating, AppError
│
├── core/                        # Hạ tầng dùng chung
│   ├── audio/
│   │   └── background_audio_service.dart   # Nhạc nền (just_audio), fade in/out khi vào/ra video
│   ├── bootstrap/
│   │   └── app_bootstrap.dart   # Khởi tạo: repository, connectivity, load cache; quyết định hasData / needsSetup / offline / error
│   ├── config/
│   │   ├── app_config.dart      # Cấu hình app
│   │   └── slideshow_config.dart # Bật/tắt poster, SDP, video, audio; đường dẫn asset; thời gian hiển thị
│   ├── constants/
│   │   └── api_constants.dart   # URL API, thời gian SDP, asset mặc định
│   ├── connectivity/
│   │   └── connectivity_service.dart  # Stream trạng thái mạng
│   ├── network/
│   │   ├── dio_client.dart      # Instance Dio (HTTP)
│   │   └── socket_client.dart   # WebSocket / STOMP (dữ liệu SDP)
│   ├── storage/
│   │   └── rom_media_storage.dart # ROM: standee_media/{images,videos,audio,cache}; copy asset; tải file; LRU
│   └── video/
│       └── video_service.dart   # Một Player (20MB buffer); open/play; loop seek-before-end; isFileReady
│
├── data/                        # Dữ liệu và nguồn dữ liệu
│   ├── datasources/
│   │   ├── local_media_datasource.dart   # Hive: đọc/ghi playlist, version
│   │   ├── remote_media_datasource.dart  # API: lấy version, danh sách media
│   │   ├── sdp_cache.dart
│   │   ├── sdp_datasource.dart
│   │   └── weather_cache.dart
│   ├── models/
│   │   ├── media_item_model.dart # MediaItem: id, url, type (image/video/sdp), durationSeconds, localPath
│   │   ├── weather_model.dart
│   │   ├── air_quality_model.dart
│   │   ├── speed_test_model.dart
│   │   └── standee_info_model.dart
│   └── repositories/
│       └── media_repository.dart # loadInitial; checkVersionAndUpdateIfNeeded; refreshFromRemote (tải ROM, lưu Hive)
│
└── presentation/
    ├── controllers/
    │   ├── slideshow_controller.dart  # Logic slideshow: preloadNext, nextSlide, releasePrevious; timer; videoEnded
    │   └── sdp_controller.dart        # Logic SDP (weather, AQI, speed, ...)
    │
    ├── screens/
    │   ├── app_flow_screen.dart       # Theo AppState → chọn màn: Loading | Slideshow | Offline | UpdateProgress | Error
    │   ├── loading_screen.dart
    │   ├── slideshow_screen.dart      # Full màn SlideshowWidget
    │   ├── offline_screen.dart
    │   ├── update_progress_screen.dart # Lần đầu: copy/tải ROM, hiển thị tiến độ
    │   └── error_screen.dart
    │
    └── widgets/
        ├── slideshow_widget.dart      # Chỉ render: Stack 2 layer, fade 200ms; thực thi preload/release khi controller gọi
        ├── media_image_widget.dart    # Hiển thị ảnh (file / network / asset)
        ├── media_video_widget.dart    # Gọi VideoService.open khi play; báo Started/Ended
        ├── waiting_video_widget.dart  # Video chờ (màn loading/setup), Player riêng, loop + mute
        └── sdp/
            ├── media_sdp_widget.dart
            ├── liquid_glass_container.dart
            ├── weather_section.dart
            ├── weather_ambient_overlay.dart
            ├── aqi_section.dart
            ├── aqi_bar_painter.dart
            ├── speed_section.dart
            ├── speed_gauge_painter.dart
            ├── health_advice_section.dart
            └── ...
```

---

## 4. Luồng hoạt động hiện tại

### 4.1 Khởi động ứng dụng

1. **main.dart**
   - Khởi tạo MediaKit (video).
   - Khởi tạo Hive (cache local).
   - Cấu hình fullscreen, orientation.
   - Giới hạn image cache: tối đa 6 ảnh, 30MB (phù hợp poster ~3–5MB/ảnh).
   - Chạy app với BlocProvider(AppBloc), home = AppFlowScreen.

2. **AppBloc nhận AppStarted**
   - Emit **AppLoading**.
   - Gọi **AppBootstrap.run()**:
     - Repository.init(), Connectivity.init().
     - loadInitial() từ Hive (playlist đã cache).
   - Kết quả:
     - **Có cache** → emit **AppReady** → hiển thị **SlideshowScreen**.
     - **Chưa có cache** → emit **AppUpdating** → **UpdateProgressScreen** (copy asset, tải media lần đầu).
     - **Mất mạng và cần data** → emit **AppOffline** → **OfflineScreen**.
     - **Lỗi** → emit **AppError** → **ErrorScreen**.

3. **AppFlowScreen**
   - BlocBuilder theo AppState → chọn đúng màn hình (Loading / Slideshow / Offline / UpdateProgress / Error).

### 4.2 Vận hành slideshow

**SlideshowController** nắm toàn bộ logic:

- **Danh sách**: `_media` (list MediaItem), `_currentIndex` (slide hiện tại).
- **preloadNext()**: Preload slide kế tiếp
  - Nếu là **image** → gọi callback để precache ảnh.
  - Nếu là **video** → chỉ kiểm tra file tồn tại (không mở player).
- **nextSlide()**: Chuyển sang slide tiếp theo
  - releasePrevious(prev): giải phóng tài nguyên slide cũ (ảnh → evict khỏi cache).
  - Tăng `_currentIndex`, xử lý chuyển nhạc nền (vào/ra video).
  - _notify() → UI cập nhật (double buffer).
  - preloadNext() → _startTimer().
- **releasePrevious(prev)**: Image → gọi callback evict ảnh; video không mở sẵn nên không cần release.

**Thời gian hiển thị (timer):**

- **Ảnh / SDP**: Dùng **Timer(durationSeconds)**; hết giờ → _onSlideTimerFired → **nextSlide()**.
- **Video**: **Không dùng timer**; chuyển slide **chỉ khi** player báo **onVideoEnded** → **nextSlide()** (tránh timer hết trước khi video decode xong gây giật).

**SlideshowWidget** (UI):

- **Chỉ render**: Stack 2 layer (slide hiện tại + slide kế tiếp), chuyển cảnh bằng AnimatedOpacity 200ms.
- **Không quyết định** khi nào preload/release; khi controller gọi callback thì widget thực thi (precache ảnh, evict ảnh).

### 4.3 Video: một Player, chỉ mở khi play

- **VideoService**: Một Player duy nhất (buffer 20MB), một VideoController.
- **Preload video**: Không gọi `player.open()`, chỉ kiểm tra file tồn tại (isFileReady) để tránh spike RAM.
- **Khi vào slide video**: MediaVideoWidget gọi `VideoService.open(fileUrl, play: true)` (mở và phát).
- **Loop**: Nghe position; khi `position >= duration - 200ms` → seek(0) rồi play() (loop mượt, tránh màn đen).
- **Nguồn**: Chỉ phát từ file ROM (`file://`); URL asset/relative được resolve thành đường dẫn file.

### 4.4 Dữ liệu media và ROM

- **RomMediaStorage**: Thư mục `standee_media/` với các thư mục con images, videos, audio, cache. Copy asset một lần; tải file từ API vào cache rồi chuyển sang images/videos; LRU khi vượt quota.
- **MediaRepository**: loadInitial từ Hive; định kỳ checkVersionAndUpdateIfNeeded (so sánh version API với local); nếu có bản mới thì refreshFromRemote (tải file qua RomMediaStorage, lưu playlist + localPath vào Hive).

---

## 5. Cách vận hành (tóm tắt)

| Thành phần | Vai trò |
|------------|--------|
| **AppBloc** | Quyết định màn hình theo trạng thái (Ready / Offline / Updating / Error). |
| **SlideshowController** | Quyết định slide hiện tại, preload next, release previous, timer (image/SDP), chuyển slide video khi onVideoEnded. |
| **SlideshowWidget** | Chỉ vẽ Stack 2 layer + fade; thực thi precache/evict khi controller yêu cầu. |
| **VideoService** | Một player; preload = check file; chỉ open khi play; loop bằng seek trước khi hết. |
| **MediaRepository + RomMediaStorage** | Offline-first: cache playlist (Hive), file media (ROM); cập nhật khi có version mới. |

**Luồng chuyển slide:**

- **Image/SDP**: Timer(durationSeconds) hết → nextSlide() → releasePrevious → preloadNext → _startTimer().
- **Video**: Player báo videoEnded → nextSlide() → releasePrevious → preloadNext → _startTimer() (timer chỉ có ý nghĩa cho slide tiếp theo nếu là image/SDP).

**Thiết kế hướng tới ổn định:**

- Một player video, không tạo/hủy theo từng video.
- Preload video không mở player; chỉ open khi thực sự phát.
- Timer không điều khiển video; video tự báo kết thúc rồi mới chuyển slide.
- Controller nắm logic; UI chỉ render và thực thi lệnh preload/release.
- Giới hạn image cache (6 ảnh, 30MB) và evict ảnh cũ khi chuyển slide.

---

Tài liệu này mô tả cấu trúc thư mục, thư viện, luồng hoạt động và cách vận hành hiện tại của ứng dụng Standee, dùng cho báo cáo mentor.
