# Phase 12: Profile Setup & Emergency Contacts - Mobile Handoff

**Status:** ✅ Complete  
**Date:** 2024  
**Phase:** 12 of Mobile Roadmap  
**Artifacts:** EditProfileScreen, EmergencyContactsScreen, integrated with LocalDb + ApiService

---

## Overview

Phase 12 implements two core mobile features for user profile management:
1. **Edit Profile Screen** - Users can update personal details (name, phone, email, province, community)
2. **Emergency Contacts Screen** - Users can manage emergency contacts with full CRUD operations

Both screens integrate seamlessly with the new `/api/mobile/` backend endpoints and persist data locally via SQLite.

---

## File Structure

```
lib/features/profile/
├── edit_profile_screen.dart       (297 lines) - Profile editing interface
├── emergency_contacts_screen.dart (329 lines) - Contact management interface
└── profile_screen.dart             (646 lines) - Main profile display
```

---

## Implementation Details

### 1. EditProfileScreen

**Location:** [lib/features/profile/edit_profile_screen.dart](lib/features/profile/edit_profile_screen.dart)

**Purpose:** Allow authenticated users to edit their profile name, phone, email, province, and community.

**Key Features:**
- Form validation with TextFormField validators
- Phone number normalization (accepts `0XXXXXXXXX` or `+27XXXXXXXXX`)
- Real-time error feedback via SnackBar
- Updates local database (LocalDb) after successful API call
- Calls UserProvider.bootSession() to refresh app state

**API Integration:**
```dart
// PUT request to backend endpoint
final response = await ApiService().put(
  '/api/mobile/profile',
  data: {
    'fullName': _nameController.text,
    'phone': _phoneController.text,
    'email': _emailController.text,
    'province': _province,
    'community': _community,
  },
);

// Response format: { data: { id, name, email, phone, ... } }
if (response['data'] != null) {
  await LocalDb.updateUser({
    'id': response['data']['id'],
    'full_name': response['data']['name'],
    'phone_number': response['data']['phone'],
    'email': response['data']['email'],
    'province': response['data']['province'],
    'community': response['data']['community'],
  });
  // Trigger app state refresh
  userProvider.bootSession();
}
```

**Fields Supported:**
| Field | Type | Validation | Notes |
|-------|------|-----------|-------|
| fullName | String | Min 2 chars | Required |
| phone | String | SA format (10 digits) | Normalized at backend |
| email | String | Valid email | Optional |
| province | String | Enum | Optional |
| community | String | Text | Optional |

---

### 2. EmergencyContactsScreen

**Location:** [lib/features/profile/emergency_contacts_screen.dart](lib/features/profile/emergency_contacts_screen.dart)

**Purpose:** Display, create, edit, and delete emergency contacts that will receive SOS alerts.

**Key Features:**
- List view with all contacts ordered by creation date
- Add contact via modal form with validation
- Edit contact with pre-filled data
- Delete contact with confirmation dialog
- Phone normalization for all contacts
- Automatic LocalDb synchronization

**API Integration:**

#### GET all contacts
```dart
final response = await ApiService().get('/api/mobile/emergency-contacts');
// Response: { data: [{ id, name, phone, relationship, createdAt }, ...] }
for (final contact in response['data']) {
  await LocalDb.insertEmergencyContact({
    'id': contact['id'],
    'user_id': user.id,
    'name': contact['name'],
    'phone_number': contact['phone'],        // Field mapping: phone → phone_number
    'relationship': contact['relationship'],
    'created_at': DateTime.parse(contact['createdAt']).millisecondsSinceEpoch,
  });
}
```

#### POST new contact
```dart
final response = await ApiService().post(
  '/api/mobile/emergency-contacts',
  data: {
    'name': nameController.text,
    'phone': phoneController.text,           // Field name: phone (not phoneNumber)
    'relationship': relationship,
  },
);
// Response: { data: { id, name, phone, relationship, createdAt, ... } }
```

#### PUT update contact
```dart
final response = await ApiService().put(
  '/api/mobile/emergency-contacts/$contactId',
  data: {
    'name': updatedName,
    'phone': updatedPhone,
    'relationship': updatedRelationship,
  },
);
```

#### DELETE contact
```dart
await ApiService().delete('/api/mobile/emergency-contacts/$contactId');
```

