import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({Key? key}) : super(key: key);

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> with TickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  static const Color _accent = Color(0xFFF59E0B); // Your original amber color
  static const Color _backgroundAccent = Color(0xFFFEF3C7); // Light amber background
  
  late AnimationController _mainAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  late List<AnimationController> _fieldControllers;
  late List<Animation<double>> _fieldAnimations;

  @override
  void initState() {
    super.initState();
    
    // Initialize field controllers list
    _fieldControllers = [];
    _fieldAnimations = [];
    
    // Main animation controller
    _mainAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // Different animations
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.elasticOut),
    );
    
    _rotateAnimation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.elasticOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.bounceOut,
    ));
    
    _fadeAnimation = CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );
    
    // Create animations for each field (6 fields)
    for (int i = 0; i < 6; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + (i * 100)),
      );
      _fieldControllers.add(controller);
      
      final animation = CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      );
      _fieldAnimations.add(animation);
      
      // Start field animation after main animation
      Future.delayed(Duration(milliseconds: 300 + (i * 100)), () {
        if (mounted) {
          controller.forward();
        }
      });
    }
    
    // Start main animation
    _mainAnimationController.forward();
    
    // focus first field when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    for (final c in _fieldControllers) {
      c.dispose();
    }
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onFieldChanged(String value, int index) {
    // Animate field when filled
    if (value.isNotEmpty && mounted) {
      _fieldControllers[index].reverse().then((_) {
        if (mounted) {
          _fieldControllers[index].forward();
        }
      });
    }
    
    if (value.length == 1) {
      if (index < 5) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
        // Animate next field
        if (mounted) {
          _fieldControllers[index + 1].forward(from: 0.0);
        }
      } else {
        _focusNodes[index].unfocus();
        // Pulse animation on last field before submit
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _fieldControllers[index].reverse().then((_) {
              if (mounted) {
                _fieldControllers[index].forward();
              }
            });
            _submitOtp();
          }
        });
      }
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  Widget _pinField(int index, {double width = 55}) {
    return AnimatedBuilder(
      animation: _fieldAnimations[index],
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.3 * _fieldAnimations[index].value),
          child: child,
        );
      },
      child: Container(
        width: width,
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.2 * _fieldAnimations[index].value),
              blurRadius: 10 * _fieldAnimations[index].value,
              spreadRadius: 2 * _fieldAnimations[index].value,
            ),
          ],
        ),
        child: TextFormField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textInputAction: index < 5 ? TextInputAction.next : TextInputAction.done,
          onChanged: (value) => _onFieldChanged(value, index),
          onFieldSubmitted: (v) {
            if (index == 5) _submitOtp();
          },
          style: const TextStyle(
            color: Colors.black87, 
            fontSize: 24, 
            fontWeight: FontWeight.w700
          ),
          textAlign: TextAlign.center,
          cursorColor: _accent,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), 
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), 
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), 
              borderSide: BorderSide(color: _accent, width: 2),
            ),
          ),
          keyboardType: TextInputType.number,
          maxLength: 1,
        ),
      ),
    );
  }

  void _submitOtp() {
    final otp = _controllers.map((c) => c.text.trim()).join();
    if (otp.length == 6) {
      // Success animation
      for (var controller in _fieldControllers) {
        controller.repeat(reverse: true, period: const Duration(milliseconds: 200));
      }
      
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          Navigator.of(context).pop(otp);
        }
      });
    } else {
      // Error animation - shake fields
      for (var controller in _fieldControllers) {
        controller.repeat(reverse: true, period: const Duration(milliseconds: 100));
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AutoSizeText(AppLocalizations.of(context)!.enterSixDigitOtp),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.red.shade400,
        ),
      );
      
      // Stop shake after 1 second
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          for (int i = 0; i < _fieldControllers.length; i++) {
            _fieldControllers[i].forward(from: 0.0);
          }
        }
      });
    }
  }

  void _resendOtp() {
    // Clear all fields with animation
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].clear();
      if (mounted) {
        _fieldControllers[i].forward(from: 0.0);
      }
    }
    
    // Focus first field
    _focusNodes[0].requestFocus();
    
    // Show success message with animation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: AutoSizeText(AppLocalizations.of(context)!.otpResentSuccess),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.green.shade400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: AnimatedBuilder(
          animation: _mainAnimationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - _mainAnimationController.value)),
              child: Opacity(
                opacity: _mainAnimationController.value,
                child: child,
              ),
            );
          },
          child: AutoSizeText('', style: TextStyle(color: Colors.black87)),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              
              // Animated icon with your theme color
              AnimatedBuilder(
                animation: _mainAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotateAnimation.value,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: child,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _backgroundAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.mark_email_unread_outlined, 
                    size: 50, 
                    color: _accent,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Animated title
              AnimatedBuilder(
                animation: _mainAnimationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - _mainAnimationController.value)),
                    child: Opacity(
                      opacity: _mainAnimationController.value,
                      child: child,
                    ),
                  );
                },
                child: AutoSizeText(
                  'Enter OTP Code',
                  style: TextStyle(
                    fontSize: 26, 
                    fontWeight: FontWeight.w700, 
                    color: Colors.black87,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Animated subtitle with phone number
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      AutoSizeText(
                        'We have sent a 6-digit code to:',
                        style: TextStyle(
                          fontSize: 15, 
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: _backgroundAccent.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: _accent.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.email_outlined, size: 20, color: _accent),
                            const SizedBox(width: 8),
                            AutoSizeText(
                              '+1 234 567 8900',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // OTP fields (6 fields) — compute width to avoid overflow
              LayoutBuilder(
                builder: (context, constraints) {
                  final totalSpacing = 8.0 * 5; // margins between fields approx
                  final available = constraints.maxWidth - totalSpacing - 48; // keep some padding
                  final fieldWidth = (available / 6).clamp(40.0, 60.0);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) => _pinField(i, width: fieldWidth)),
                  );
                },
              ),
              
              const SizedBox(height: 50),
              
              // Animated Verify button
              AnimatedBuilder(
                animation: _mainAnimationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - _mainAnimationController.value)),
                    child: Opacity(
                      opacity: _mainAnimationController.value,
                      child: child,
                    ),
                  );
                },
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 1),
                  tween: Tween(begin: 1.0, end: 1.05),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _submitOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                      ),
                      child: AutoSizeText(
                        'Verify',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Animated resend section
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: GestureDetector(
                    onTap: _resendOtp,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(seconds: 2),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: [
                                  _accent,
                                  _accent.withOpacity(0.7),
                                ],
                                stops: [value - 0.2, value],
                              ).createShader(bounds);
                            },
                            child: child,
                          );
                        },
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(fontSize: 15),
                            children: [
                              TextSpan(
                                text: "Didn't receive the code? ",
                                style: TextStyle(color: Colors.black.withOpacity(0.6)),
                              ),
                              TextSpan(
                                text: 'Resend',
                                style: TextStyle(
                                  color: _accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}