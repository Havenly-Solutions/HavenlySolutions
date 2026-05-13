// FILE: mobile/lib/features/auth/guest_portal_screen.dart
// Phase 10 — Guest portal with limited access
// Guest sees: SOS, minor cases only, register/login prompt
// Guest does NOT see: news feed, community chat

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/translations.dart';
import '../../app/routes.dart';

class GuestPortalScreen extends StatefulWidget {
  const GuestPortalScreen({super.key});

  @override
  State<GuestPortalScreen> createState() => _GuestPortalScreenState();
}

class _GuestPortalScreenState extends State<GuestPortalScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  // SOS PIN state
  bool _showSosPad = false;
  final List<String> _sosPin = ['', '', '', ''];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _exitGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest_session', false);
    if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.auth);
  }

  void _onSosDigit(String d) {
    final idx = _sosPin.indexOf('');
    if (idx == -1) return;
    setState(() => _sosPin[idx] = d);
    if (_sosPin.every((c) => c.isNotEmpty)) {
      _submitGuestSos();
    }
  }

  void _onSosDelete() {
    final last = _sosPin.lastIndexWhere((c) => c.isNotEmpty);
    if (last == -1) return;
    setState(() => _sosPin[last] = '');
  }

  Future<void> _submitGuestSos() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      setState(() {
        _showSosPad = false;
        _sosPin.fillRange(0, 4, '');
      });
      Navigator.pushNamed(context, '/sos_active');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Status bar spacer
          SizedBox(height: MediaQuery.of(context).padding.top),

          // Guest banner
          Container(
            width: double.infinity,
            color: const Color(0xFF1A0000),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.person_outline,
                    color: Color(0xFFE53935), size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Guest Mode — Limited access',
                    style: TextStyle(
                      color: Color(0xFFE53935),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _exitGuest,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFFE53935)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _GuestHomeTab(
                  pulse: _pulse,
                  showPad: _showSosPad,
                  sosPin: _sosPin,
                  onSosTap: () => setState(() {
                    _showSosPad = true;
                    _sosPin.fillRange(0, 4, '');
                  }),
                  onDigit: _onSosDigit,
                  onDelete: _onSosDelete,
                  onCancelPad: () =>
                      setState(() => _showSosPad = false),
                ),
                const _GuestCasesTab(),
                _GuestProfileTab(onExit: _exitGuest),
              ],
            ),
          ),

          // Bottom nav — 3 items only
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0D0D0D),
              border: Border(
                  top: BorderSide(color: Color(0xFF1A1A1A))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  _GuestNavItem(
                    icon: Icons.shield_outlined,
                    activeIcon: Icons.shield,
                    label: 'Safety',
                    selected: _currentIndex == 0,
                    onTap: () =>
                        setState(() => _currentIndex = 0),
                  ),
                  _GuestNavItem(
                    icon: Icons.folder_outlined,
                    activeIcon: Icons.folder,
                    label: 'Report',
                    selected: _currentIndex == 1,
                    onTap: () =>
                        setState(() => _currentIndex = 1),
                  ),
                  _GuestNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Account',
                    selected: _currentIndex == 2,
                    onTap: () =>
                        setState(() => _currentIndex = 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GuestNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? activeIcon : icon,
                color: selected
                    ? const Color(0xFFE53935)
                    : Colors.grey.shade700,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFFE53935)
                      : Colors.grey.shade700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── GUEST HOME TAB ───────────────────────────────────────────

class _GuestHomeTab extends StatelessWidget {
  final Animation<double> pulse;
  final bool showPad;
  final List<String> sosPin;
  final VoidCallback onSosTap;
  final void Function(String) onDigit;
  final VoidCallback onDelete;
  final VoidCallback onCancelPad;

  const _GuestHomeTab({
    required this.pulse,
    required this.showPad,
    required this.sosPin,
    required this.onSosTap,
    required this.onDigit,
    required this.onDelete,
    required this.onCancelPad,
  });

  @override
  Widget build(BuildContext context) {
    if (showPad) {
      return _buildPinPad(context);
    }
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 32),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              'Emergency SOS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Hold the button for 3 seconds to trigger',
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 48),
            ScaleTransition(
              scale: pulse,
              child: GestureDetector(
                onLongPress: onSosTap,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE53935),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x55E53935),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hold for 3 seconds',
              style: TextStyle(
                  color: Colors.grey.shade700, fontSize: 12),
            ),
            const SizedBox(height: 48),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1A1A1A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AVAILABLE WITH A FREE ACCOUNT',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FeatureRow(
                    icon: Icons.newspaper_outlined,
                    label: 'Havenly Solutions News',
                  ),
                  const SizedBox(height: 10),
                  _FeatureRow(
                    icon: Icons.people_outline,
                    label: 'Community Chat',
                  ),
                  const SizedBox(height: 10),
                  _FeatureRow(
                    icon: Icons.folder_open_outlined,
                    label: 'Full Case Filing to SAPS',
                  ),
                  const SizedBox(height: 10),
                  _FeatureRow(
                    icon: Icons.shield_outlined,
                    label: 'Personal SOS PIN Identity',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinPad(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 28, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Enter Your PIN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your PIN identifies you so emergency\nservices know who to help.',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = sosPin[i].isNotEmpty;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? const Color(0xFFE53935)
                      : const Color(0xFF2A2A2A),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: keys.map((row) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row.map((k) {
                    if (k.isEmpty) {
                      return const SizedBox(width: 72, height: 64);
                    }
                    return GestureDetector(
                      onTap: () {
                        if (k == 'del') {
                          onDelete();
                        } else {
                          onDigit(k);
                        }
                      },
                      child: Container(
                        width: 72,
                        height: 64,
                        margin:
                            const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        alignment: Alignment.center,
                        child: k == 'del'
                            ? const Icon(Icons.backspace_outlined,
                                color: Colors.white, size: 20)
                            : Text(
                                k,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
          TextButton(
            onPressed: onCancelPad,
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE53935), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
        ),
        const Icon(Icons.lock_outline,
            color: Color(0xFF2A2A2A), size: 14),
      ],
    );
  }
}

// ── GUEST CASES TAB ──────────────────────────────────────────

class _GuestCasesTab extends StatefulWidget {
  const _GuestCasesTab();

  @override
  State<_GuestCasesTab> createState() => _GuestCasesTabState();
}

class _GuestCasesTabState extends State<_GuestCasesTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedCategory;
  bool _submitting = false;
  bool _submitted = false;

  final List<String> _minorCategories = [
    'Noise complaint',
    'Littering / Illegal dumping',
    'Vandalism (minor)',
    'Trespassing',
    'Stray animals',
    'Broken streetlight',
    'Suspicious activity (minor)',
    'Other minor issue',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _submitting = false;
        _submitted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle,
                  color: Color(0xFF4CAF50), size: 64),
              const SizedBox(height: 20),
              const Text(
                'Report Submitted',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your report has been logged. Create an account to file high-priority cases directly to SAPS.',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      setState(() => _submitted = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Submit Another Report',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SAPS header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF003087),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_police,
                      color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SOUTH AFRICAN POLICE SERVICE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Minor Incident Report — Guest',
                        style: TextStyle(
                            color: Color(0xFFAEC6E8),
                            fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFFFD700), width: 0.5),
              ),
              child: const Text(
                'Guest mode allows minor reports only. Sign up to file high-priority cases (assault, theft, GBV) directly to SAPS.',
                style: TextStyle(
                    color: Color(0xFF856404), fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'YOUR DETAILS',
              style: TextStyle(
                color: Color(0xFF757575),
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _CaseField(
                controller: _nameController,
                label: 'First Name',
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Required'
                    : null),
            const SizedBox(height: 10),
            _CaseField(
                controller: _surnameController,
                label: 'Surname',
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Required'
                    : null),
            const SizedBox(height: 10),
            _CaseField(
              controller: _idController,
              label: 'ID Number',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (v.trim().length != 13) {
                  return 'Must be 13 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            _CaseField(
              controller: _emailController,
              label: 'Email Address',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!v.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            const SizedBox(height: 10),
            _CaseField(
              controller: _phoneController,
              label: 'Contact Number',
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Required'
                  : null,
            ),
            const SizedBox(height: 16),
            const Text(
              'INCIDENT DETAILS',
              style: TextStyle(
                color: Color(0xFF757575),
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Incident Category',
                labelStyle:
                    TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: const Color(0xFF111111),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF222222)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF222222)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFFE53935)),
                ),
              ),
              dropdownColor: const Color(0xFF111111),
              style: const TextStyle(
                  color: Colors.white, fontSize: 14),
              items: _minorCategories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ))
                  .toList(),
              validator: (v) =>
                  v == null ? 'Select a category' : null,
              onChanged: (v) =>
                  setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 10),
            _CaseField(
              controller: _descController,
              label: 'Describe the incident',
              maxLines: 4,
              validator: (v) {
                if (v == null || v.trim().length < 10) {
                  return 'Please provide at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003087),
                  disabledBackgroundColor:
                      const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Minor Report',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _CaseField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _CaseField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500),
        filled: true,
        fillColor: const Color(0xFF111111),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF222222)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF222222)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE53935)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE53935)),
        ),
      ),
    );
  }
}

// ── GUEST PROFILE TAB ─────────────────────────────────────────

class _GuestProfileTab extends StatelessWidget {
  final VoidCallback onExit;

  const _GuestProfileTab({required this.onExit});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Avatar placeholder
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A1A),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: const Icon(Icons.person,
                color: Color(0xFF424242), size: 40),
          ),
          const SizedBox(height: 12),
          const Text(
            'Guest User',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0000),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFE53935).withOpacity(0.4)),
            ),
            child: const Text(
              'GUEST MODE',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 36),
          // Create account button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.signup);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Create Free Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: onExit,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2A2A2A)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Sign In to Existing Account',
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0D),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1A1A1A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WHY CREATE AN ACCOUNT?',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _WhyItem(
                  icon: Icons.shield,
                  text: 'Your identity dispatched with every SOS',
                ),
                _WhyItem(
                  icon: Icons.newspaper,
                  text: 'Post and read all community news',
                ),
                _WhyItem(
                  icon: Icons.people,
                  text: 'Join your local community chat',
                ),
                _WhyItem(
                  icon: Icons.folder,
                  text: 'File full cases directly to SAPS',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhyItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _WhyItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE53935), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  color: Colors.grey.shade300, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}