**Validation Schema:**
| Field | Min | Max | Pattern |
|-------|-----|-----|---------|
| name | 2 | 255 | Text |
| phone | 10 | 13 | SA format |
| relationship | 2 | 100 | Text (spouse, sibling, friend, etc.) |

**Contact Model (Local):**
```dart
{
  'id': String,
  'user_id': String,
  'name': String,
  'phone_number': String,        // Stored as full phone with country code
  'relationship': String,
  'created_at': int,             // Milliseconds since epoch
}
```

---

## Navigation Integration

**Routes Defined:** [lib/app/routes.dart](lib/app/routes.dart)
```dart
static const editProfile = '/edit_profile';
static const emergencyContacts = '/emergency_contacts';

// From ProfileScreen
Navigator.pushNamed(context, AppRoutes.editProfile);
Navigator.pushNamed(context, AppRoutes.emergencyContacts);
```

**Button Integration:**
- ProfileScreen has "Edit Profile" button → EditProfileScreen
- ProfileScreen shows "X Contacts" → EmergencyContactsScreen
- EmergencyContactsScreen has "+ Add Contact" FAB → Modal form

---

## API Response Envelope

All mobile API endpoints use consistent response format:

**Success Response:**
```json
{
  "data": {
    "id": "...",
    "name": "...",
    "phone": "+27...",
    "email": "...",
    "createdAt": "2024-01-15T10:30:00Z",
    ...
  }
}
```

**List Response:**
```json
{
  "data": [
    { "id": "...", "name": "...", ... },
    { "id": "...", "name": "...", ... }
  ]
}
```

**Error Response:**
```json
{
  "error": "Validation failed",
  "issues": [
    { "path": ["phone"], "message": "Invalid SA phone number" }
  ]
}
```

---

## Database Synchronization

### LocalDb Methods Used

```dart
// Update authenticated user profile
LocalDb.updateUser({
  'id': userId,
  'full_name': name,
  'phone_number': phone,
  'email': email,
  'province': province,
  'community': community,
});

// Insert emergency contact
LocalDb.insertEmergencyContact({
  'id': contactId,
  'user_id': userId,
  'name': name,
  'phone_number': phone,
  'relationship': relationship,
  'created_at': timestamp,
});

// Delete emergency contact
LocalDb.deleteEmergencyContact(contactId);
```

### Offline Behavior

- **Reads** are served from LocalDb if API fails
- **Writes** are queued by ApiService.post/put/delete and retried when online
- **Sync** occurs automatically on app launch via UserProvider.bootSession()

---

## Error Handling

All screens implement standard error handling:

```dart
try {
  final response = await ApiService().post(endpoint, data: payload);
  // Handle success
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Error: $e"))
  );
}
```

**Common Error Codes:**
- `401 Unauthorized` - Token expired, user logged out
- `422 Unprocessable Entity` - Validation failed, check `issues` field
- `500 Internal Server Error` - Backend error, retry later

---

## Phone Number Handling

**Frontend:** Accepts both formats
- `0XXXXXXXXX` (South African domestic)
- `+27XXXXXXXXX` (international)

**Backend Normalization:** All phones stored as `+27XXXXXXXXX`

**LocalDb Storage:** Phones stored in normalized format for consistency

---

## Testing Checklist

- [ ] **EditProfileScreen**
  - [ ] Load screen, verify pre-populated values
  - [ ] Update name only, verify saves
  - [ ] Update phone (test both 0 and +27 formats)
  - [ ] Update email and province
  - [ ] Verify LocalDb reflects changes
  - [ ] Test validation (empty name, invalid phone, etc.)
  - [ ] Test error scenarios (network down, server error)

- [ ] **EmergencyContactsScreen**
  - [ ] Load screen, verify contacts displayed
  - [ ] Add new contact with valid data
  - [ ] Verify contact appears in list
  - [ ] Edit existing contact
  - [ ] Delete contact with confirmation
  - [ ] Test validation (2-char name min, phone format)
  - [ ] Test offline behavior
  - [ ] Verify LocalDb synced after each operation

- [ ] **Integration Tests**
  - [ ] Edit profile → verify ProfileScreen refreshes
  - [ ] Add contact → verify appears in list immediately
  - [ ] Navigate back/forth without data loss
  - [ ] App background/foreground → verify state persists

---

## Known Issues & Limitations

