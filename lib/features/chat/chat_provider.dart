import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../core/database/local_db.dart';

class ChatProvider extends ChangeNotifier {
  List<Contact> _contacts = [];
  final List<Map<String, dynamic>> _matchedUsers = [];
  final List<Contact> _unmatchedContacts = [];
  bool _loading = false;

  List<Map<String, dynamic>> get matchedUsers => _matchedUsers;
  List<Contact> get unmatchedContacts => _unmatchedContacts;
  bool get loading => _loading;

  Future<void> syncContacts() async {
    _loading = true;
    notifyListeners();

    try {
      if (await FlutterContacts.requestPermission()) {
        _contacts = await FlutterContacts.getContacts(withProperties: true);

        _matchedUsers.clear();
        _unmatchedContacts.clear();

        for (var contact in _contacts) {
          bool matched = false;
          for (var phone in contact.phones) {
            final normalized = _normalizePhone(phone.number);
            final user = await LocalDb.getUserByPhone(normalized);
            if (user != null) {
              _matchedUsers.add({
                'contact': contact,
                'user': user,
              });
              matched = true;
              break;
            }
          }
          if (!matched) {
            _unmatchedContacts.add(contact);
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing contacts: $e');
    }

    _loading = false;
    notifyListeners();
  }

  String _normalizePhone(String phone) {
    // Remove all non-digit characters
    return phone.replaceAll(RegExp(r'\D'), '');
  }
}
