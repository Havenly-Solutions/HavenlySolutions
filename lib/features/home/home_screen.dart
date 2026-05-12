import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../chat/chat_screen.dart';
import '../cases/cases_screen.dart';
import '../feed/feed_screen.dart';
import '../../core/services/sos_orchestrator.dart';
import '../../core/constants/translations.dart';
import '../../core/providers/language_provider.dart';
import '../../core/widgets/app_background.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/safety_metrics_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0;

  // SOS hold state
  bool _sosPressing = false;
  double _sosProgress = 0.0;
  AnimationController? _sosController;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MetricsProvider>().loadMetrics();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<MetricsProvider>().loadMetrics();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sosController?.dispose();
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
    Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);

    await SosOrchestrator.trigger();

    if (mounted) {
      Navigator.pushNamed(context, '/sos_active');
    }
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    
    final String title;
    final String subtitle;
    
    switch(_currentIndex) {
      case 1: 
        title = AppTranslations.t('feed_title');
        subtitle = 'Havenly Solutions';
        break;
      case 2:
        title = AppTranslations.t('chat_title');
        subtitle = 'Havenly Solutions';
        break;
      case 3:
        title = AppTranslations.t('cases_title');
        subtitle = 'Havenly Solutions';
        break;
      default:
        title = 'Havenly Solutions';
        subtitle = AppTranslations.t('app_tagline');
    }

    return AppBackground(
      headerTitle: title,
      headerSubtitle: subtitle,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _HomeContent(
              onSosHoldStart: _onSosHoldStart,
              onSosHoldEnd: _onSosHoldEnd,
              sosProgress: _sosProgress,
              sosPressing: _sosPressing,
              onNavTap: _onNavTap,
            ),
            const FeedScreen(),
            const ChatScreen(),
            const CasesScreen(),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
          onSosHoldStart: _onSosHoldStart,
          onSosHoldEnd: _onSosHoldEnd,
          sosProgress: _sosProgress,
          sosPressing: _sosPressing,
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final VoidCallback onSosHoldStart;
  final VoidCallback onSosHoldEnd;
  final double sosProgress;
  final bool sosPressing;
  final ValueChanged<int> onNavTap;

  const _HomeContent({
    required this.onSosHoldStart,
    required this.onSosHoldEnd,
    required this.sosProgress,
    required this.sosPressing,
    required this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final metricsProvider = context.watch<MetricsProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.t('welcome_back'),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    AppTranslations.t('app_tagline'),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFF1F5F9),
                    backgroundImage: userProvider.currentUser?.profileImagePath != null
                        ? FileImage(File(userProvider.currentUser!.profileImagePath!))
                        : null,
                    child: userProvider.currentUser?.profileImagePath == null
                        ? const Icon(Icons.person_outline, color: Colors.black, size: 18)
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SafetyMetricsCard(
            metrics: metricsProvider.metrics,
            isLoading: metricsProvider.isLoading,
          ),
          const SizedBox(height: 8),
          _FeatureCard(
            title: 'Emergency Help',
            desc: 'Access all local emergency and medical numbers.',
            icon: Icons.phone_forwarded,
            color: const Color(0xFFE53935),
            onTap: () => Navigator.pushNamed(context, '/emergency_numbers'),
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            title: 'Community Feed',
            desc: 'Stay informed about safety incidents in your area.',
            icon: Icons.feed_outlined,
            color: Colors.black,
            onTap: () => onNavTap(1),
          ),
          const Expanded(child: SizedBox()),
          _SOSButton(
            pressing: sosPressing,
            progress: sosProgress,
            onHoldStart: onSosHoldStart,
            onHoldEnd: onSosHoldEnd,
            size: 220,
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    desc,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SOSButton extends StatelessWidget {
  final bool pressing;
  final double progress;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;
  final double size;

  const _SOSButton({
    required this.pressing,
    required this.progress,
    required this.onHoldStart,
    required this.onHoldEnd,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => onHoldStart(),
      onLongPressEnd: (_) => onHoldEnd(),
      onLongPressCancel: onHoldEnd,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 10,
                backgroundColor: Colors.grey.shade100,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
              ),
            ),
            Container(
              width: size - 34,
              height: size - 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE53935),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE53935).withOpacity(0.4),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
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

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onSosHoldStart;
  final VoidCallback onSosHoldEnd;
  final double sosProgress;
  final bool sosPressing;

  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.onSosHoldStart,
    required this.onSosHoldEnd,
    required this.sosProgress,
    required this.sosPressing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      height: 72,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_filled,
            label: 'Home',
            selected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.feed_outlined,
            activeIcon: Icons.feed,
            label: 'News',
            selected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            label: 'Chat',
            selected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.folder_open_outlined,
            activeIcon: Icons.folder_open,
            label: 'Reports',
            selected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          // Separate SOS Button on the right corner for non-home screens
          if (currentIndex != 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _SOSButton(
                pressing: sosPressing,
                progress: sosProgress,
                onHoldStart: onSosHoldStart,
                onHoldEnd: onSosHoldEnd,
                size: 56,
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? activeIcon : icon,
              color: selected ? Colors.white : Colors.grey.shade600,
              size: 26,
            ),
            const SizedBox(height: 4),
            if (selected)
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
