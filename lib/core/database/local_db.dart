/*
 * ─────────────────────────────────────────────────────────────
 * FILE: lib/core/database/local_db.dart
 * PHASE: 15 — Local SQLite Database
 *
 * PURPOSE:
 *   Primary offline data store. All app data lives here first.
 *   Synced to PostgreSQL backend when connectivity is available.
 * ─────────────────────────────────────────────────────────────
 */

import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class LocalDb {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'havenly_solutions.db');
    return openDatabase(
      path,
      version: 11,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // ── USERS ──────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        phone_number TEXT UNIQUE NOT NULL,
        phone_verified INTEGER DEFAULT 0,
        full_name TEXT NOT NULL,
        display_name TEXT,
        age INTEGER,
        gender TEXT,
        title TEXT,
        race TEXT,
        id_number TEXT,
        passport_number TEXT,
        email TEXT UNIQUE,
        pin_hash TEXT,
        community_id TEXT,
        province TEXT,
        suburb TEXT,
        community_name TEXT,
        last_known_lat REAL,
        last_known_lng REAL,
        last_seen_at INTEGER,
        is_guest INTEGER DEFAULT 0,
        tier TEXT DEFAULT 'FREE',
        profile_image_path TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // ── COMMUNITIES ─────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE communities (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        province TEXT NOT NULL,
        center_lat REAL NOT NULL,
        center_lng REAL NOT NULL,
        radius_km REAL NOT NULL,
        leader_user_id TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // ── EMERGENCY CONTACTS ──────────────────────────────────────
    await db.execute('''
      CREATE TABLE emergency_contacts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        relationship TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // ── SOS EVENTS ──────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE sos_events (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        triggered_at INTEGER NOT NULL,
        trigger_method TEXT NOT NULL DEFAULT 'app',
        lat_at_trigger REAL,
        lng_at_trigger REAL,
        cell_mcc TEXT,
        cell_mnc TEXT,
        cell_lac TEXT,
        cell_cid TEXT,
        layer1_gps INTEGER DEFAULT 0,
        layer2_cell INTEGER DEFAULT 0,
        layer3_mesh INTEGER DEFAULT 0,
        sms_sent INTEGER DEFAULT 0,
        sms_contacts INTEGER DEFAULT 0,
        api_reached INTEGER DEFAULT 0,
        services_notified INTEGER DEFAULT 0,
        status TEXT DEFAULT 'active',
        rescue_method TEXT,
        rescue_confirmed_at INTEGER,
        closed_at INTEGER,
        closed_by TEXT,
        last_lat REAL,
        last_lng REAL,
        last_heartbeat_at INTEGER,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // ── COMMUNITY ALERTS ────────────────────────────────────────
    await db.execute('''
      CREATE TABLE community_alerts (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT,
        body TEXT,
        latitude REAL,
        longitude REAL,
        community_id TEXT,
        created_at INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // ── FEED POSTS ──────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE posts (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT,
        body TEXT,
        image_local_path TEXT,
        contact_name TEXT,
        contact_phone TEXT,
        author_id TEXT NOT NULL,
        author_name TEXT NOT NULL,
        author_age INTEGER,
        author_region TEXT,
        reply_count INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // ── REPLIES ─────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE replies (
        id TEXT PRIMARY KEY,
        post_id TEXT NOT NULL,
        author_id TEXT NOT NULL,
        author_name TEXT NOT NULL,
        author_region TEXT,
        body TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
      )
    ''');

    // ── CONVERSATIONS ───────────────────────────────────────────
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        participant_id TEXT NOT NULL,
        participant_name TEXT NOT NULL,
        participant_age INTEGER,
        participant_region TEXT,
        last_message TEXT,
        last_message_at INTEGER,
        unread_count INTEGER DEFAULT 0
      )
    ''');

    // ── MESSAGES ────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        sender_name TEXT NOT NULL,
        body TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
      )
    ''');

    // ── CASES ───────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE cases (
        id TEXT PRIMARY KEY,
        ref_number TEXT UNIQUE,
        incident_type TEXT NOT NULL,
        incident_date TEXT NOT NULL,
        location_address TEXT NOT NULL,
        location_lat REAL,
        location_lng REAL,
        description TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'received',
        synced INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        evidence_urls TEXT
      )
    ''');

    // Seed communities on first create
    await _seedCommunities(db);

    // ── OFFLINE QUEUE ───────────────────────────────────────────
    await db.execute('''
      CREATE TABLE offline_queue (
        id TEXT PRIMARY KEY,
        endpoint TEXT NOT NULL,
        method TEXT NOT NULL,
        payload TEXT,
        created_at INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0,
        max_retries INTEGER DEFAULT 3,
        status TEXT DEFAULT 'PENDING'
      )
    ''');

    await db.execute('''
      CREATE TABLE safety_metrics_cache (
        user_id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // ── BOOKMARKS (Phase 15 Local Pinning) ─────────────────────
    await db.execute('''
      CREATE TABLE bookmarks (
        id TEXT PRIMARY KEY,
        post_json TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS offline_queue (
          id TEXT PRIMARY KEY,
          endpoint TEXT NOT NULL,
          method TEXT NOT NULL,
          payload TEXT,
          created_at INTEGER NOT NULL,
          retry_count INTEGER DEFAULT 0,
          max_retries INTEGER DEFAULT 3,
          status TEXT DEFAULT 'PENDING'
        )
      ''');
    }

    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cases (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          community TEXT NOT NULL,
          category TEXT NOT NULL,
          description TEXT NOT NULL,
          evidence TEXT,
          status TEXT NOT NULL DEFAULT 'pending',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          synced INTEGER DEFAULT 0,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 7) {
      await db
          .execute(
              'ALTER TABLE offline_queue ADD COLUMN max_retries INTEGER DEFAULT 3')
          .catchError((_) {});
      await db.execute('''
        CREATE TABLE IF NOT EXISTS safety_metrics_cache (
          user_id TEXT PRIMARY KEY,
          payload TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
    }

    if (oldVersion < 11) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS bookmarks (
          id TEXT PRIMARY KEY,
          post_json TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''').catchError((_) {});
    }
  }

  // ── COMMUNITIES SEED DATA ───────────────────────────────────

  static Future<void> _seedCommunities(Database db) async {
    final communities = [
      {
        'id': 'gauteng_johannesburg_alexandra',
        'name': 'Alexandra',
        'province': 'Gauteng',
        'center_lat': -26.0613,
        'center_lng': 28.0656,
        'radius_km': 2.5,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'id': 'gauteng_johannesburg_soweto',
        'name': 'Soweto',
        'province': 'Gauteng',
        'center_lat': -26.2704,
        'center_lng': 27.8479,
        'radius_km': 5.0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
    ];

    for (final community in communities) {
      await db.insert(
        'communities',
        community,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // ── RESET ───────────────────────────────────────────────────

  static Future<void> reset() async {
    final database = await db;
    await database.delete('users');
    await database.delete('emergency_contacts');
    await database.delete('sos_events');
    await database.delete('posts');
    await database.delete('replies');
    await database.delete('conversations');
    await database.delete('messages');
    await database.delete('cases');
    await database.delete('community_alerts');
    await database.delete('bookmarks');
  }

  static Future<void> resetForFreshUser() async {
    await reset();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('has_account');
    await prefs.remove('user_pin');
    await prefs.remove('user_phone');
    await prefs.remove('current_user_id');
    await prefs.remove('seen_onboarding');
    await prefs.remove('seen_language');
  }

  // ── USERS ───────────────────────────────────────────────────

  static Future<void> insertUser(Map<String, dynamic> user) async {
    final database = await db;
    await database.insert('users', user,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> getUser(String userId) async {
    final database = await db;
    final result =
        await database.query('users', where: 'id = ?', whereArgs: [userId]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    final database = await db;
    final result = await database
        .query('users', where: 'phone_number = ?', whereArgs: [phone]);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<void> updateUser(
      String userId, Map<String, dynamic> updates) async {
    final database = await db;
    await database.update(
      'users',
      {...updates, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ── EMERGENCY CONTACTS ──────────────────────────────────────

  static Future<void> insertEmergencyContact(
      Map<String, dynamic> contact) async {
    final database = await db;
    await database.insert('emergency_contacts', contact,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getEmergencyContacts(
      String userId) async {
    final database = await db;
    return database
        .query('emergency_contacts', where: 'user_id = ?', whereArgs: [userId]);
  }

  static Future<void> deleteEmergencyContact(String contactId) async {
    final database = await db;
    await database
        .delete('emergency_contacts', where: 'id = ?', whereArgs: [contactId]);
  }

  // ── SOS EVENTS ──────────────────────────────────────────────

  static Future<void> insertSosEvent(Map<String, dynamic> event) async {
    final database = await db;
    await database.insert('sos_events', event,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateSosEvent(
      String eventId, Map<String, dynamic> updates) async {
    final database = await db;
    await database
        .update('sos_events', updates, where: 'id = ?', whereArgs: [eventId]);
  }

  static Future<Map<String, dynamic>?> getSosEvent(String eventId) async {
    final database = await db;
    final result = await database
        .query('sos_events', where: 'id = ?', whereArgs: [eventId]);
    return result.isNotEmpty ? result.first : null;
  }

  // ── POSTS ───────────────────────────────────────────────────

  static Future<void> insertPost(Map<String, dynamic> post) async {
    final database = await db;
    await database.insert('posts', post,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getPosts() async {
    final database = await db;
    return database.query('posts', orderBy: 'created_at DESC');
  }

  static Future<void> deletePost(String id) async {
    final database = await db;
    await database.delete('posts', where: 'id = ?', whereArgs: [id]);
  }

  // ── BOOKMARKS ───────────────────────────────────────────────

  static Future<void> insertBookmark(String id, String json) async {
    final database = await db;
    await database.insert(
      'bookmarks',
      {
        'id': id,
        'post_json': json,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteBookmark(String id) async {
    final database = await db;
    await database.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getBookmarks() async {
    final database = await db;
    return database.query('bookmarks', orderBy: 'created_at DESC');
  }

  static Future<bool> isBookmarked(String id) async {
    final database = await db;
    final res =
        await database.query('bookmarks', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty;
  }

  // ── CONVERSATIONS & MESSAGES ────────────────────────────────

  static Future<void> upsertConversation(
      Map<String, dynamic> conversation) async {
    final database = await db;
    await database.insert('conversations', conversation,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getConversations() async {
    final database = await db;
    return database.query('conversations', orderBy: 'last_message_at DESC');
  }

  static Future<void> insertMessage(Map<String, dynamic> message) async {
    final database = await db;
    await database.insert('messages', message,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getMessages(
      String conversationId) async {
    final database = await db;
    return database.query('messages',
        where: 'conversation_id = ?',
        whereArgs: [conversationId],
        orderBy: 'created_at ASC');
  }

  // ── CASES ───────────────────────────────────────────────────

  static Future<void> insertCase(Map<String, dynamic> caseData) async {
    final database = await db;
    await database.insert('cases', caseData,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getCases() async {
    final database = await db;
    return database.query('cases', orderBy: 'created_at DESC');
  }

  static Future<void> updateCase(
      String caseId, Map<String, dynamic> updates) async {
    final database = await db;
    await database
        .update('cases', updates, where: 'id = ?', whereArgs: [caseId]);
  }

  // ── METRICS ─────────────────────────────────────────────────

  static Future<void> saveSafetyMetrics(String userId, String payload) async {
    final database = await db;
    await database.insert(
      'safety_metrics_cache',
      {
        'user_id': userId,
        'payload': payload,
        'updated_at': DateTime.now().millisecondsSinceEpoch
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> getSafetyMetrics(String userId) async {
    final database = await db;
    final result = await database.query('safety_metrics_cache',
        where: 'user_id = ?', whereArgs: [userId]);
    return result.isNotEmpty ? result.first['payload'] as String : null;
  }

  // ── COMMUNITIES ─────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAllCommunities() async {
    final database = await db;
    return database.query('communities', orderBy: 'name');
  }

  // ── REPLIES ─────────────────────────────────────────────────

  static Future<void> insertReply(Map<String, dynamic> reply) async {
    final database = await db;
    await database.insert('replies', reply,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getReplies(String postId) async {
    final database = await db;
    return database.query('replies',
        where: 'post_id = ?', whereArgs: [postId], orderBy: 'created_at ASC');
  }

  // ── HELPERS ─────────────────────────────────────────────────

  Future<void> wipeDatabase() async {
    final database = await LocalDb.db;
    final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'");
    for (final table in tables) {
      await database.delete(table['name'] as String);
    }
    await _seedCommunities(database);
  }
}
