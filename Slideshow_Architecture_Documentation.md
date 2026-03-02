SLIDESHOW ARCHITECTURE DOCUMENTATION
I. Folder Structure
lib/
│
├── core/
│   ├── network/
│   │   └── dio_client.dart
│   │
│   ├── connectivity/
│   │   └── connectivity_service.dart
│   │
│   └── constants/
│       └── api_constants.dart
│
├── data/
│   ├── models/
│   │   └── media_item_model.dart
│   │
│   ├── datasources/
│   │   ├── remote_media_datasource.dart
│   │   └── local_media_datasource.dart
│   │
│   └── repositories/
│       └── media_repository.dart
│
├── presentation/
│   ├── controllers/
│   │   └── slideshow_controller.dart
│   │
│   ├── widgets/
│   │   ├── slideshow_widget.dart
│   │   ├── media_image_widget.dart
│   │   └── media_video_widget.dart
│   │
│   └── screens/
│       └── slideshow_screen.dart
│
└── main.dart
II. Libraries Used
- dio (API calls)
- cached_network_image (Image caching)
- video_player (Video playback)
- connectivity_plus (Network detection)
- hive (Local storage / offline cache)
III. Functional Overview
Main Features:
- Fetch media list (image + video) from API
- Cache data locally for offline usage
- Auto slideshow (10 seconds per item)
- Infinite loop
- Retry when network reconnects
- Smooth transition animation
IV. Media Model Design
enum MediaType { image, video }

class MediaItem {
  final String url;
  final MediaType type;

  MediaItem({
    required this.url,
    required this.type,
  });
}
V. Application Flow
When screen opens:
1. Initialize controller
2. Load local cache (Hive)
3. Display cached data immediately (if exists)
4. Fetch API in background
5. If success → update list & save to Hive
6. If fail → keep old data
7. Start slideshow timer
VI. Slideshow Timer Logic
Timer triggers every 10 seconds:
- currentIndex++
- AnimatedSwitcher runs
- Old media fades out
- New media fades in
- Old widget removed from tree
- Bitmap remains in image cache
VII. Offline Handling
If network is lost:
- Do not crash
- Continue showing cached data
- Listen for connectivity change
- Retry API automatically when network returns
VIII. Edge Cases Handling
1. Slow image loading → Show placeholder
2. API returns empty list → Show default banner
3. API structure changes → Use versioned endpoints (v1, v2)
4. Weak GPU device → Avoid heavy animations & effects
5. App killed → Reload from Hive cache
IX. Architecture Advantages
- Clean separation of concerns
- Easily extendable (image → video)
- Production-ready
- Offline-first approach
- Not over-engineered
- Easy to migrate to Riverpod or BLoC later
