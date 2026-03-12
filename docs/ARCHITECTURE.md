# Kiến trúc hệ thống – React Native Digital Standee

## 1. Tổng quan hệ thống

Ứng dụng Digital Standee chạy trên Android box (RAM 1–2GB), hoạt động 24/7.

**Trách nhiệm chính:**
- Hiển thị poster (ảnh)
- Phát video mượt
- Hiển thị SDP (Smart Data Poster)
- Lấy playlist từ API
- Tải và cache media local (ROM)
- Preload media tiếp theo
- Tránh khung đen giữa các video

---

## 2. Slideshow = “lật album” full màn hình

**Một slide = cả màn hình** là một trong ba loại:

| Slide    | Nội dung full màn hình                    |
|----------|------------------------------------------|
| **SDP**  | Layout SDP: header, thời tiết, AQI, tốc độ mạng, **ô bên phải chỉ poster (ảnh)** |
| **Poster** | Một tấm ảnh poster phủ full màn hình   |
| **Video** | Một video phủ full màn hình            |

**Luồng:** SDP → Poster A → Poster B → Video → SDP → … (lặp vô hạn).

**Bổ sung:** Trong màn SDP, **ô bên phải chỉ hiển thị poster (ảnh)**, không hiển thị video. Video chỉ xuất hiện khi slide hiện tại là slide **Video** (full màn hình).

---

## 3. Kiến trúc high-level (Advanced)

**Core modules:**
1. **API Layer** – Gọi API playlist, standee, device
2. **Media Sync Service** – Đồng bộ media (tải thiếu về ROM)
3. **Local Media Cache** – Lưu ảnh/video trong ROM
4. **Media Engine** – Load media, lifecycle player, dọn tài nguyên, preload
5. **Slideshow Controller** – Điều khiển thứ tự slide, timer, state machine
6. **SDP Engine** – Dữ liệu SDP (giờ, thời tiết, AQI, metrics)
7. **Rendering Layer** – Vẽ SDP / PosterView / VideoView

**Luồng khởi động:**
```
Boot
  ↓
Fetch Playlist
  ↓
Sync Media (download thiếu về ROM)
  ↓
Preload First Items
  ↓
Start Slideshow
  ↓
Loop Forever
```

---

## 4. Cấu trúc thư mục (Production)

```
src/
  core/           appBootstrap.js, config.js
  api/            httpClient.js, playlistService.js, deviceService.js
  media/          mediaEngine.js, videoEngine.js, imageEngine.js
  storage/        mediaCache.js, downloadManager.js
  slideshow/      slideshowController.js, slideStateMachine.js
  sdp/            sdpEngine.js, sdpRenderer.js
  components/     PosterView.js, VideoView.js, SDPView.js
  screens/        StandeePlayerScreen.js
```

---

## 5. API Design

API trả về cấu hình playlist. Ví dụ:

```json
{
  "deviceId": "standee_01",
  "playlist": [
    { "id": "1", "type": "poster", "url": "https://cdn/poster.jpg", "duration": 10 },
    { "id": "2", "type": "video", "url": "https://cdn/video.mp4" },
    { "id": "3", "type": "sdp" }
  ]
}
```

App cần: validate dữ liệu, phát hiện nội dung mới, kích hoạt đồng bộ media.

---

## 6. Media Synchronization

Quy trình nền tải media thiếu:

- Với mỗi item trong playlist: nếu chưa có local → tải về → lưu ROM → cập nhật cache index.
- Đường dẫn local ví dụ: `/storage/standee_media/videos/`, `/storage/standee_media/images/`.
- **Luôn phát từ local storage**, không stream trực tiếp từ mạng.

---

## 7. Media Engine

**Trách nhiệm:** load media, lifecycle player, dọn tài nguyên, preload item tiếp theo.

