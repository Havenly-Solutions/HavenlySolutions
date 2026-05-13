import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ContactsTab extends StatefulWidget {
  const ContactsTab({super.key});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  List<Contact>? _contacts;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    try {
      if (!await FlutterContacts.requestPermission()) {
        setState(() => _permissionDenied = true);
      } else {
        final contacts = await FlutterContacts.getContacts(withProperties: true);
        setState(() => _contacts = contacts);
      }
    } catch (e) {
      debugPrint('Error fetching contacts: \$e');
      setState(() => _permissionDenied = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) return const Center(child: Text('Permission denied or error fetching contacts'));
    if (_contacts == null) return const Center(child: CircularProgressIndicator());

    return ListView.builder(
      itemCount: _contacts!.length,
      itemBuilder: (context, index) {
        final contact = _contacts![index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.backgroundLight,
            child: Text(contact.displayName.isNotEmpty ? contact.displayName[0] : '?'),
          ),
          title: Text(contact.displayName, style: AppTypography.bodyLarge),
          subtitle: Text(contact.phones.isNotEmpty ? contact.phones.first.number : 'No phone', style: AppTypography.bodySmall),
          trailing: TextButton(
            onPressed: () {},
            child: const Text('Invite', style: TextStyle(color: AppColors.emergency)),
          ),
        );
      },
    );
  }
}
