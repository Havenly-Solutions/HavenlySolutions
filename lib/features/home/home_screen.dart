import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../Shared/theme/app_theme.dart';
import '../../core/providers/language_provider.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/safety_metrics_card.dart';
import '../../app/routes.dart';
import '../../features/cases/case_create_screen.dart';
import '../../services/geo_location_service.dart';
import '../../services/sos_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0;

  // SOS hold state
  bool _sosPressing = false;
  double _sosProgress = 0.0;
  AnimationController? _sosController;
  late AnimationController _pulseController;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _sosController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        setState(() => _sosProgress = _sosController!.value);
        if (_sosController!.value >= 1.0) {
          _fireSOS();
        }
      });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MetricsProvider>().loadMetrics();
      context.read<GeoLocationService>().initialise();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<MetricsProvider>().loadMetrics();
      context.read<GeoLocationService>().initialise();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sosController?.dispose();
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onSosHoldStart() {
    setState(() => _sosPressing = true);
    HapticFeedback.heavyImpact();
    _sosController?.forward(from: 0);
  }

  void _onSosHoldEnd() {
    if (_sosProgress < 1.0) {
      _sosController?.stop();
      _sosController?.reverse();
      setState(() {
        _sosPressing = false;
        _sosProgress = 0.0;
      });
    }
  }

  Future<void> _fireSOS() async {
    setState(() {
      _sosPressing = false;
      _sosProgress = 0.0;
    });
    _sosController?.reset();
    HapticFeedback.heavyImpact();

    final geoService = context.read<GeoLocationService>();
    await SOSService().triggerSOS(
      triggerType: SOSTriggerType.manualButton,
      geoService: geoService,
    );

    if (mounted) {
      Navigator.pushNamed(context, AppRoutes.sosActive);
    }
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        setState(() => _currentIndex = 0);
        return;
      case 1:
        Navigator.pushNamed(context, AppRoutes.news);
        return;
      case 2:
        Navigator.pushNamed(context, AppRoutes.chat);
        return;
      case 3:
        Navigator.pushNamed(context, AppRoutes.cases);
        return;
      default:
        return;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Good morning";
    if (hour >= 12 && hour < 17) return "Good afternoon";
    if (hour >= 17 && hour < 21) return "Good evening";
    return "Stay safe tonight";
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final user = context.watch<UserProvider>().currentUser;
    final metricsProvider = context.watch<MetricsProvider>();
    final geoService = context.watch<GeoLocationService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF1A1A2E),
                      backgroundImage: user?.profileImagePath != null
                          ? FileImage(File(user!.profileImagePath!))
                          : null,
                      child: user?.profileImagePath == null
                          ? Text(
                              user?.fullName.isNotEmpty == true
                                  ? user!.fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            )
                          : null,
                    ),
                  ),
                      Text(
                    'Havenly Solutions',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined,
                            color: Color(0xFF1A1A2E)),
                        onPressed: () {},
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFC0392B),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '${_getGreeting()}, ${user?.firstName ?? "User"}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // STATS ROW
              Row(
                children: [
                      _StatCard(
                    label: 'SOS STATUS',
                    value: 'READY',
                    sub: 'All systems operational',
                    icon: Icons.shield_outlined,
                    iconColor: AppColors.green,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'AREA SAFETY',
                    value: '94/100',
                    sub: 'Your neighbourhood',
                    progress: 0.94,
                    progressColor: AppColors.green,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // SOS BUTTON (HERO)
              Center(
                child: Column(
                  children: [
                    _AnimatedSosButton(
                      pulseController: _pulseController,
                      pressing: _sosPressing,
                      progress: _sosProgress,
                      onHoldStart: _onSosHoldStart,
                      onHoldEnd: _onSosHoldEnd,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _sosPressing
                          ? "HOLDING..."
                          : "Hold 3 seconds to activate",
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // QUICK ACTIONS GRID
              Text(
                'Quick Actions',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _ActionTile(
                    icon: Icons.local_phone_outlined,
                    iconColor: const Color(0xFFC0392B),
                    label: 'Emergency\nNumbers',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.emergencyNumbers),
                  ),
                  _ActionTile(
                    icon: Icons.description_outlined,
                    iconColor: const Color(0xFF1A1A2E),
                    label: 'File a\nReport',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CaseCreateScreen()),
                    ),
                  ),
                  _ActionTile(
                    icon: Icons.newspaper_outlined,
                    iconColor: const Color(0xFF0B6E4F),
                    label: 'Community\nFeed',
                    onTap: () => _onNavTap(1),
                  ),
                  _ActionTile(
                    icon: Icons.chat_bubble_outline,
                    iconColor: const Color(0xFFD4A017),
                    label: 'Community\nChat',
                    onTap: () => _onNavTap(2),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // MAP WIDGET
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.inputFill,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    if (geoService.currentPosition != null)
                      GoogleMap(
                        onMapCreated: (controller) {
                          _mapController = controller;
                          final position = geoService.currentPosition!;
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              LatLng(position.latitude, position.longitude),
                              14,
                            ),
                          );
                        },
                        initialCameraPosition: CameraPosition(
                          target: LatLng(geoService.currentPosition!.latitude,
                              geoService.currentPosition!.longitude),
                          zoom: 14,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('user_location'),
                            position: LatLng(geoService.currentPosition!.latitude,
                                geoService.currentPosition!.longitude),
                            infoWindow: const InfoWindow(title: 'You are here'),
                          ),
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapType: MapType.normal,
                      )
                    else
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off_outlined, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("Enable location for area awareness",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color.fromRGBO(0, 0, 0, 0.6),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                geoService.isInsideCommunity
                                    ? "PROTECTED AREA"
                                    : "CURRENT AREA",
                                style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 10,
                                    color: geoService.isInsideCommunity
                                        ? AppColors.green
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0)),
                            Text(
                                geoService.nearestCommunityName != null
                                    ? geoService.nearestCommunityName!
                                    : geoService.currentSuburb != null
                                        ? "${geoService.currentSuburb}, ${geoService.currentCity}"
                                        : "Locating...",
                                style: const TextStyle(
                                    fontFamily: 'Space Grotesk',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // RECENT ALERTS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Alerts',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onNavTap(1),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        color: Color(0xFFC0392B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _AlertCard(
                type: 'NEWS',
                title: 'Community Safety Update',
                subtitle: 'New safety measures implemented in your area.',
                time: '2m ago',
                icon: Icons.article_outlined,
                iconBg: const Color(0xFFEAF4FB),
                iconColor: const Color(0xFF1A1A2E),
              ),
              _AlertCard(
                type: 'SOS',
                title: 'Assistance Requested',
                subtitle: 'A neighbor has activated an SOS near your location.',
                time: '15m ago',
                icon: Icons.sos_outlined,
                iconBg: const Color(0xFFFDECEA),
                iconColor: const Color(0xFFC0392B),
              ),

              const SizedBox(height: 32),

              // SAFETY METRICS
              SafetyMetricsCard(
                metrics: metricsProvider.metrics,
                isLoading: metricsProvider.isLoading,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _FloatingBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData? icon;
  final Color? iconColor;
  final double? progress;
  final Color? progressColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    this.icon,
    this.iconColor,
    this.progress,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            const BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.03),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                )),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value,
                    style: const TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    )),
                if (icon != null) Icon(icon, color: iconColor, size: 24),
              ],
            ),
            const SizedBox(height: 4),
            Text(sub,
                style: const TextStyle(
                    fontFamily: 'DM Sans', fontSize: 11, color: Colors.grey)),
            if (progress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(
                    progressColor ?? Colors.blue),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnimatedSosButton extends StatelessWidget {
  final AnimationController pulseController;
  final bool pressing;
  final double progress;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  const _AnimatedSosButton({
    required this.pulseController,
    required this.pressing,
    required this.progress,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => onHoldStart(),
      onLongPressEnd: (_) => onHoldEnd(),
      onLongPressCancel: onHoldEnd,
      child: AnimatedBuilder(
        animation: pulseController,
        builder: (context, child) {
          final pulse = pressing ? 0.0 : pulseController.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer rings
              _GlowRing(radius: 120, opacity: 0.08 * (1.0 - pulse)),
              _GlowRing(radius: 96, opacity: 0.15 * (1.0 - pulse)),
              _GlowRing(radius: 72, opacity: 0.25 * (1.0 - pulse)),

              // Progress ring
              SizedBox(
                width: 112,
                height: 112,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),

              // Main button
              Container(
                width: 112,
                height: 112,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFC0392B),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x66C0392B),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'SOS',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GlowRing extends StatelessWidget {
  final double radius;
  final double opacity;
  const _GlowRing({required this.radius, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.fromRGBO(192, 57, 43, opacity),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            const BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.03),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color.fromRGBO(iconColor.r.round(), iconColor.g.round(), iconColor.b.round(), 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String type;
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _AlertCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(subtitle,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    color: Colors.grey,
                  )),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class _FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavIcon(
              icon: Icons.home_filled,
              isActive: currentIndex == 0,
              onTap: () => onTap(0)),
          _NavIcon(
              icon: Icons.feed_outlined,
              isActive: currentIndex == 1,
              onTap: () => onTap(1)),
          _NavIcon(
              icon: Icons.chat_bubble_outline,
              isActive: currentIndex == 2,
              onTap: () => onTap(2)),
          _NavIcon(
              icon: Icons.folder_open_outlined,
              isActive: currentIndex == 3,
              onTap: () => onTap(3)),
          _NavIcon(
            icon: Icons.person_outline,
            isActive: false,
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIcon(
      {required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? const Color.fromRGBO(255, 255, 255, 0.15) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: isActive ? Colors.white : const Color.fromRGBO(255, 255, 255, 0.5), size: 24),
      ),
    );
  }
}
