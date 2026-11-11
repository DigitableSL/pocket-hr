import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cn_pocket_hr/Screens/qr/qr_scanner_page.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
 import 'package:geolocator/geolocator.dart';
import 'package:localstorage/localstorage.dart';
import 'package:cn_pocket_hr/services/offline_attendance_service.dart';
import 'package:cn_pocket_hr/services/security_service.dart';
import 'package:octo_image/octo_image.dart';
import 'package:cn_pocket_hr/constants/slideanimation.dart';
import 'package:cn_pocket_hr/screens/notifications/notifications.dart';
import 'package:cn_pocket_hr/services/fcm_service.dart';
import 'package:cn_pocket_hr/api/api_service.dart';
import 'package:cn_pocket_hr/controllers/controller.dart';
import 'package:cn_pocket_hr/helpers/design_config.dart';
import 'package:cn_pocket_hr/helpers/glass_box.dart';
import 'package:cn_pocket_hr/helpers/hr_colors.dart';
import 'package:cn_pocket_hr/config/flavor_config.dart';
import 'package:cn_pocket_hr/helpers/custom_blur_hash.dart';
import 'package:cn_pocket_hr/models/slider_model.dart';
import 'package:cn_pocket_hr/models/hr/check_in_check_out_model.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:cn_pocket_hr/models/hr/location_model.dart';
import 'package:cn_pocket_hr/providers/connection_provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
// import 'package:audioplayers/audioplayers.dart';

class MobileHome extends StatefulWidget {
  const MobileHome({Key? key}) : super(key: key);

  @override
  _MobileHomeState createState() => _MobileHomeState();
}

class _MobileHomeState extends State<MobileHome> with TickerProviderStateMixin {
  int currentIndex = 0;
  AnimationController? _animationController;
  PageController? _controller;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  //late AudioPlayer _audioPlayer;

  String morningBg = FlavorConfig.instance.morningBg;
  String afternoonBg = FlavorConfig.instance.afternoonBg;
  String eveningBg = FlavorConfig.instance.eveningBg;
  String nightBg = FlavorConfig.instance.nightBg;

  late String bgImg;
  String? _dateTime;
  late Timer _timer;
  late String checking = "CHECK-IN";
  final DateTime now = DateTime.now();
  LocalStorage storage = LocalStorage('pocketHR');
  APIService apiService = APIService();
  HRController controller = HRController();
  bool _qrBusy = false;

  // Brief cooldown after punch (prevents double-punch)
  bool _punchCooldown = false;
  Timer? _cooldownTimer;

  // Blink animation while QR window is active
  AnimationController? _blinkController;

  // Top toast overlay
  void showTopToast(String message,
      {Color? background,
      Duration duration = const Duration(seconds: 3),
      VoidCallback? onTap}) {
    final overlay = Overlay.of(context);

    final animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    final animation =
        CurvedAnimation(parent: animController, curve: Curves.easeOut);

    late OverlayEntry entry;
    entry = OverlayEntry(builder: (ctx) {
      return Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 12,
        right: 12,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
              .animate(animation),
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                try {
                  animController.reverse();
                } catch (_) {}
                try {
                  entry.remove();
                } catch (_) {}
                try {
                  animController.dispose();
                } catch (_) {}
                if (onTap != null) onTap();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: background ?? const Color(0xFF323232),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(message,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });

    overlay.insert(entry);
    animController.forward();

    Future.delayed(duration, () async {
      try {
        await animController.reverse();
      } catch (_) {}
      try {
        entry.remove();
      } catch (_) {}
      try {
        animController.dispose();
      } catch (_) {}
    });
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    getLocation();
    // changeBTN();
    _controller = PageController(initialPage: 0);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _timer = new Timer.periodic(Duration(seconds: 1), (Timer t) => getTime());
    _animationController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 1500));

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    // audio player for countdown sound
    //_audioPlayer = AudioPlayer();
   // _audioPlayer.setReleaseMode(ReleaseMode.stop);

