import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../core/database/local_db.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _loading = true);
    try {
      final user = context.read<UserProvider>().currentUser;
      if (user == null) return;

      final response = await ApiService().get('/api/users/contacts');
      if (response.data['success']) {
        final List data = response.data['data'];
        _contacts = data.cast<Map<String, dynamic>>();

        for (final c in _contacts) {
          await LocalDb.insertEmergencyContact({
            'id': c['id'],
            'user_id': user.id,
            'name': c['name'],
            'phone_number': c['phone_number'],
            'relationship': c['relationship'],
            'created_at': DateTime.parse(c['created_at']).millisecondsSinceEpoch,
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading contacts from API: $e");
      final user = context.read<UserProvider>().currentUser;
      if (user != null) {
        _contacts = await LocalDb.getEmergencyContacts(user.id);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addContact() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const _AddContactSheet(),
    );

    if (result == true) {
      _loadContacts();
    }
  }

  Future<void> _deleteContact(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Contact?"),
        content: const Text("They will no longer receive your SOS alerts."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Remove")),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService().delete('/api/users/contacts/$id');
        await LocalDb.deleteEmergencyContact(id);
        _loadContacts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Emergency Contacts',
            style: TextStyle(
                fontFamily: 'Space Grotesk', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1A2E),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A1A2E)))
          : _contacts.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final c = _contacts[index];
                    return _ContactCard(
                      name: c['name'],
                      phone: c['phone_number'],
                      relationship: c['relationship'] ?? 'Guardian',
                      onDelete: () => _deleteContact(c['id']),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addContact,
        backgroundColor: const Color(0xFF1A1A2E),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Contact",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.contacts_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No contacts added yet",
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
                "Emergency contacts are notified immediately via SMS when you trigger an SOS.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String name;
  final String phone;
  final String relationship;
  final VoidCallback onDelete;

  const _ContactCard(
      {required this.name,
      required this.phone,
      required this.relationship,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1A1A2E).withValues(alpha: 0.1),
          child: Text(name[0].toUpperCase(),
              style: const TextStyle(
                  color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
        ),
        title: Text(name,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontFamily: 'DM Sans')),
        subtitle: Text("$relationship • $phone",
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _AddContactSheet extends StatefulWidget {
  const _AddContactSheet();

  @override
  State<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<_AddContactSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _relationship = 'Family';
  bool _saving = false;

  final List<String> _relationships = [
    'Family',
    'Friend',
    'Work Colleague',
    'Partner',
    'Neighbour',
    'Other'
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final response = await ApiService().post('/api/users/contacts', data: {
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'relationship': _relationship,
      });

      if (response.data['success']) {
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add Emergency Contact",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Space Grotesk')),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => v!.isEmpty ? "Name required" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                  labelText: "Phone Number",
                  hintText: "0XX XXX XXXX",
                  prefixIcon: Icon(Icons.phone_outlined)),
              validator: (v) => v!.length < 10 ? "Invalid phone number" : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _relationship,
              items: _relationships
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _relationship = v),
              decoration: const InputDecoration(
                  labelText: "Relationship",
                  prefixIcon: Icon(Icons.people_outline)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Contact",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