1. **Age/Gender/Race Fields Removed**: Old profile schema included these but v2 focuses on essentials
   - Backend removed: age, gender, race, title, suburb
   - Frontend: EditProfileScreen only shows: name, phone, email, province, community

2. **Phone Format Validation**: Restricted to South African numbers (10 digits, starts with 0 or +27)
   - International numbers not supported in current phase

3. **Batch Operations**: Not implemented - contacts must be added/edited individually
   - No bulk import/export in this phase

4. **Contact Groups**: Not supported - all contacts treated equally for SOS notifications
   - Future phase may add priorities/groups

---

## Backend Endpoints Reference

**Profile Endpoints:**
- `GET /api/mobile/profile` - Get current user profile
- `PUT /api/mobile/profile` - Update profile fields

**Emergency Contacts Endpoints:**
- `GET /api/mobile/emergency-contacts` - List all contacts
- `GET /api/mobile/emergency-contacts/:id` - Get single contact
- `POST /api/mobile/emergency-contacts` - Create contact
- `PUT /api/mobile/emergency-contacts/:id` - Update contact
- `DELETE /api/mobile/emergency-contacts/:id` - Delete contact

All endpoints require Bearer token authentication.

---

## Next Phase (Phase 13)

**Recommended Work:**
1. **SOS Alert Broadcasting** - Notify emergency contacts when user triggers SOS
2. **Contact Acknowledgment** - Track which contacts have seen/acknowledged alerts
3. **Alert History** - Show past SOS alerts with delivery status
4. **Fallback Contacts** - Add secondary contacts if primary doesn't respond

**Prerequisites for Phase 13:**
- [ ] Twilio/SMS API integration confirmed
- [ ] Push notification service configured
- [ ] Real-time messaging infrastructure ready

---

## Developer Notes

**ApiService Integration:**
- GET, POST, PUT, DELETE methods automatically append Bearer token
- Responses passed as raw JSON (not wrapped)
- Errors automatically logged to console and Sentry

**UserProvider Pattern:**
- `userProvider.bootSession()` refreshes entire user state
- Call after profile updates to sync app-wide changes
- Rebuilds all Consumer<UserProvider> widgets

**LocalDb Consistency:**
- Always sync LocalDb after successful API response
- Use same field names as database schema
- Timestamps stored as milliseconds since epoch

**Reduced Motion:**
- All animations check `MediaQuery.of(context).disableAnimations`
- Modal transitions respect user accessibility preferences

---

## Deployment Checklist

- [ ] Flutter analyze runs without errors
- [ ] Backend TypeScript compiles successfully
- [ ] All API endpoints tested in Postman/Insomnia
- [ ] Emulator testing passed (ProfileScreen → EditProfileScreen → back)
- [ ] Emulator testing passed (ProfileScreen → EmergencyContactsScreen → add/edit/delete)
- [ ] LocalDb entries created/updated/deleted correctly
- [ ] Network error handling verified
- [ ] Validation errors display correctly
- [ ] App builds for Android APK release
- [ ] Sentry events logged on errors

---

## Environment Configuration

**Mobile (.dart file):**
```dart
// lib/core/config/env.dart
static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
// Usage: flutter run --dart-define=API_BASE_URL=https://api.havenly.dev
```

**Backend (.env file):**
```
CORS_ALLOWED_ORIGINS=https://app.havenly.dev,https://localhost:3000
DATABASE_URL=postgresql://...
JWT_SECRET=...
REDIS_URL=...
```

---

## Support & Questions

**Emergency Contacts Behavior:**
- Q: Can users add themselves as emergency contact?
  - A: No validation prevents it - frontend should add check

- Q: What happens if contact phone is invalid format?
  - A: Backend validation returns 422 with field-specific error

- Q: Can users have duplicate contacts?
  - A: Yes - backend allows, UI shows all without deduplication

**Profile Updates:**
- Q: Does editing profile trigger SOS contacts notification?
  - A: No - only SOS alerts notify contacts, not profile changes

- Q: Are old profile values kept in audit log?
  - A: Yes - AuditLog.metadata stores before/after values

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024 | Initial implementation of EditProfileScreen and EmergencyContactsScreen |
| - | - | Integrated with /api/mobile/ endpoints |
| - | - | LocalDb synchronization implemented |
| - | - | Navigation wiring complete |

