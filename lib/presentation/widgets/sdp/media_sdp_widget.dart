import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/api_constants.dart';
import '../../controllers/sdp_controller.dart';
import 'aqi_section.dart';
import 'health_advice_section.dart';
import 'speed_section.dart';
import 'weather_ambient_overlay.dart';
import 'weather_section.dart';

/// Widget chính hiển thị SDP (Special Dynamic Poster)
///
/// Design specs (base resolution ~1080x1920):
/// - Header: 1031 x 127, top: 25, left: 24
/// - Weather: 1035 x 582, top: 170, left: 21
/// - AQI: 500 x 290, top: 772, left: 21
/// - Speed: 500 x 290, top: 1082, left: 21
/// - Poster: 510 x 600, top: 772, left: 546
/// - Footer: 1035 x 504, top: 1392, left: 21, border-radius: 50
class MediaSdpWidget extends StatefulWidget {
  final String? posterUrl;
  final String? backgroundAsset;
  final bool showPoster;

  const MediaSdpWidget({
    super.key,
    this.posterUrl,
    this.backgroundAsset,
    this.showPoster = true,
  });

  @override
  State<MediaSdpWidget> createState() => _MediaSdpWidgetState();
}

class _MediaSdpWidgetState extends State<MediaSdpWidget> {
  late final SdpController _controller;
  SdpData _data = SdpData.empty();

  static const double _designWidth = 1080;
  static const double _designHeight = 1920;
  static const double _blurSigma = 18.0;

