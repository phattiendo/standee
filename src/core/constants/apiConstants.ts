const baseUrl = 'http://10.10.115.20:9094';
const wsBaseUrl = 'ws://10.10.115.20:9094';
const standeeId = '7bbb9af3-95a7-42af-8805-6023e60a3bdc';

export const apiConstants = {
  baseUrl,
  wsBaseUrl,
  standeeId,
  playlistPath: `/api/poster/${standeeId}/withActivePosters`,
  get playlistUrl() {
    return `${baseUrl}${this.playlistPath}`;
  },
  versionPath: '/api/standee/version',
  get versionUrl() {
    return `${baseUrl}${this.versionPath}`;
  },
  weatherWsPath: '/topic/weather',
  /** Raw WebSocket (nếu server dùng ws://host/ws/websocket). */
  weatherWsConnectPath: '/ws/websocket',
  get weatherWsConnectUrl() {
    return `${wsBaseUrl}${this.weatherWsConnectPath}`;
  },
  /** SockJS endpoint (nếu server trả /ws/390/{session}/websocket thì dùng cái này). */
  weatherWsSockJsPath: '/ws',
  get weatherWsSockJsUrl() {
    return `${baseUrl}${this.weatherWsSockJsPath}`;
  },
  /** true = dùng SockJS, false = dùng raw WebSocket. */
  weatherUseSockJs: true,
  airQualityPath: '/api/weather/air-quality',
  weatherPath: '/api/weather',
  speedTestPath: '/api/speedtest/all',
  standeeInfoPath: '/api/standee',
  /** GET /api/poster/{standeeId}/withActivePosters */
  getPosterPath(id: string) {
    return `/api/poster/${id}/withActivePosters`;
  },
  /** Nhạc nền: GET /audio/nhacbuoisang.mp3 */
  audioPath: '/audio/nhacbuoisang.mp3',
  get audioUrl() {
    return `${baseUrl}${this.audioPath}`;
  },
  sdpDurationSeconds: 40,
  sdpDefaultBackground: 'assets/tetve.jpg',
  /** Bật/tắt poster trong slideshow: true = SDP → poster → ...; false = chỉ hiển thị SDP lặp. */
  slideshowShowPosters: true,
  /** Bật/tắt video (catoon.mp4) trong slideshow: true = có slide video; false = không có. */
  slideshowShowVideo: false,
  /** Test hiệu ứng: 'rain' | 'storm' | 'cloudy' | 'flowers' | null. 'storm' = bão mưa to + sét. */
  weatherEffectOverride: null as 'rain' | 'storm' | 'cloudy' | 'flowers' | null, 
} as const;
