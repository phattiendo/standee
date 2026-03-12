# Lottie thời tiết (ô thời tiết)

Hiệu ứng trong ô thời tiết dùng [lottie-react-native](https://github.com/lottie-react-native/lottie-react-native). Mặc định app dùng JSON từ CDN (LottieFiles).

Nếu muốn dùng file local (không cần mạng), tải animation từ [LottieFiles](https://lottiefiles.com) và đặt vào thư mục này:

- **clear** (nắng): lá rơi / cánh hoa — lưu thành `clear.json` hoặc dùng URL trong `WeatherLottieView.tsx`
- **cloudy** (nhiều mây): mây bay — `cloudy.json`
- **rain** (mưa): mưa rơi — `rain.json`

Trong `WeatherLottieView.tsx` có thể đổi `LOTTIE_SOURCES` sang `require('./clear.json')` v.v. nếu bạn thêm file vào đây.
