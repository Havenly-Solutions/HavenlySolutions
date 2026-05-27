import 'package:flutter_contacts/flutter_contacts.dart';
import '../utils/crypto_utils.dart';
import '../database/local_db.dart';
import 'api_service.dart';

class ContactDiscoveryService {
  ContactDiscoveryService._();
  static final ContactDiscoveryService instance = ContactDiscoveryService._();

  /// Reads the device phonebook, hashes all numbers, and discovers which contacts are registered Havenly users.
  /// As per Master Build Prompt Section 12.
  Future<void> syncContacts() async {
    if (!await FlutterContacts.requestPermission()) return;

    final rawContacts = await FlutterContacts.getContacts(withProperties: true);

    // Hash all normalized phone numbers
    final Map<String, String> hashMap = {}; // Hash -> Display Name
    final List<String> hashes = [];

    for (final contact in rawContacts) {
      if (contact.phones.isNotEmpty) {
        for (final phone in contact.phones) {
          final hash = CryptoUtils.hashPhone(phone.number);
          hashMap[hash] = contact.displayName;
          hashes.add(hash);
        }
      }
    }

    if (hashes.isEmpty) return;

    // POST only hashes to backend
    final api = ApiService();
    try {
      final response = await api.discoverContacts(hashes.toSet().toList());
      final List<dynamic> registered = response['contacts'];

      for (final userData in registered) {
        final hash = userData['phoneHash'];
        final userId = userData['id'];
        final fullName = userData['fullName'];

        // Upsert into local SQLite contacts table
        await LocalDb.upsertContact({
          'id': userId,
          'phone_hash': hash,
          'display_name': hashMap[hash] ?? fullName,
          'is_havenly_user': 1,
          'havenly_user_id': userId,
          'last_synced': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      print('[ContactDiscovery] Sync failed: $e');
    }
  }
}
