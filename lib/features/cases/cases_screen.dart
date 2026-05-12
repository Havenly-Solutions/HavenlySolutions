import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/translations.dart';
import '../../core/providers/language_provider.dart';
import '../../features/cases/case_provider.dart';
import '../../core/models/case_model.dart';
import '../../providers/user_provider.dart';

class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _evidenceController;
  String _selectedCategory = CaseProvider.categories.first;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _evidenceController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaseProvider>().loadCases();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  Future<void> _showNewCaseDialog() async {
    final provider = context.read<CaseProvider>();
    final userProvider = context.read<UserProvider>();
    _selectedCategory = CaseProvider.categories.first;
    _descriptionController.clear();
    _evidenceController.clear();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.t('new_case'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: CaseProvider.categories
                        .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => _selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _evidenceController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Evidence / Notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _descriptionController.text.trim().isEmpty
                          ? null
                          : () async {
                              final navigator = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              final result = await provider.submitCase(
                                userId: userProvider.currentUser?.id ?? 'local_user',
                                community: userProvider.currentUser?.community ?? 'Unknown Community',
                                category: _selectedCategory,
                                description: _descriptionController.text.trim(),
                                evidence: _evidenceController.text.trim(),
                              );
                              if (!mounted) return;
                              if (result) {
                                navigator.pop();
                                messenger.showSnackBar(
                                  SnackBar(content: Text(AppTranslations.t('case_submitted'))),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      ),
                      child: Text(AppTranslations.t('case_submit'), style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final provider = context.watch<CaseProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppTranslations.t('cases_title'),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _showNewCaseDialog,
            child: Text(AppTranslations.t('new_case'), style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : provider.cases.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open_outlined, color: Colors.grey.shade300, size: 64),
                      const SizedBox(height: 24),
                      Text(
                        AppTranslations.t('cases_title'),
                        style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No reports filed yet.',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: provider.cases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final caseItem = provider.cases[index];
                    return _CaseTile(caseItem: caseItem);
                  },
                ),
    );
  }
}

class _CaseTile extends StatelessWidget {
  final CaseModel caseItem;

  const _CaseTile({required this.caseItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(caseItem.category, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: caseItem.status == 'pending' ? Colors.orange.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  caseItem.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: caseItem.status == 'pending' ? Colors.orange.shade800 : Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(caseItem.description, style: TextStyle(color: Colors.grey.shade800, height: 1.4)),
          if (caseItem.evidence.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Evidence: ${caseItem.evidence}', style: TextStyle(color: Colors.grey.shade600)),
          ],
          const SizedBox(height: 12),
          Text(
            'Filed ${caseItem.createdAt.day}/${caseItem.createdAt.month}/${caseItem.createdAt.year}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