**Quy tắc:**
- Chỉ **một** instance video player cho toàn app.
- Player tồn tại suốt vòng đời app.
- Đổi nội dung bằng cách **đổi source** của player, không tạo player mới.

---

## 8. Chiến lược phát video

Dùng `react-native-video` với hardware decoding.

```
prepareVideo(nextVideo)
  ↓ load metadata
  ↓ warm decoder
  ↓ render first frame
  ↓ chờ đến lúc chuyển slide
  ↓ play ngay
```

→ Tránh khung đen giữa các vòng lặp.

---

## 9. Preload

Luôn chuẩn bị **slide tiếp theo**.

Ví dụ playlist: Poster A → Poster B → Video C → SDP.

- Đang phát Poster A → preload Poster B.
- Đang phát Poster B → preload Video C.
- Tương tự cho SDP và các slide khác.

---

## 10. Slideshow State Machine

Các trạng thái:

- **IDLE**
- **PREPARING**
- **PLAYING_POSTER**
- **PLAYING_VIDEO**
- **PLAYING_SDP**
- **TRANSITION**

Chuyển trạng thái do **SlideshowController** điều khiển.

---

## 11. SDP Engine

SDP = Smart Data Poster. Nguồn dữ liệu: giờ hiện tại, Weather API, AQI, metrics backend.

- Cập nhật: **refresh mỗi 5 phút**.
- UI cập nhật qua React state.

---

## 12. Tối ưu hiệu năng

1. Không stream video từ mạng.
2. Luôn phát từ ROM.
3. Giới hạn độ phân giải ảnh.
4. Dùng hardware decode cho video.
5. Chỉ 1 player đang active.
6. Release media không dùng.

---

## 13. Chiến lược bộ nhớ

Mục tiêu RAM ổn định (~300MB hoặc thấp hơn).

- Tối đa 1 video decoder.
- Tối đa 2 ảnh preload.
- Không nhiều video buffer cùng lúc.
- Tránh object JS lớn.

---

## 14. Chuẩn encode video

- Resolution: 1280×720  
- Codec: H.264  
- Bitrate: 3–6 Mbps  
- FPS: 30  
- Tránh 4K hoặc bitrate quá cao.

---

## 15. 24/7 Stability

- **Memory watchdog** – theo dõi RAM.
- **Crash auto restart** – tự khởi động lại khi crash.
- **Playlist refresh** – làm mới playlist (ví dụ mỗi 30 phút).
- **Media integrity check** – kiểm tra file media còn dùng được.

---

## 16. Deployment

```
Device Boot
  ↓
Auto start app
  ↓
Sync playlist
  ↓
Download media
  ↓
Start slideshow
  ↓
Loop infinitely
```

---

## 17. Thư viện production đề xuất

### Nên thêm cho standee 24/7

| Thư viện | Mục đích |
|----------|----------|
| **react-native-restart** | App restart watchdog: memory leak, video crash, update playlist → restart app |
| **react-native-background-fetch** | Sync media nền: 30 phút sync playlist, download media |
| **react-native-device-info** | Thông tin thiết bị: deviceId, model, RAM, storage (gửi API / hiển thị) |

### Không cần thêm

- **expo-av**, **video.js**, **vlc** — `react-native-video` đã đủ cho phát video.

### Bộ thư viện production chuẩn

- axios  
- zustand  
- react-native-video  
- react-native-fast-image  
- react-native-fs  
- react-native-mmkv  
- react-native-device-info  
- react-native-background-fetch  
- react-native-restart  
- sockjs-client  
- @stomp/stompjs  
- react-native-svg  

---

## Tóm tắt bổ sung về SDP và ô poster

- **SDP** là một loại slide full màn hình: layout SDP (header, thời tiết, AQI, tốc độ, ô bên phải).
- **Ô bên phải trong SDP** chỉ hiển thị **poster (ảnh)** từ API, **không hiển thị video**. Video chỉ xuất hiện ở slide full màn hình kiểu **Video**.
