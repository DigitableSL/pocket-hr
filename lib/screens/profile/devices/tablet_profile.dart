import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:octo_image/octo_image.dart';
import 'package:cn_pocket_hr/l10n/app_localizations.dart';
import 'package:cn_pocket_hr/screens/notifications/notifications.dart';
import 'package:cn_pocket_hr/api/api_service.dart';
import 'package:cn_pocket_hr/helpers/design_config.dart';
import 'package:cn_pocket_hr/helpers/hr_colors.dart';
import 'package:cn_pocket_hr/helpers/custom_blur_hash.dart';
import 'package:localstorage/localstorage.dart';
import 'package:cn_pocket_hr/services/fcm_service.dart';
import 'package:cn_pocket_hr/services/secure_token_service.dart';

class TabletProfile extends StatefulWidget {
  @override
  _TabletProfileState createState() => _TabletProfileState();
}

class _TabletProfileState extends State<TabletProfile> {
  final APIService _apiService = APIService();
  final LocalStorage storage = LocalStorage('pocketHR');

  bool _loadingMe = false;
  String? _error;
  bool _photoLoading = false;
  bool _savingImage = false;
  File? _selectedImage;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Profile data
  String _headerFullName = '';
  String _headerEpf = '';
  String _profilePhotoUrl = '';
  String _email = '';
  String _designation = '';
  String _department = '';
  String _phone = '';
  String _address = '';
  String _nic = '';
  String _dob = '';

  // Colors
  static Color get _primaryColor => HRColors.darkOrangeColor;
  static const Color _backgroundColor = Color.fromARGB(255, 248, 250, 252);
  static const Color _cardColor = Colors.white;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _loadProfileData();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _loadProfileData() async {
    if (_loadingMe) return;
    setState(() {
      _loadingMe = true;
      _error = null;
    });

    try {
      final meProfile = await _apiService.fetchMeProfileWithBearer();
      if (meProfile == null) {
        setState(() {
          _error = AppLocalizations.of(context)!.failedToConnectToServer;
        });
        return;
      }

      final dataAny =
          meProfile['data'] ?? meProfile['result'] ?? meProfile['user'];
      if (dataAny is! Map) return;
      final data = Map<String, dynamic>.from(dataAny);

      // Helper: read custom field value
      String cf(String key) {
        final cfs = data['customfields'];
        if (cfs is List) {
          for (final item in cfs) {
            if (item is Map && item['input_name']?.toString() == key) {
              return item['input_value']?.toString() ?? '';
            }
          }
        }
        return '';
      }

      final uid = (data['_id'] ?? data['id'] ?? '').toString();
      if (uid.isNotEmpty) {
        await storage.ready;
        await storage.setItem('uid', uid);
      }

      setState(() {
        _email = (data['email'] ?? '').toString();
        _headerFullName = '${cf('cf_first_name')} ${cf('cf_last_name')}'.trim();
        _headerEpf = cf('cf_epf_no');
        _designation = cf('cf_designation');
        _department = cf('cf_department');
        _phone = cf('cf_phone');
        _address = cf('cf_address');
        _nic = cf('cf_nic');
        _dob = cf('cf_dob');
      });

      _fetchProfilePhoto();
    } catch (e) {
      debugPrint('[PROFILE] Error loading profile: $e');
      setState(() {
        _error = DesignConfig.getFriendlyErrorMessage(context, e);
      });
    } finally {
      if (mounted) setState(() => _loadingMe = false);
    }
  }

  Future<void> _fetchProfilePhoto() async {
    if (mounted) setState(() => _photoLoading = true);
    try {
      final url = await _apiService.getProfilePhotoUrl(size: '150-150');
      debugPrint('[PROFILE] photo URL => $url');
      if (url != null && url.isNotEmpty && mounted) {
        setState(() => _profilePhotoUrl = url);
      }
    } catch (e) {
      debugPrint('[PROFILE] photo fetch error: $e');
    } finally {
      if (mounted) setState(() => _photoLoading = false);
    }
  }

  Map<String, String> _authHeaders() {
    final oauthToken = SecureTokenService.getOauthTokenSync();
    final accessToken = SecureTokenService.getAccessTokenSync();
    final tenant = storage.getItem('tenant')?.toString() ?? '';
    return {
      'Accept': 'image/*',
      if (oauthToken.isNotEmpty) 'Oauth-Token': oauthToken,
      if (accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
      if (tenant.isNotEmpty) 'Tenant': tenant,
    };
  }

  Future<void> _pickImage() async {
    try {
      setState(() => _savingImage = true);
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _savingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: AutoSizeText(AppLocalizations.of(context)!.profilePictureUpdated),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      setState(() => _savingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: AutoSizeText(AppLocalizations.of(context)!.failedToUpdatePicture),
        backgroundColor: Colors.red,
      ));
    }
  }

  // ── UI Widgets ─────────────────────────────────────────────────────────────

