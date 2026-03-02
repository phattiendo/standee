# Mock Data System

Hệ thống mock data cho Standee app, dùng để demo/testing khi không có API thật.

## Cách sử dụng

### Bật/Tắt Mock Mode

Chỉnh sửa file `lib/core/config/app_config.dart`:

```dart
/// Bật mock mode = true để dùng data giả
/// Tắt mock mode = false để dùng API thật
static const bool useMockData = true;
```

### Cấu trúc Mock Data

File mock data nằm ở `assets/mock/mock_data.json`:

```json
{
  "weather": { ... },        // Dữ liệu thời tiết
  "airQuality": { ... },     // Chất lượng không khí
  "speedTest": { ... },      // Kết quả speed test
  "standeeInfo": { ... },    // Thông tin standee
  "mediaList": [ ... ]       // Danh sách media (image/video/sdp)
}
```

### Mock Data Fields

#### Weather
- `temperature`: Nhiệt độ hiện tại (°C)
- `humidity`: Độ ẩm (%)
- `weatherCode`: Mã thời tiết WMO (0=sunny, 1-3=cloudy, 61-65=rainy, etc.)
- `uv_index`: Chỉ số UV
- `hourly`: Dự báo theo giờ

#### Air Quality
- `pm2_5`, `pm10`: Nồng độ bụi mịn
- `us_aqi`: Chỉ số chất lượng không khí (0-500)
- `ozone`, `carbon_monoxide`, etc.: Các chỉ số khí

#### Speed Test
- `downloadSpeed`: Tốc độ download (Mbps)
- `uploadSpeed`: Tốc độ upload (Mbps)
- `ping`: Độ trễ (ms)

#### Media List
- `type`: "image" | "video" | "sdp"
- `url`: Đường dẫn media (dùng `asset:` prefix cho local assets)
- `durationSeconds`: Thời gian hiển thị

### Local Assets trong Mock

Để dùng local assets trong mock, sử dụng prefix `asset:`:

```json
{
  "url": "asset:assets/image.png",
  "type": "image"
}
```

## Files

- `assets/mock/mock_data.json` - Mock data JSON
- `lib/data/datasources/mock_datasource.dart` - Mock datasource singleton
- `lib/core/config/app_config.dart` - Config bật/tắt mock mode
