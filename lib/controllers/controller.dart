import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:cn_pocket_hr/services/security_service.dart';

class HRController {
  double? latitude;
  double? longitude;
  String? address;
  StreamSubscription<Position>? streamSubscription;
  List<Map<String, double?>> location = [];

  void onInit() {
    getLocation();
  }

  void onReady() {}

  void onClose() {
    streamSubscription?.cancel();
  }

  Future<void> getLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    await streamSubscription?.cancel();
    streamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      ),
    ).listen((Position position) async {
      final isClean = await SecurityService.verifyPosition(position);
      if (!isClean) return;

      latitude = position.latitude;
      longitude = position.longitude;
      final loc = {'latitude': latitude, 'longitude': longitude};
      await getAddressFromLatLang(position);
      location.add(loc);
    });
  }

  Future<String?> getAddressFromLatLang(Position position) async {
    try {
      final placemark =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemark.isNotEmpty) {
        final place = placemark.first;
        address = '${place.locality ?? ''},${place.country ?? ''}';
      }
    } catch (_) {}
    return address;
  }

  String formatISOTime(DateTime date) {
    final duration = date.timeZoneOffset;
    final sign = duration.isNegative ? '-' : '+';
    final hours = duration.inHours.abs().toString().padLeft(2, '0');
    final minutes =
        (duration.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '${DateFormat("yyyy-MM-ddTHH:mm:ss").format(date)}$sign$hours$minutes';
  }
}
