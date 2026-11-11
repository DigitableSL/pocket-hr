import 'dart:async';
import 'package:cn_pocket_hr/helpers/hr_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localstorage/localstorage.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:vibration/vibration.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:cn_pocket_hr/services/security_service.dart';

class QrScannerPage extends StatefulWidget {
  final String? expectedValue;
  final String? Function(String code)? validator;
  final String? username;
  final bool showRemoteButton;
  final VoidCallback? onRemotePressed;
  final Function(Position position)? onLocationUpdated;
  final bool tenantCoordinatesFailed;

  const QrScannerPage({
    Key? key,
    this.expectedValue,
    required this.validator,
    this.username,
    this.showRemoteButton = false,
    this.onRemotePressed,
    this.onLocationUpdated,
    this.tenantCoordinatesFailed = false,
  }) : super(key: key);

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> with SingleTickerProviderStateMixin {
  bool _scanned = false;
  final MobileScannerController _controller = MobileScannerController();
  String? _message;
  bool _isError = false;
  bool _torchOn = false;
  bool _isFrontCamera = false;
  bool _isFetchingLocation = false;
  final LocalStorage storage = LocalStorage('pocketHR');

  StreamSubscription<Position>? _positionStream;
  int _locationAttempts = 0;
  bool _accuracyAchieved = false;
  double? _currentAccuracy;
  late AnimationController _satelliteAnimationController;
  Timer? _stepTimer;
  int _locationStepIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SecurityService.verifyDeviceSecurity(context: context);
    });
    _satelliteAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _startLocationListening();
    if (widget.tenantCoordinatesFailed) {
      _isError = true;
    }
  }

  void _startLocationListening() async {
    _locationStepIndex = 0;
    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _locationStepIndex++;
        });
      }
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _stepTimer?.cancel();
        setState(() {
          _accuracyAchieved = true;
        });
        return;
      }

      final LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position? position) {
        if (position != null) {
          _handleNewLocation(position);
        }
      });
    } catch (_) {
      _stepTimer?.cancel();
      setState(() {
        _accuracyAchieved = true;
      });
    }
  }

  void _handleNewLocation(Position position) {
    if (!mounted) return;
    if (position.isMocked) {
      SecurityService.verifyPosition(position, context: context);
      return;
    }
    debugPrint('[Location] New coordinate: lat=${position.latitude}, lng=${position.longitude}, accuracy=${position.accuracy}m');
    widget.onLocationUpdated?.call(position);
    setState(() {
      _currentAccuracy = position.accuracy;
    });

    if (position.accuracy <= 5.0) {
      _stepTimer?.cancel();
      setState(() {
        _accuracyAchieved = true;
      });
      _positionStream?.cancel();
    } else {
      _locationAttempts++;
      if (_locationAttempts >= 2) {
        _stepTimer?.cancel();
        _positionStream?.cancel();
        _showAccuracyDialog();
      }
    }
  }

  void _showAccuracyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final local = AppLocalizations.of(context)!;
        final accuracyStr = _currentAccuracy != null ? _currentAccuracy!.toStringAsFixed(1) : "0.0";
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          content: Text(
            local.locationAccuracyMessage(accuracyStr),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (mounted) {
                  setState(() {
                    _accuracyAchieved = true;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: HRColors.darkOrangeColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: Text(
                local.continueText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _buzzOnScan() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        // short, subtle vibration
        await Vibration.vibrate(duration: 60, amplitude: 80);
      } else {
        HapticFeedback.mediumImpact();
      }
    } catch (_) {
      try {
        HapticFeedback.selectionClick();
      } catch (_) {}
    }

    // Optional fallback sound (some devices silence/disable haptics)
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  void _setMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _message = msg;
      _isError = isError;
    });
  }

  String _getLocationStepText(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final step = _locationStepIndex % 3;

    if (step == 0) {
      return local.findingSatellite;
    } else if (step == 1) {
      return local.calibratingDevice;
    } else {
      return local.calculatingDistance;
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _positionStream?.cancel();
    _satelliteAnimationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get _isServerErrorActive {
    if (_message == null) return false;
    try {
      final serverErrMsg = AppLocalizations.of(context)!.failedToRetrieveCoordinatesCheckInOutEnabled;
      if (_message == serverErrMsg) return true;
    } catch (_) {}
    return _message == "Failed to retrieve site coordinates. Check-in/out locally is enabled.";
  }

  @override
  Widget build(BuildContext context) {
    if (_message == null && widget.tenantCoordinatesFailed) {
      _message = AppLocalizations.of(context)!.failedToRetrieveCoordinatesCheckInOutEnabled;
    }
    final media = MediaQuery.of(context);
    final safeH = media.size.height - media.padding.top - media.padding.bottom;
    final double scanSize = math.min(320.0, math.max(220.0, safeH * 0.42));
    const double cornerLen = 28;
    const double cornerStroke = 4;
    final double topPad = 70;
    final double msgTop = topPad + scanSize + 12;
    final double bottomPad = math.max(16.0, media.padding.bottom + 12.0);

    void handleDetect(BarcodeCapture capture) async {
      try {
        if (!_accuracyAchieved || _scanned || _isFetchingLocation) return;
        final barcodes = capture.barcodes;
        if (barcodes.isEmpty) return;
        final b = barcodes.first;
        final String? code = b.rawValue;
        if (code == null || code.isEmpty) return;

        setState(() {
          _scanned = true; // Briefly pause scanning
          _isFetchingLocation = true;
        });

        _buzzOnScan();

        Position? position;
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            timeLimit: const Duration(seconds: 10),
          );
        } catch (_) {
          try {
            position = await Geolocator.getLastKnownPosition();
          } catch (_) {}
        }

        setState(() {
          _isFetchingLocation = false;
        });

        if (position == null) {
          _setMessage('Location not available', isError: true);
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (!mounted) return;
            setState(() {
              _scanned = false;
              _message = null;
            });
          });
          return;
        }

        // Verify device security and mock location
        final isClean = await SecurityService.verifyDeviceSecurity(
          currentPosition: position,
          context: context,
        );
        if (!isClean) {
          _controller.stop();
          return;
        }

        widget.onLocationUpdated?.call(position);

        final trimmed = code.trim();
        final err = widget.validator?.call(trimmed);

        if (err == null) {
          // --- SUCCESS ---
          // Only navigate away if the validator confirms everything is OK.
          _setMessage('QR accepted', isError: false);
          _controller.stop();
          Navigator.of(context).pop(trimmed);
          return;
        }

        // --- ERROR ---
        // Any error from the validator (distance, invalid QR, etc.) is handled here.
        // Do not navigate. Show the message and allow re-scanning.
        _setMessage(err, isError: true);

        // After a delay, re-enable scanning
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (!mounted) return;
          setState(() {
            _scanned = false;
            _message = null;
          });
          try {
            if (_controller.value.isRunning == false) {
              _controller.start();
            }
          } catch (_) {}
        });
      } catch (_) {
        if (mounted) {
          setState(() {
            _scanned = false;
            _isFetchingLocation = false;
          });
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Full screen white background
            Positioned.fill(
              child: Container(color: Colors.white),
            ),

            // Camera preview only inside the scan box (moved to top + larger)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: topPad),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: scanSize,
                    height: scanSize,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _controller,
                          onDetect: handleDetect,
                        ),

                        // subtle border
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isError
                                  ? Colors.redAccent
                                  : Colors.black.withOpacity(0.20),
                              width: 1.5,
                            ),
                          ),
                        ),

                        // Highlighted corners
                        Positioned(
                          left: 10,
                          top: 10,
                          child: _Corner(
                            color: _isError ? Colors.redAccent : Colors.white,
                            length: cornerLen,
                            stroke: cornerStroke,
                            topLeft: true,
                          ),
                        ),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: _Corner(
                            color: _isError ? Colors.redAccent : Colors.white,
                            length: cornerLen,
                            stroke: cornerStroke,
                            topRight: true,
                          ),
                        ),
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: _Corner(
                            color: _isError ? Colors.redAccent : Colors.white,
                            length: cornerLen,
                            stroke: cornerStroke,
                            bottomLeft: true,
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: _Corner(
                            color: _isError ? Colors.redAccent : Colors.white,
                            length: cornerLen,
                            stroke: cornerStroke,
                            bottomRight: true,
                          ),
                        ),

                        if (!_accuracyAchieved)
                          Container(
                            color: Colors.black.withOpacity(0.85),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _satelliteAnimationController,
                                    builder: (context, child) {
                                      return Opacity(
                                        opacity: 0.5 + (_satelliteAnimationController.value * 0.5),
                                        child: Transform.scale(
                                          scale: 1.0 + (_satelliteAnimationController.value * 0.15),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: const Icon(
                                      Icons.satellite_alt_outlined,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _getLocationStepText(context),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_currentAccuracy != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      AppLocalizations.of(context)!.currentAccuracyLabel(_currentAccuracy!.toStringAsFixed(1)),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        if (_isFetchingLocation)
                          Container(
                            color: Colors.black.withOpacity(0.85),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _getLocationStepText(context),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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

            // Close button
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            // Torch and camera switch buttons (top right)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 8.0, right: 8.0, bottom: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _torchOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.black,
                      ),
                      onPressed: () async {
                        try {
                          await _controller.toggleTorch();
                          setState(() => _torchOn = !_torchOn);
                        } catch (_) {}
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cameraswitch, color: Colors.black),
                      onPressed: () async {
                        try {
                          await _controller.switchCamera();
                          setState(() => _isFrontCamera = !_isFrontCamera);
                        } catch (_) {}
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Dynamic message (error/success) directly under scan area
            if ((_message?.trim().isNotEmpty ?? false))
              Positioned(
                left: 16,
                right: 16,
                top: msgTop,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 96),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isServerErrorActive
                          ? Colors.orange
                          : (_isError ? Colors.redAccent : Colors.green),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      )
                    ],
                  ),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _isServerErrorActive
                          ? Colors.orange
                          : (_isError ? Colors.redAccent : Colors.green),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

            // Fixed bottom instruction
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomPad,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.scannText,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            if (widget.showRemoteButton)
              Positioned(
                bottom: 150,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _controller.stop();
                      widget.onRemotePressed?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HRColors.orangeColor,
                      // foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.remoteChecking,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }




}

class _Corner extends StatelessWidget {
  final Color color;
  final double length;
  final double stroke;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  const _Corner({
    required this.color,
    required this.length,
    required this.stroke,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    // Draw an L shape using two containers.
    final horiz = Container(width: length, height: stroke, color: color);
    final vert = Container(width: stroke, height: length, color: color);

    if (topLeft) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [horiz, vert],
      );
    }
    if (topRight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [horiz, vert],
      );
    }
    if (bottomLeft) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [vert, horiz],
      );
    }
    // bottomRight
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [vert, horiz],
    );
  }
}
