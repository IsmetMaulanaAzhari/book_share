import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  String _currentAddress = '';
  bool _isLoading = false;
  String? _errorMessage;

  Position? get currentPosition => _currentPosition;
  String get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Default: Jakarta
  double get latitude => _currentPosition?.latitude ?? -6.2088;
  double get longitude => _currentPosition?.longitude ?? 106.8456;

  Future<bool> checkPermission() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Location services are disabled.';
        notifyListeners();
        return false;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Location permissions are denied.';
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Location permissions are permanently denied.';
        notifyListeners();
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Permission check error: $e');
      return false;
    }
  }

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // On web, geolocation may not work well
      if (kIsWeb) {
        // Use default location for web
        _currentAddress = 'Jakarta, Indonesia (Default)';
        _isLoading = false;
        notifyListeners();
        return;
      }

      bool hasPermission = await checkPermission();
      if (!hasPermission) {
        // Use default location if permission denied
        _currentAddress = 'Lokasi default (Jakarta)';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await _getAddressFromLatLng();
    } catch (e) {
      debugPrint('Location error: $e');
      _currentAddress = 'Lokasi default (Jakarta)';
      // Don't set error message to allow app to continue with default location
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _getAddressFromLatLng() async {
    if (_currentPosition == null) return;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentAddress = '${place.street}, ${place.subLocality}, ${place.locality}';
      }
    } catch (e) {
      _currentAddress = 'Unable to get address';
    }
  }

  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.subLocality}, ${place.locality}';
      }
    } catch (e) {
      return 'Unknown location';
    }
    return 'Unknown location';
  }

  // Haversine formula untuk menghitung jarak antara dua koordinat
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Return in km
  }
}