    // Refresh profile from API if storage was cleared (e.g. after logout+login).
    // Runs after the first frame so the UI appears immediately, then updates.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await storage.ready;
        if (storage.getItem('me_profile') == null) {
          await apiService.fetchMeProfileWithBearer();
          if (mounted) setState(() {});
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    try {
      _cooldownTimer?.cancel();
    } catch (_) {}
    try {
      _blinkController?.dispose();
    } catch (_) {}
    try {
   //   _audioPlayer.stop();
    //  _audioPlayer.dispose();
    } catch (_) {}
    _timer.cancel();
    streamSubscription.cancel();
    _animationController!.dispose();
    super.dispose();
  }

  getTime() {
    String languageCode = Localizations.localeOf(context).languageCode;
    String formattedDateTime = "";
    String suffix = 'th';
    final int digit = now.day % 10;
    if ((digit > 0 && digit < 4) && (now.day < 11 || now.day > 13)) {
      suffix = <String>['st', 'nd', 'rd'][digit - 1];
    }

    if (languageCode == 'si' || languageCode == 'ta') {
      formattedDateTime = DateFormat("dd MMM yyyy - kk:mm:ss", languageCode)
          .format(DateTime.now())
          .toString();
    } else {
      formattedDateTime =
          DateFormat("d'$suffix' MMM yyyy - kk:mm:ss", languageCode)
              .format(DateTime.now())
              .toString();
    }

    setState(() {
      _dateTime = formattedDateTime;
    });
  }

  checkinCheckout(type, {bool isRemote = false}) async {
    final isSecure = await SecurityService.verifyDeviceSecurity(
      currentPosition: _currentPosition,
      context: context,
    );
    if (!isSecure) return;

    DateTime getCurrentTimestamp = DateTime.now();
    String date = controller.formatISOTime(getCurrentTimestamp);

    final useQrLocation = !isRemote && qrLatitude != null;
    final activeLat = useQrLocation ? qrLatitude : latitude;
    final activeLng = useQrLocation ? qrLongitude : longitude;
    final activeAddr = useQrLocation ? (qrAddress ?? address) : address;
    final activeAcc = useQrLocation ? qrAccuracy : accuracy;

    final latStr = (activeLat != null) ? activeLat.toString() : null;
    final lngStr = (activeLng != null) ? activeLng.toString() : null;
    final addr = (activeAddr != null) ? activeAddr.toString() : null;
    final accStr = (activeAcc != null) ? activeAcc.toString() : null;

    final attendanceId = DateTime.now().millisecondsSinceEpoch.toString();
    final model = AttendancePunchModel(
      attendanceId: attendanceId,
      uid: storage.getItem('uid')?.toString() ?? 'local',
      type: type,
      time: date,
      lat: (activeLat is double)
          ? activeLat
          : double.tryParse(activeLat?.toString() ?? '') ?? 0.0,
      lng: (activeLng is double)
          ? activeLng
          : double.tryParse(activeLng?.toString() ?? '') ?? 0.0,
      address: activeAddr ?? '',
      deviceId: '',
      deviceModel: '',
      deviceBrand: '',
      devicePlatform: '',
      deviceVersion: '',
      deviceIdentifier: '',
      deviceIp: '',
      batteryLevel: 0,
      tenant: storage.getItem('company') ?? '',
      isRemote: isRemote ? 1 : 0,
      isSynced: 0,
    );

    // 🔹 STEP 1: ALL records are FIRST saved to local Drift SQLite DB
    try {
      await OfflineAttendanceService.instance.insertPunch(model);
      print('[PUNCH STEP 1] 💾 Saved punch locally into Drift SQLite DB FIRST (ID: $attendanceId, isSynced: 0)');
    } catch (e) {
      print('[DB ERROR] Failed inserting punch to Drift DB: $e');
    }

    // Check network connectivity
    final conn = Provider.of<ConnectionProvider>(context, listen: false);
    if (!conn.isOnline) {
      print('[PUNCH STEP 2] 📡 Device is Offline. Punch stays queued in Drift DB (isSynced: 0).');
      if (mounted) {
        showTopToast(
          AppLocalizations.of(context)!.savedLocallyWillSyncWhenOnline,
          background: Colors.orange,
        );
      }
      return;
    }

    // STEP 2: If online and server is reachable, attempt sending punch to backend
    print('[PUNCH STEP 2] 🌐 Device is Online. Sending punch to backend API...');
    Map? res;
    try {
      res = await apiService.checkInCheckout(
        date,
        type,
        latitude: latStr,
        longitude: lngStr,
        address: addr,
        accuracy: accStr,
        isRemotePunch: isRemote,
      );
    } catch (e) {
      // Network error: punch remains saved in Drift DB (isSynced = 0) to auto-sync later
      print('[PUNCH STEP 2 ERROR] Network failure: $e. Punch remains in Drift DB for auto-sync.');
      if (mounted) {
        showTopToast(
          AppLocalizations.of(context)!.savedLocallyWillSyncWhenOnline,
          background: Colors.orange,
        );
      }
      return;
    }

    if (res is Map && res.containsKey('status')) {
      final statusCode = res['status'];
      String msg = '';
      Color bg = Colors.red;
      if (statusCode is int && statusCode >= 200 && statusCode < 300) {
        // STEP 3: Backend success! Update local Drift DB record as synced
        await OfflineAttendanceService.instance.markSynced(attendanceId);
        print('[PUNCH STEP 3] ✅ Server returned HTTP $statusCode. Updated local Drift DB record (isSynced: 1)');

        msg = type == 'checkin'
            ? AppLocalizations.of(context)!.checkInSuccess
            : AppLocalizations.of(context)!.checkOutSuccess;
        bg = Colors.green;
        _cooldownTimer?.cancel();
        _cooldownTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) setState(() => _punchCooldown = false);
        });
        if (mounted) setState(() => _punchCooldown = true);
        if (mounted) showTopToast(msg, background: bg);

