# Mock Data Guide - Standee App

## Mục đích
File này hướng dẫn cách chạy app với **mock data** (dữ liệu giả) để test/review code mà không cần kết nối API thật.

---

## Cách bật/tắt Mock Mode

Mở file `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  /// Bật mock mode = true để dùng data giả từ assets/mock/
  /// Tắt mock mode = false để dùng API thật
  static const bool useMockData = true;  // ← Thay đổi ở đây
}
```

- `useMockData = true` → App dùng data từ `assets/mock/mock_data.json`
- `useMockData = false` → App gọi API thật

---

## Cấu trúc Mock Data

### File: `assets/mock/mock_data.json`

```json
{
  "weather": { ... },      // Dữ liệu thời tiết
  "airQuality": { ... },   // Chất lượng không khí (AQI)
  "speedTest": { ... },    // Tốc độ internet
  "standeeInfo": { ... },  // Thông tin standee
  "mediaList": [ ... ]     // Danh sách poster/video
}
```

### Ảnh poster mock

Đặt ảnh poster vào thư mục `assets/mock/` và cập nhật `mediaList` trong JSON:

```json
"mediaList": [
  {
    "url": "asset:assets/mock/poster1.jpg",
    "type": "image",
    "durationSeconds": 10
  },
  {
    "url": "asset:assets/mock/poster2.jpg",
    "type": "image",
    "durationSeconds": 10
  }
]
```

**Lưu ý**: URL bắt đầu bằng `asset:` để chỉ định đây là file local trong assets.

### Video mock

```json
{
  "url": "asset:assets/mock/sample_video.mp4",
  "type": "video",
  "durationSeconds": 30
}
```

---

## Cách thêm poster mock

1. Copy ảnh vào `assets/mock/` (VD: `poster1.jpg`, `poster2.jpg`)
2. Mở `assets/mock/mock_data.json`
3. Thêm vào array `mediaList`:

```json
{
  "url": "asset:assets/mock/poster1.jpg",
  "type": "image",
  "durationSeconds": 10
}
```

4. Run `flutter pub get`
5. Hot restart app

---

## Dữ liệu mẫu

### Weather (Thời tiết)
```json
{
  "current": {
    "time": "2026-02-26T10:00",
    "temperature": 28.5,
    "humidity": 65,
    "weatherCode": 2,
    "uv_index": 6.2
  },
  "daily": {
    "temperature_2m_max": 32.0,
    "temperature_2m_min": 24.5
  },
  "hourly": {
    "time": ["2026-02-26T10:00", ...],
    "temperature_2m": [28.5, 29.2, ...],
    "weather_code": [2, 2, ...]
  }
}
```

### Air Quality (Chất lượng không khí)
```json
{
  "code": 200,
  "result": {
    "time": "2026-02-26T10:00",
    "pm2_5": 15.8,
    "pm10": 22.3,
    "sulphur_dioxide": 5.2,
    "nitrogen_dioxide": 8.1,
    "ozone": 95.5,
    "carbon_monoxide": 210.0,
    "us_aqi": 52
  }
}
```

### Speed Test (Tốc độ internet)
```json
{
  "code": 200,
  "result": [
    {
      "id": 1,
      "downloadSpeed": 85.6,
      "uploadSpeed": 42.3,
      "ping": 18,
      "timestamp": "2026-02-26T09:45:00Z"
    }
  ]
}
```

### Standee Info
```json
{
  "standeeId": "STD-001",
  "standeeName": "Main Lobby Standee",
  "alias": "B10",
  "mainTitle": "EIU Campus",
  "subTitle": "Innovation Center",
  "displayDuration": 40,
  "spaceId": "SPACE-001"
}
```

---

## Debug Panel

App có debug panel để bật/tắt từng loại content:
- SDP (Special Dynamic Poster)
- Poster
- Video
- Audio

Xem `SlideshowConfig` trong `lib/presentation/config/slideshow_config.dart`.

---

## Lưu ý

1. Sau khi sửa `mock_data.json`, cần **hot restart** (không chỉ hot reload)
2. Đảm bảo ảnh/video mock được khai báo trong `pubspec.yaml` (đã có `assets/mock/`)
3. Mock mode bỏ qua WebSocket, chỉ dùng data tĩnh

---

## File liên quan

- `lib/core/config/app_config.dart` - Cấu hình mock mode
- `lib/data/datasources/mock_datasource.dart` - Load mock data
- `assets/mock/mock_data.json` - Mock data JSON
- `assets/mock/*.jpg` - Ảnh poster mock
