import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/core/l10n/locale_provider.dart';

/// Xaritadan manzil tanlash ekrani.
/// Foydalanuvchi xaritani suradi — markazdagi belgi tanlangan nuqtani
/// ko'rsatadi. Tasdiqlaganda OpenStreetMap Nominatim orqali manzil
/// avtomatik aniqlanadi va natija (lat/lng/address) qaytariladi.
class MapPickerResult {
  final double lat;
  final double lng;
  final String address;

  const MapPickerResult({
    required this.lat,
    required this.lng,
    required this.address,
  });
}

class MapPickerScreen extends StatefulWidget {
  /// Oldindan tanlangan nuqta (bo'lsa) — xaritani shu yerga markazlaydi.
  final double? initialLat;
  final double? initialLng;

  const MapPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  // Toshkent markazi — standart nuqta
  static const LatLng _tashkent = LatLng(41.2995, 69.2401);

  final MapController _mapController = MapController();
  late LatLng _center;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _center = (widget.initialLat != null && widget.initialLng != null)
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : _tashkent;
  }

  /// Qurilma geolokatsiyasi orqali foydalanuvchi joylashuviga o'tish.
  Future<void> _goToMyLocation() async {
    final loc = context.read<LocaleProvider>();
    try {
      // Joylashuv xizmati yoqilganini tekshiramiz
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('service disabled');

      // Ruxsatni so'raymiz
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('permission denied');
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final target = LatLng(pos.latitude, pos.longitude);
      _mapController.move(target, 16);
      setState(() => _center = target);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('map.locationError'))),
      );
    }
  }

  /// Nominatim reverse geocoding — koordinatadan manzil matni.
  Future<String> _reverseGeocode(double lat, double lng) async {
    final lang = context.read<LocaleProvider>().lang; // uz / ru
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=json&lat=$lat&lon=$lng&accept-language=$lang&zoom=18',
    );
    try {
      final resp = await http.get(
        url,
        headers: const {'User-Agent': 'BasicStore/1.0 (customer-app)'},
      ).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final name = data['display_name'];
        if (name is String && name.isNotEmpty) return name;
      }
    } catch (_) {
      // Tarmoq xatosida koordinatani matn sifatida qaytaramiz
    }
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  Future<void> _confirm() async {
    setState(() => _isResolving = true);
    final address = await _reverseGeocode(_center.latitude, _center.longitude);
    if (!mounted) return;
    setState(() => _isResolving = false);
    Navigator.pop(
      context,
      MapPickerResult(
        lat: _center.latitude,
        lng: _center.longitude,
        address: address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.t('map.title').toUpperCase(),
          style: GoogleFonts.playfairDisplay(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14,
              onPositionChanged: (camera, hasGesture) {
                _center = camera.center;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'uz.basicstore.customer',
                maxZoom: 19,
              ),
            ],
          ),

          // Markazdagi qo'zg'almas belgi (tanlangan nuqta)
          const Padding(
            padding: EdgeInsets.only(bottom: 40),
            child: Icon(
              Icons.location_on,
              color: Colors.black,
              size: 48,
            ),
          ),

          // Yo'riqnoma banner — yuqorida
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.black),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loc.t('map.hint'),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Mening joylashuvim tugmasi
          Positioned(
            right: 16,
            bottom: 96,
            child: FloatingActionButton(
              heroTag: 'myLocation',
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 2,
              onPressed: _goToMyLocation,
              child: const Icon(Icons.my_location),
            ),
          ),

          // Tasdiqlash tugmasi — pastda
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isResolving ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const RoundedRectangleBorder(),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isResolving
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            loc.t('map.searching'),
                            style: const TextStyle(letterSpacing: 1),
                          ),
                        ],
                      )
                    : Text(
                        loc.t('map.confirm').toUpperCase(),
                        style: const TextStyle(letterSpacing: 1),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
