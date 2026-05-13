import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/widgets/saps_badge.dart';
import '../../core/widgets/trust_banner.dart';
import '../../providers/user_provider.dart';
import './models/case_model.dart';
import './providers/case_provider.dart';

class CaseCreateScreen extends StatefulWidget {
  const CaseCreateScreen({super.key});

  @override
  State<CaseCreateScreen> createState() => _CaseCreateScreenState();
}

class _CaseCreateScreenState extends State<CaseCreateScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Step 0 controllers
  String? _incidentType;
  final _dateController = TextEditingController();
  DateTime? _incidentDate;
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Step 1 controllers
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyController = TextEditingController();
  String? _language;

  // Step 2 controllers
  final _evidenceDescController = TextEditingController();

  final List<String> _incidentTypes = [
    'Domestic Violence / Abuse',
    'Sexual Assault / Rape',
    'GBV — Gender-Based Violence',
    'Theft / Robbery',
    'Hijacking',
    'Kidnapping / Missing Person',
    'Assault / Physical Harm',
    'Stalking / Harassment',
    'Other'
  ];

  final List<String> _languages = [
    'English', 'Zulu', 'Xhosa', 'Afrikaans', 'Sotho', 'Tswana', 'Venda', 'Tsonga'
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().currentUser;
    if (user != null) {
      _nameController.text = user.fullName;
      _phoneController.text = user.phoneNumber;
      _idController.text = user.idNumber ?? '';
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _submitReport();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submitReport() async {
    final caseId = const Uuid().v4();
    final now = DateTime.now();
    final refNumber = 'HVN-${now.year}-${(now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}';

    final newCase = CaseModel(
      id: caseId,
      refNumber: refNumber,
      incidentType: _incidentType ?? 'Other',
      incidentDate: _incidentDate ?? now,
      locationAddress: _locationController.text,
      description: _descriptionController.text,
      status: 'received',
      synced: false,
      createdAt: now,
      evidenceUrls: [],
    );

    final success = await context.read<CaseProvider>().submitCase(newCase);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your report has been submitted. SAPS reference: $refNumber'),
          backgroundColor: const Color(0xFF1A7A4A),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF002366),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _prevStep,
        ),
        title: const Text(
          'New Report',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Center(child: SapsBadge()))],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStepLabels(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: _buildCurrentStep(),
              ),
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildStepLabels() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StepLabel(text: 'Incident', isActive: _currentStep == 0),
          _StepLabel(text: 'Your Info', isActive: _currentStep == 1),
          _StepLabel(text: 'Evidence', isActive: _currentStep == 2),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildStep0();
      case 1: return _buildStep1();
      case 2: return _buildStep2();
      default: return const SizedBox();
    }
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('What happened?', 'Please share as much or as little as you feel comfortable with. This report is private and confidential.'),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _incidentType,
          items: _incidentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _incidentType = v),
          decoration: _inputDecoration('Type of incident'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _dateController,
          readOnly: true,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() {
                _incidentDate = date;
                _dateController.text = DateFormat('yyyy-MM-dd').format(date);
              });
            }
          },
          decoration: _inputDecoration('When did this happen?', hint: 'Date of the incident'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _locationController,
          decoration: _inputDecoration('Where did it happen?', hint: 'Street address, area or describe the location', prefix: Icons.location_on),
        ),
        const SizedBox(height: 12),
        _buildMapPlaceholder(),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          maxLines: 5,
          maxLength: 1000,
          decoration: _inputDecoration('Tell us what happened', hint: 'Describe what happened in your own words. Take your time.'),
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => const Text(
            'Everything you write is secure and will only be seen by SAPS officers.',
            style: TextStyle(fontSize: 10, color: Color(0xFF8A9BB0)),
          ),
        ),
        const SizedBox(height: 24),
        const TrustBanner(
          icon: Icons.shield,
          text: 'Your report is encrypted and submitted directly to SAPS. You do not need to visit a police station to open this case.',
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('Your details', 'This helps SAPS contact you. Your ID number is encrypted and cannot be read by anyone except your assigned officer.'),
        const SizedBox(height: 20),
        TextFormField(controller: _nameController, decoration: _inputDecoration('Full name', hint: 'Your name as per your ID document')),
        const SizedBox(height: 16),
        TextFormField(
          controller: _idController,
          maxLength: 13,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration('South African ID number', hint: '13-digit ID number (encrypted)'),
        ),
        const SizedBox(height: 16),
        TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: _inputDecoration('Phone number', hint: '+27 or 0XX XXX XXXX')),
        const SizedBox(height: 16),
        TextFormField(controller: _emergencyController, decoration: _inputDecoration('Emergency contact (optional)', hint: 'Name and phone number')),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _language,
          items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
          onChanged: (v) => setState(() => _language = v),
          decoration: _inputDecoration('Preferred language for updates'),
        ),
        const SizedBox(height: 24),
        const TrustBanner(
          icon: Icons.lock,
          text: 'Your ID number and contact details are AES-256 encrypted. Only authorised SAPS officers assigned to your case can view them.',
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('Add evidence (optional)', 'Photos, screenshots, voice notes or documents. This step is optional but helps SAPS act faster on your report.'),
        const SizedBox(height: 20),
        TextFormField(
          controller: _evidenceDescController,
          maxLines: 3,
          decoration: _inputDecoration('Describe what this evidence shows', hint: 'e.g. Photo of bruising taken on the same day.'),
        ),
        const SizedBox(height: 16),
        _buildUploadZone(),
        const SizedBox(height: 24),
        const TrustBanner(
          icon: Icons.shield,
          text: 'All files are encrypted and stored on SAPS-approved secure servers. They are only accessible by your assigned case officer.',
        ),
      ],
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568), height: 1.5)),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint, IconData? prefix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix != null ? Icon(prefix, size: 20, color: const Color(0xFF002366)) : null,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: Color(0xFF4A5568), fontSize: 14),
      hintStyle: const TextStyle(color: Color(0xFF8A9BB0), fontSize: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDDE3EE))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDDE3EE))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF002366))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 130,
      decoration: BoxDecoration(color: const Color(0xFFF0F3F8), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFDDE3EE))),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, color: Color(0xFF8A9BB0), size: 32),
              SizedBox(height: 8),
              Text('Confirm on map', style: TextStyle(color: Color(0xFF4A5568), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
              child: const Text('Optional', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF8A9BB0))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadZone() {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File upload will be connected to S3 in the next task'))),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE3EE), width: 1, style: BorderStyle.solid), // Dotted appearance would need CustomPaint
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, color: Color(0xFF002366), size: 40),
            SizedBox(height: 12),
            Text('Upload photos, videos or documents', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
            SizedBox(height: 4),
            Text('JPG, PNG, MP4, PDF — up to 50MB each', style: TextStyle(fontSize: 11, color: Color(0xFF8A9BB0))),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFDDE3EE)))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentStep == 0) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: () {}, child: const Text('Save as draft')),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFCC0000)), foregroundColor: const Color(0xFFCC0000)),
                child: const Text('Cancel'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep == 2 ? const Color(0xFF1A7A4A) : const Color(0xFF002366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_currentStep == 2) const Icon(Icons.check, size: 18),
                  if (_currentStep == 2) const SizedBox(width: 8),
                  Text(
                    _currentStep == 2 ? 'Submit Report to SAPS' : 'Continue to Step ${_currentStep + 2} \u2192',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          if (_currentStep > 0) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: _prevStep, child: const Text('Back to previous step', style: TextStyle(color: Color(0xFF8A9BB0)))),
          ]
        ],
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String text;
  final bool isActive;

  const _StepLabel({required this.text, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
        color: isActive ? const Color(0xFF002366) : const Color(0xFF8A9BB0),
      ),
    );
  }
}
