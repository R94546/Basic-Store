import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/video_background_provider.dart';

/// ZARA uslubida HomeScreen - video orqa fon bilan
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVideo();
    });
  }

  Future<void> _initializeVideo() async {
    final provider = context.read<VideoBackgroundProvider>();
    await provider.initialize();
    
    _videoController = VideoPlayerController.asset(provider.currentVideoPath);
    
    try {
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(0); // Tovushsiz
      await _videoController!.play();
      
      if (mounted) {
        setState(() => _isVideoInitialized = true);
      }
    } catch (e) {
      debugPrint('Video initialization error: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Background (full screen)
          if (_isVideoInitialized && _videoController != null)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),
          
          // Gradient overlay (ZARA style - darker at bottom)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          
          // Content overlay
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                
                // BASIC STORE Logo (center, ZARA style)
                Text(
                  'BASIC\nSTORE',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 64,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 12.0,
                    height: 1.1,
                    color: Colors.white,
                  ),
                ),
                
                const Spacer(),
                
                // Bottom buttons (ZARA style)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: Column(
                    children: [
                      // Primary button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            // Navigate to shop - will use BottomNav automatically
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white, width: 1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(),
                          ),
                          child: const Text(
                            'KIRISH',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Location info
                      const Text(
                        'TASHKENT, UZBEKISTAN',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Loading indicator while video loads
          if (!_isVideoInitialized)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