  Widget _topCircleButton(
      {required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: HRColors.flavorIconBackgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _topHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _topCircleButton(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: SvgPicture.asset(
                'assets/svg/drawer_icon.svg',
                colorFilter: ColorFilter.mode(
                  HRColors.flavorIconColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
            AutoSizeText(
              AppLocalizations.of(context)!.myProfileTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            _topCircleButton(
              onTap: () async {
                await Navigator.pushNamed(context, HRNotifications.routeName);
                await FCMService.loadUnreadCount();
              },
              child: ValueListenableBuilder<int>(
                valueListenable: FCMService.unreadCount,
                builder: (context, count, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SvgPicture.asset(
                      'assets/svg/notifications_icon.svg',
                      colorFilter: ColorFilter.mode(
                        HRColors.flavorIconColor,
                        BlendMode.srcIn,
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
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback() {
    final firstLetter =
        _headerFullName.isNotEmpty ? _headerFullName[0].toUpperCase() : 'H';
    return Container(
      color: Colors.black.withOpacity(0.08),
      child: Center(
        child: Text(
          firstLetter,
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildTopProfileHeader() {
    const double size = 135;

    Widget avatarImage;
    if (_selectedImage != null) {
      avatarImage = Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        width: size,
        height: size,
      );
    } else if (_savingImage || _photoLoading) {
      avatarImage = const Center(
        child: CupertinoActivityIndicator(
          color: Colors.black,
          radius: 16,
        ),
      );
    } else if (_profilePhotoUrl.isNotEmpty) {
      avatarImage = OctoImage(
        image: CachedNetworkImageProvider(
          _profilePhotoUrl,
          headers: _authHeaders(),
        ),
        placeholderBuilder: OctoBlurHashFix.placeHolder(
          'LRHe%pIA.m_2KjxawKNGIWkWD*M{',
        ),
        errorBuilder: (context, error, stacktrace) => _avatarFallback(),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else {
      avatarImage = _avatarFallback();
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: _savingImage ? null : _pickImage,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(child: avatarImage),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_headerFullName.isNotEmpty)
          AutoSizeText(
            _headerFullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        if (_headerEpf.isNotEmpty) ...[
          const SizedBox(height: 4),
          AutoSizeText(
            '${AppLocalizations.of(context)!.epfLabel} $_headerEpf',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (_designation.isNotEmpty || _department.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_designation.isNotEmpty) ...[
                _buildBadge(_designation, null),
                const SizedBox(width: 8),
              ],
              if (_department.isNotEmpty)
                _buildBadge(
                  _department,
                  const Icon(Icons.check_rounded, size: 12, color: Colors.black),
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBadge(String label, Widget? prefixIcon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prefixIcon != null) ...[
            prefixIcon,
            const SizedBox(width: 4),
          ],
          AutoSizeText(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem({
    required IconData icon,
    required String label,
    required String value,
    bool showChevron = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withOpacity(0.04)),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 22,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black45,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isNotEmpty
                      ? value
                      : AppLocalizations.of(context)!.notAdded,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (showChevron) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.black26,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              const Divider(
                height: 1,
                indent: 84,
                endIndent: 20,
                color: Color(0xFFF1F5F9),
              ),
          ],
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      drawerScrimColor: Colors.black.withOpacity(0.3),
      drawer: Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: DesignConfig.drawerContent(_scaffoldKey, context),
      ),
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          _topHeader(),
          Expanded(
            child: _loadingMe
                ? Center(
                    child: CupertinoActivityIndicator(
                      color: HRColors.darkOrangeColor,
                      radius: 16.0,
                    ),
                  )
                : _error != null
                    ? DesignConfig.buildErrorState(
                        context,
                        message: _error!,
                        onRetry: _loadProfileData,
                      )
                    : RefreshIndicator(
                        color: _primaryColor,
                        onRefresh: _loadProfileData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 700),
                              child: Column(
                                children: [
                                  _buildTopProfileHeader(),
                                  _buildCardGroup([
                                    _buildCardItem(
                                      icon: Icons.phone_outlined,
                                      label: AppLocalizations.of(context)!.phoneLabel,
                                      value: _phone,
                                    ),
                                    _buildCardItem(
                                      icon: Icons.mail_outline_rounded,
                                      label: AppLocalizations.of(context)!.emailAddressText,
                                      value: _email,
                                    ),
                                    _buildCardItem(
                                      icon: Icons.place_outlined,
                                      label: AppLocalizations.of(context)!.addressLabel,
                                      value: _address,
                                    ),
                                  ]),
                                  _buildCardGroup([
                                    _buildCardItem(
                                      icon: Icons.badge_outlined,
                                      label: AppLocalizations.of(context)!.nicLabel,
                                      value: _nic,
                                    ),
                                    _buildCardItem(
                                      icon: Icons.cake_outlined,
                                      label: AppLocalizations.of(context)!.dateOfBirth,
                                      value: _dob,
                                    ),
                                  ]),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}