        // Background sweep for any prior pending punches
        OfflineAttendanceService.instance.syncPending();
      } else if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
        // Permanent failure (validation/credentials): Mark synced/cleared in DB to prevent infinite retry
        await OfflineAttendanceService.instance.markSynced(attendanceId);
        print('[PUNCH STEP 3] ⚠️ Server returned HTTP $statusCode (client error). Cleared from DB queue.');

        if (statusCode == 400) {
          msg = AppLocalizations.of(context)!.cantLocate;
        } else {
          msg = AppLocalizations.of(context)!.sessionExpired;
        }
        bg = Colors.red;
        if (mounted) showTopToast(msg, background: bg);
      } else {
        // Server side error (5xx): Punch remains in local DB for auto-sync
        await OfflineAttendanceService.instance.incrementRetry(attendanceId);
        print('[PUNCH STEP 3] ❌ Server returned HTTP $statusCode (server error). Punch stays in Drift DB for auto-sync.');
        if (mounted) {
          showTopToast(
            AppLocalizations.of(context)!.serverErrorSavedLocallyWillSyncLater,
            background: Colors.orange,
          );
        }
      }
    } else {
      // res is null: Punch remains in local DB for auto-sync
      await OfflineAttendanceService.instance.incrementRetry(attendanceId);
      print('[PUNCH STEP 3] ❌ Server returned null response. Punch stays in Drift DB for auto-sync.');
      if (mounted) {
        showTopToast(
          AppLocalizations.of(context)!.serverErrorSavedLocallyWillSyncLater,
          background: Colors.orange,
        );
      }
    }
  }

  changeBTN() {
    if (storage.getItem('checking')) {
      checking = "CHECK-OUT";
    } else {
      checking = "CHECK-IN";
    }
  }

  setBgImage() {
    var hours = DateTime.now().hour;
    if (hours < 12) {
      bgImg = morningBg;
    } else if (hours < 14) {
      bgImg = afternoonBg;
    } else if (hours < 18) {
      bgImg = eveningBg;
    } else {
      bgImg = nightBg;
    }
    return bgImg;
  }

  Position? _currentPosition;
  var latitude;
  var longitude;
  var address;
  var accuracy;
  late StreamSubscription<Position> streamSubscription;

  var qrLatitude;
  var qrLongitude;
  var qrAccuracy;
  var qrAddress;

  getLocation() async {
    bool serviceEnabled;

    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
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
    streamSubscription =
        Geolocator.getPositionStream().listen((Position position) {
      _currentPosition = position;
      latitude = position.latitude;
      longitude = position.longitude;
      accuracy = position.accuracy;
      getAddressFromLatLang(position);
    });
  }

  Future<void> getAddressFromLatLang(Position position) async {
    List<Placemark> placemark =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemark[0];

    address = '${place.street}, ${place.locality}';
  }

  Future<void> _getQrAddressFromLatLang(Position position) async {
    try {
      List<Placemark> placemark =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemark[0];
      if (mounted) {
        setState(() {
          qrAddress = '${place.street}, ${place.locality}';
        });
      }
    } catch (_) {}
  }

  // Compute distance between two lat/lng points in meters (Haversine formula)
  double _distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000.0; // Earth radius in meters
    final phi1 = lat1 * (math.pi / 180.0);
    final phi2 = lat2 * (math.pi / 180.0);
    final dPhi = (lat2 - lat1) * (math.pi / 180.0);
    final dLambda = (lon2 - lon1) * (math.pi / 180.0);
    final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(dLambda / 2) *
            math.sin(dLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  Future<List<UserLocation>?> _fetchLocationsWithRetry(String userId) async {
    final conn = Provider.of<ConnectionProvider>(context, listen: false);
    if (!conn.isOnline) {
      if (mounted) {
        showTopToast(
          'Network connection error. Please check your internet connection.',
          background: Colors.red,
        );
      }
      return [];
    }

    int attempts = 0;
    while (attempts < 3) {
      try {
        final List<UserLocation> locations = await apiService.getTenantCoordinateFromQr(userId);
        return locations;
      } on SocketException catch (e) {
        print('[API ERROR] Network SocketException: $e');
        if (mounted) {
          showTopToast(
            'Network connection error. Please check your internet connection.',
            background: Colors.red,
          );
        }
        return [];
      } on TimeoutException catch (e) {
        print('[API ERROR] Server timeout: $e');
      } catch (e) {
        print('[API ERROR] Server Side/API Error: $e');
      }
      attempts++;
      if (attempts < 3) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return null;
  }

  // ── NEW: Scan → bottom sheet flow ───────────────────────────────────────

  Future<void> _onScanTap() async {
    if (_punchCooldown || _qrBusy) return;
    _qrBusy = true;
    setState(() {
      qrLatitude = null;
      qrLongitude = null;
      qrAccuracy = null;
      qrAddress = null;
    });
    try {
      if (!apiService.qrEnable) {
        // QR not required — go straight to punch selection
        _showPunchBottomSheet(isRemote: false);
        return;
      }

      final userId = storage.getItem('uid')?.toString() ?? '';
      final locationsResult = await _fetchLocationsWithRetry(userId);
      final bool tenantCoordinatesFailed = locationsResult == null;
      final List<UserLocation> locations = locationsResult ?? [];
      final usernameForQr = (storage.getItem('name') ??
              storage.getItem('username') ??
              storage.getItem('userName') ??
              '')
          .toString();

      final qr = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => QrScannerPage(
            username: usernameForQr,
            showRemoteButton: false,
            tenantCoordinatesFailed: tenantCoordinatesFailed,
            onLocationUpdated: (pos) {
              setState(() {
                qrLatitude = pos.latitude;
                qrLongitude = pos.longitude;
                qrAccuracy = pos.accuracy;
              });
              _getQrAddressFromLatLang(pos);
            },
            validator: (raw) {
              double? qlat;
              double? qlng;
              try {
                String normalized = raw.trim();
                if (normalized.contains("'") && !normalized.contains('"')) {
                  normalized = normalized.replaceAll("'", '"');
                }
                final parsed = jsonDecode(normalized);
                if (parsed is Map) {
                  final latAny = parsed['lat'] ?? parsed['latitude'];
                  final lngAny = parsed['lng'] ?? parsed['longitude'];
                  if (latAny != null && lngAny != null) {
                    qlat = latAny is num
                        ? latAny.toDouble()
                        : double.tryParse(latAny.toString());
                    qlng = lngAny is num
                        ? lngAny.toDouble()
                        : double.tryParse(lngAny.toString());
                  }
                }
              } catch (_) {}

              if (qlat == null || qlng == null) {
                return AppLocalizations.of(context)!.qrNoCoordinates;
              }

              double allowedRadius = 50.0;

              if (!tenantCoordinatesFailed) {
                dynamic matchedLocation;
                for (var loc in locations) {
                  dynamic rawLat;
                  dynamic rawLng;
                  try {
                    rawLat = loc.lat;
                    rawLng = loc.lng;
                  } catch (_) {}
                  double currentLat = 0.0, currentLng = 0.0;
                  if (rawLat is num) {
                    currentLat = rawLat.toDouble();
                  } else if (rawLat != null) {
                    currentLat = double.tryParse(rawLat.toString()) ?? 0.0;
                  }
                  if (rawLng is num) {
                    currentLng = rawLng.toDouble();
                  } else if (rawLng != null) {
                    currentLng = double.tryParse(rawLng.toString()) ?? 0.0;
                  }
                  if (qlat == currentLat && qlng == currentLng) {
                    matchedLocation = loc;
                    break;
                  }
                }

                if (matchedLocation == null) {
                  return AppLocalizations.of(context)!
                      .qrCoordinatesMismatchMessage;
                }

                try {
                  final dynamic r = matchedLocation.radius ??
                      matchedLocation.radiusMeters ??
                      matchedLocation.range;
                  if (r is num) allowedRadius = r.toDouble();
                  if (r is String) allowedRadius = double.tryParse(r) ?? 50.0;
                } catch (_) {}
              }

              final double? dlat = (qrLatitude is num)
                  ? (qrLatitude as num).toDouble()
                  : double.tryParse(qrLatitude?.toString() ?? '');
              final double? dlng = (qrLongitude is num)
                  ? (qrLongitude as num).toDouble()
                  : double.tryParse(qrLongitude?.toString() ?? '');

              if (dlat == null || dlng == null) return 'Location not available';

              final dist = _distanceBetween(dlat, dlng, qlat, qlng);
              if (dist > allowedRadius) {
                final uname = (storage.getItem('name') ??
                        storage.getItem('username') ??
                        '')
                    .toString();
                return AppLocalizations.of(context)!.qrCannotPunchHere(
                      uname.isNotEmpty ? uname : 'User',
                    ) +
                    ' (${dist.toStringAsFixed(0)}m / ${allowedRadius.toStringAsFixed(0)}m)';
              }
              return null;
            },
          ),
        ),
      );

      if (!mounted || qr == null || qr.trim().isEmpty) return;
      _showPunchBottomSheet(isRemote: false);
    } finally {
      _qrBusy = false;
      if (mounted) setState(() {});
    }
  }

  void _onRemoteTap() {
    if (_punchCooldown) return;
    _showPunchBottomSheet(isRemote: true);
  }

  void _showPunchBottomSheet({required bool isRemote}) {
    final primary = FlavorConfig.instance.primaryColor;
    final secondary = FlavorConfig.instance.secondaryColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, 32 + MediaQuery.of(ctx).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Text(
                isRemote
                    ? AppLocalizations.of(context)!.remoteChecking
                    : 'Select Action',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (!isRemote || apiService.remoteValue == 1 || apiService.remoteValue == 3)
                    Expanded(
                      child: _punchSheetButton(
                        label: AppLocalizations.of(context)!.checkIn,
                        icon: Icons.input,
                        color: primary,
                        onTap: () {
                          Navigator.pop(ctx);
                          checkinCheckout('checkin', isRemote: isRemote);
                        },
                      ),
                    ),
                  if (!isRemote || apiService.remoteValue == 3)
                    const SizedBox(width: 12),
                  if (!isRemote || apiService.remoteValue == 2 || apiService.remoteValue == 3)
                    Expanded(
                      child: _punchSheetButton(
                        label: AppLocalizations.of(context)!.checkOut,
                        icon: Icons.output,
                        color: secondary,
                        onTap: () {
                          Navigator.pop(ctx);
                          checkinCheckout('checkout', isRemote: isRemote);
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _punchSheetButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // ── End new methods ──────────────────────────────────────────────────────

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final l10n = AppLocalizations.of(context)!;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 17) return l10n.goodAfternoon;
    if (hour < 21) return l10n.goodEvening;
    return l10n.goodNight;
  }

  String _getWelcomeName() {
    // Try to find cf_nickname first
    try {
      final raw = storage.getItem('me_profile');
      if (raw != null) {
        final map = raw is Map ? Map<String, dynamic>.from(raw) : null;
        if (map != null) {
          final dataAny = map['data'] ?? map['result'] ?? map['user'] ?? map;
          if (dataAny is Map) {
            final data = Map<String, dynamic>.from(dataAny);
            final cf = data['customfields'];
            if (cf is List) {
              for (final item in cf) {
                if (item is Map) {
                  final inputName = item['input_name']?.toString() ?? '';
                  final inputValue =
                      item['input_value']?.toString().trim() ?? '';
                  if (inputName == 'cf_nickname' && inputValue.isNotEmpty) {
                    return inputValue;
                  }
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    // Try flat keys next
    final flat = (storage.getItem('name') ??
            storage.getItem('username') ??
            storage.getItem('userName') ??
            '')
        .toString()
        .trim();
    if (flat.isNotEmpty) return flat.split(' ').first;

    // Fall back to me_profile JSON
    try {
      final raw = storage.getItem('me_profile');
      if (raw != null) {
        final map = raw is Map ? Map<String, dynamic>.from(raw) : null;
        if (map != null) {
          final dataAny = map['data'] ?? map['result'] ?? map['user'] ?? map;
          if (dataAny is Map) {
            final data = Map<String, dynamic>.from(dataAny);

            // Try flat fields first
            final fn =
                (data['first_name'] ?? data['name'] ?? data['full_name'] ?? '')
                    .toString()
                    .trim();
            if (fn.isNotEmpty) return fn.split(' ').first;

            // Parse customfields array: [{"input_name":"cf_first_name","input_value":"..."}]
            final cf = data['customfields'];
            if (cf is List) {
              for (final item in cf) {
                if (item is Map) {
                  final inputName = item['input_name']?.toString() ?? '';
                  final inputValue =
                      item['input_value']?.toString().trim() ?? '';
                  if (inputName == 'cf_first_name' && inputValue.isNotEmpty) {
                    return inputValue.split(' ').first;
                  }
                }
              }
            }
          }
        }
      }
    } catch (_) {}
    return '';
  }

  Widget _buildWelcomeText() {
    final firstName = _getWelcomeName();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getGreeting(),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
            fontWeight: FontWeight.w400,
            shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
          ),
        ),
        if (firstName.isNotEmpty)
          Text(
            firstName,
            style: const TextStyle(
              fontSize: 26,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
            ),
          ),
      ],
    );
  }

  Widget slider() {
    return Container(
      height: MediaQuery.of(context).size.height / 1.9,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: 1,
            onPageChanged: (int index) {
              setState(() {
                currentIndex = index;
              });
            },
            itemBuilder: (_, i) {
              return GestureDetector(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    child: OctoImage(
                      image: DesignConfig.getHomeBgProvider(setBgImage()),
                      placeholderBuilder: OctoBlurHashFix.placeHolder(
                        sliderList[i].blurUrl!,
                      ),
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      errorBuilder: OctoError.icon(color: HRColors.black),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                onTap: () {},
              );
            },
          ),

          // Welcome text overlay — below the AppBar/drawer icon area
          Positioned(
            top: MediaQuery.of(context).padding.top + 64,
            left: 20,
            right: 20,
            child: _buildWelcomeText(),
          ),

          Container(
            width: MediaQuery.of(context).size.width,
            height: 122.0,
            margin: EdgeInsets.only(
              left: 12.0,
              right: 12.0,
              top: MediaQuery.of(context).size.height * .37,
            ),
            child: SlideAnimation(
              position: 4,
              itemCount: 8,
              slideDirection: SlideDirection.fromTop,
              animationController: _animationController,
              child: GlassBox(
                redius: 24.0,
                width: MediaQuery.of(context).size.width,
                height: 122.0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(
                            _dateTime ?? "loading...",
                            style: TextStyle(
                              color: HRColors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        ignoring: _punchCooldown || _qrBusy,
                        child: Opacity(
                          opacity: (_punchCooldown || _qrBusy) ? 0.45 : 1.0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // ── Scan Check-In/Out button ────────────
                              Flexible(
                                child: GestureDetector(
                                  onTap: _onScanTap,
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 160),
                                    curve: Curves.easeOut,
                                    height: 46,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: FlavorConfig
                                          .instance.primaryColor,
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.qr_code_scanner,
                                              color: Colors.white, size: 18),
                                          const SizedBox(width: 5),
                                          Text(
                                            AppLocalizations.of(context)!
                                                .scanCheckInOut,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // ── Remote button (only for remote-enabled users) ──
                              if (apiService.remoteEnable) ...[
                                const SizedBox(width: 8),
                                Flexible(
                                  child: GestureDetector(
                                    onTap: _onRemoteTap,
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 160),
                                      curve: Curves.easeOut,
                                      height: 46,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: FlavorConfig
                                            .instance.secondaryColor,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 8,
                                            offset: Offset(0, 4),
                                          )
                                        ],
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.wifi_tethering,
                                                color: Colors.white,
                                                size: 18),
                                            const SizedBox(width: 5),
                                            Text(
                                              AppLocalizations.of(context)!
                                                  .remoteChecking,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget data() {
    final connectionProvider = Provider.of<ConnectionProvider>(context);
    final _ = connectionProvider.isOnline;
    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemStatusBarContrastEnforced: false,
          ),
          snap: false,
          pinned: true,
          floating: false,
          flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                "",
                style:
                    TextStyle(color: HRColors.white, fontSize: 0), //TextStyle
              ), //Text
              background: Stack(children: [
                slider(),
              ])),
          actions: <Widget>[
            // Manual sync button (Only visible when pending sync data exists)
            FutureBuilder<int>(
              future: OfflineAttendanceService.instance.getPendingCount(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (count <= 0) return const SizedBox.shrink();

                return GestureDetector(
                  onTap: () async {
                    try {
                      final results =
                          await OfflineAttendanceService.instance.syncPending(ignoreMaxAttempts: true);
                      final success = results['success'] ?? 0;
                      final failed = results['failed'] ?? 0;
                      showTopToast(
                        AppLocalizations.of(context)!.syncedCountFailedCount(success, failed),
                        background: Colors.green,
                      );
                    } catch (e) {
                      showTopToast('Sync failed', background: Colors.red);
                    } finally {
                      if (mounted) setState(() {});
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5.0),
                    alignment: Alignment.center,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GlassBox(
                          redius: 40.0,
                          width: 50,
                          height: 50,
                          backgroundColor: HRColors.flavorIconBackgroundColor,
                          child: Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Icon(Icons.sync, color: HRColors.flavorIconColor),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            GestureDetector(
              onTap: () async {
                await Navigator.pushNamed(context, HRNotifications.routeName);
                await FCMService.loadUnreadCount();
              },
              child: Container(
                padding: EdgeInsets.all(5.0),
                alignment: Alignment.center,
                child: ValueListenableBuilder<int>(
                  valueListenable: FCMService.unreadCount,
                  builder: (context, count, _) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GlassBox(
                        redius: 40.0,
                        width: 50,
                        height: 50,
                        backgroundColor: HRColors.flavorIconBackgroundColor,
                        child: Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: SvgPicture.asset(
                                'assets/svg/notifications_icon.svg',
                                colorFilter: ColorFilter.mode(
                                    HRColors.flavorIconColor, BlendMode.srcIn)),
                          ),
                        ),
                      ),
                      if (count > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ), //IconButton//IconButton
          ], //FlexibleSpaceBar
          expandedHeight: MediaQuery.of(context).size.height / 2,
          backgroundColor: Colors.transparent.withOpacity(0.02),
          shadowColor: Colors.transparent,
          leading: GestureDetector(
            onTap: () {
              _scaffoldKey.currentState!.openDrawer();
            },
            child: Container(
              padding: EdgeInsets.all(5.0),
              alignment: Alignment.center,
              child: GlassBox(
                redius: 40.0,
                width: 50,
                height: 50,
                backgroundColor: HRColors.flavorIconBackgroundColor,
                child: Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: SvgPicture.asset("assets/svg/drawer_icon.svg",
                        colorFilter: ColorFilter.mode(
                            HRColors.flavorIconColor, BlendMode.srcIn)),
                  ),
                ),
              ),
            ),
          ),
        ),
        //SliverAppBar
        SliverList(
          delegate: SliverChildListDelegate(
            [
              SlideAnimation(
                position: 4,
                itemCount: 8,
                slideDirection: SlideDirection.fromBottom,
                animationController: _animationController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Padding(
                    //   padding: const EdgeInsets.only(top: 10),
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.center,
                    //     children: [
                    //       ElevatedButton(
                    //         style: ElevatedButton.styleFrom(
                    //           backgroundColor: apiService.qrEnable ? Colors.green : Colors.red,
                    //         ),
                    //         onPressed: () {
                    //           setState(() {
                    //             apiService.qrEnable = !apiService.qrEnable;
                    //           });
                    //         },
                    //         child: Text('QR: ${apiService.qrEnable ? "ON" : "OFF"}', style: TextStyle(color: Colors.white)),
                    //       ),
                    //       const SizedBox(width: 10),
                    //       ElevatedButton(
                    //         style: ElevatedButton.styleFrom(
                    //           backgroundColor: apiService.remoteEnable ? Colors.green : Colors.red,
                    //         ),
                    //         onPressed: () {
                    //           setState(() {
                    //             apiService.remoteEnable = !apiService.remoteEnable;
                    //           });
                    //         },
                    //         child: Text('Remote: ${apiService.remoteEnable ? "ON" : "OFF"}', style: TextStyle(color: Colors.white)),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                          top: 10, start: 10, end: 10),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Text(
                                  AppLocalizations.of(context)!.rosterText,
                                  style: TextStyle(
                                      color: HRColors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                              ),
                              Spacer(), // Defaults to a flex of one.
                            ]),
                            roster()
                          ]),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ], //<Widget>[]
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        key: _scaffoldKey,
        extendBody: true,
        backgroundColor: Colors.white,
        drawerScrimColor: Colors.transparent,
        drawer: Drawer(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: DesignConfig.drawerContent(_scaffoldKey, context),
        ),
        body: Container(
          width: double.infinity,
          child: data(),
        ),
      ),
    );
  }

  Future<void> navigationPage() async {
    Navigator.pop(context);
  }

  Widget roster() {
    final CalendarController _controller = CalendarController();

    const Color _surface = Color.fromARGB(255, 248, 250, 252);

    return GestureDetector(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              color: _surface,
              child: SfCalendar(
                view: CalendarView.month,
                controller: _controller,
                viewNavigationMode: ViewNavigationMode.none,
                dataSource: MeetingDataSource(_getDataSource()),
                headerStyle: const CalendarHeaderStyle(
                    backgroundColor: _surface, textAlign: TextAlign.center),
                monthViewSettings: MonthViewSettings(
                  showTrailingAndLeadingDates: false,
                  appointmentDisplayMode:
                      MonthAppointmentDisplayMode.appointment,
                  dayFormat: 'EEE',
                  agendaViewHeight: MediaQuery.of(context).size.height / 580,
                  showAgenda: true,
                ),
              ),
            ),
            Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height * 0.40))
          ],
        ),
      ),
    );
  }

  List<Meeting> _getDataSource() {
    final List<Meeting> meetings = <Meeting>[];
    return meetings;
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Meeting> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].from;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].to;
  }

  @override
  String getSubject(int index) {
    return appointments![index].eventName;
  }

  @override
  Color getColor(int index) {
    return appointments![index].background;
  }

  @override
  bool isAllDay(int index) {
    return appointments![index].isAllDay;
  }
}

class Meeting {
  Meeting(this.eventName, this.from, this.to, this.background, this.isAllDay);

  String eventName;
  DateTime from;
  DateTime to;
  Color background;
  bool isAllDay;
}