  @override
  void initState() {
    super.initState();
    _controller = SdpController(
      onDataChanged: (data) {
        if (mounted) {
          setState(() => _data = data);
        }
      },
    );
    _controller.init(posterUrl: widget.posterUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasNoDataYet =>
      _data.weather.isEmpty &&
      _data.airQuality.isEmpty &&
      _data.speedTest.isEmpty;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleX = constraints.maxWidth / _designWidth;
        final scaleY = constraints.maxHeight / _designHeight;
        final scale = scaleX < scaleY ? scaleX : scaleY;

        final content = Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          decoration: _buildBackground(),
          child: Stack(
            children: [
              if (_data.isLoading || _hasNoDataYet)
                Positioned.fill(
                  child: Container(
                    color: Colors.black38,
                    alignment: Alignment.center,
                    child: Text(
                      _data.isLoading
                          ? 'Đang tải dữ liệu...'
                          : 'Đang kết nối thời tiết & mạng...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20 * scale,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 25 * scaleY,
                left: 24 * scaleX,
                child: _buildGlassSection(
                  width: 1031 * scaleX,
                  height: 127 * scaleY,
                  borderRadius: 24 * scale,
                  child: _buildHeaderContent(scale),
                ),
              ),
              Positioned(
                top: 170 * scaleY,
                left: 21 * scaleX,
                child: Stack(
                  children: [
                    _buildGlassSection(
                      width: 1035 * scaleX,
                      height: 582 * scaleY,
                      borderRadius: 24 * scale,
                      child: const SizedBox.shrink(),
                    ),
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24 * scale),
                        child: WeatherAmbientOverlay(
                          weather: _data.weather,
                          enabled: true,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 1035 * scaleX,
                      height: 582 * scaleY,
                      child: Padding(
                        padding: EdgeInsets.all(16 * (1035 * scaleX / 500)),
                        child: WeatherSection(
                          weather: _data.weather,
                          scale: scale,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 772 * scaleY,
                left: 21 * scaleX,
                child: _buildGlassSection(
                  width: 500 * scaleX,
                  height: 290 * scaleY,
                  borderRadius: 24 * scale,
                  child: AqiSection(
                    airQuality: _data.airQuality,
                    scale: scale,
                  ),
                ),
              ),
              Positioned(
                top: 1082 * scaleY,
                left: 21 * scaleX,
                child: _buildGlassSection(
                  width: 500 * scaleX,
                  height: 290 * scaleY,
                  borderRadius: 24 * scale,
                  child: SpeedSection(
                    speedTest: _data.speedTest,
                    scale: scale,
                  ),
                ),
              ),
              if (widget.showPoster)
                Positioned(
                  top: 772 * scaleY,
                  left: 546 * scaleX,
                  child: _buildGlassSection(
                    width: 510 * scaleX,
                    height: 600 * scaleY,
                    borderRadius: 24 * scale,
                    padding: EdgeInsets.all(8 * scale),
                    child: _buildPosterContent(scale),
                  ),
                ),
              Positioned(
                top: 1392 * scaleY,
                left: 21 * scaleX,
                child: _buildGlassSection(
                  width: 1035 * scaleX,
                  height: 504 * scaleY,
                  borderRadius: 50 * scale,
                  child: HealthAdviceSection(
                    weather: _data.weather,
                    scale: scale,
                  ),
                ),
              ),
            ],
          ),
        );

        return content;
      },
    );
  }

  Widget _buildGlassSection({
    required double width,
    required double height,
    required double borderRadius,
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    final effectivePadding = padding ?? EdgeInsets.all(16 * (width / 500));

    final content = SizedBox(
      width: width,
      height: height,
      child: Padding(
        padding: effectivePadding,
        child: child,
      ),
    );

    return _buildBackdropGlass(
      width: width,
      height: height,
      borderRadius: borderRadius,
      child: content,
    );
  }

  Widget _buildBackdropGlass({
    required double width,
    required double height,
    required double borderRadius,
    required Widget child,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromRGBO(255, 255, 255, 0.25),
                  Color.fromRGBO(255, 255, 255, 0.10),
                ],
              ),
              border: Border.all(
                color: const Color.fromRGBO(255, 255, 255, 0.30),
                width: 1.2,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.center,
                        colors: [
                          Color.fromRGBO(255, 255, 255, 0.40),
                          Color.fromRGBO(255, 255, 255, 0.0),
                        ],
                        stops: [0.0, 0.5],
                      ),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBackground() {
    final bgAsset = (widget.backgroundAsset != null && widget.backgroundAsset!.isNotEmpty)
        ? widget.backgroundAsset
        : ApiConstants.sdpDefaultBackground;
    if (bgAsset != null && bgAsset.isNotEmpty) {
      return BoxDecoration(
        image: DecorationImage(
          image: AssetImage(bgAsset),
          fit: BoxFit.cover,
        ),
      );
    }

    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFAB40),
          Color(0xFFFF6D00),
          Color(0xFFE65100),
        ],
        stops: [0.0, 0.5, 1.0],
      ),
    );
  }

  Widget _buildHeaderContent(double scale) {
    // Lấy thông tin từ StandeeInfo
    final standeeInfo = _data.standeeInfo;
    final displayName = standeeInfo.isEmpty 
        ? 'Block B10' // Default fallback
        : standeeInfo.displayName;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/eiu15.svg',
          height: 55 * scale,
          fit: BoxFit.contain,
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 28 * scale,
            vertical: 12 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14 * scale),
          ),
          child: Text(
            displayName,
            style: TextStyle(
              color: const Color(0xFFE65100),
              fontSize: 28 * scale,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const Spacer(),
        SvgPicture.asset(
          'assets/powerd-by-IIC-logo.svg',
          height: 55 * scale,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  Widget _buildPosterContent(double scale) {
    final posterUrl = _data.posterUrl ?? widget.posterUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16 * scale),
      child: _buildPosterImage(posterUrl, scale),
    );
  }

  Widget _buildPosterImage(String? url, double scale) {
    if (url == null || url.isEmpty) {
      return Image.asset(
        'assets/image 1.png',
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildPosterPlaceholder(scale),
      );
    }
    final placeholder = _buildPosterPlaceholder(scale);
    if (url.startsWith('/') || url.startsWith('file://')) {
      final path = url.startsWith('file://') ? url.substring(7) : url;
      return Image.file(
        File(path),
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      );
    }
    return Image.asset(
      'assets/image 1.png',
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }

  Widget _buildPosterPlaceholder(double scale) {
    return Container(
      color: Colors.white.withValues(alpha: 0.3),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image,
              size: 56 * scale,
              color: Colors.white70,
            ),
            SizedBox(height: 10 * scale),
            Text(
              'Poster',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18 * scale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
