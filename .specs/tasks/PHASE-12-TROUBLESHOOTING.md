# Phase 12: Troubleshooting & Common Issues

**Purpose:** Quick reference for resolving Phase 12 related issues  
**Last Updated:** May 19, 2026

---

## Issue: Flutter Build Takes Too Long (Gradle Task Stuck)

**Symptoms:**
- `flutter run` shows "Running Gradle task 'assembleDebug'..." for 30+ minutes
- No error messages, just spinning indicator

**Root Causes:**
1. First build of Flutter app (slow - expected)
2. Gradle downloading dependencies
3. Emulator not fully booted when build started
4. Insufficient system resources

**Solutions:**

**Solution 1: Wait it out (recommended first time)**
```bash
# First build is always slower
# Expected time: 15-30 minutes for initial build
# Subsequent builds will be 2-5 minutes
```

**Solution 2: Check emulator status**
```bash
# Verify emulator is actually running
adb devices
# Expected: emulator-5554   device

# If not running, start it:
emulator -avd Pixel6_API34 -no-window &
sleep 20
```

**Solution 3: Kill and restart build**
```bash
# Kill the hanging build process
pkill -f "flutter run"
pkill -f "gradle"

# Clean build files
cd ~/Documents/havenly/mobile
flutter clean
flutter pub get

# Try again with more verbose output
flutter run -d emulator-5554 --debug -v 2>&1 | tee build.log

# Monitor progress in another terminal:
tail -f build.log
```

**Solution 4: Check disk space**
```bash
# Flutter builds require ~2-3GB disk space
df -h /home/BigBossOffice

# If < 1GB available:
# Clean gradle cache
rm -rf ~/.gradle/caches

# Clean flutter cache
flutter clean
rm -rf build/ .dart_tool/
```

**Solution 5: Low system resources**
```bash
# Check available RAM
free -h

# If < 2GB available:
# Close other applications
# Consider increasing emulator RAM:
# Edit ~/.android/avd/Pixel6_API34/config.ini
# Change: hw.ram.size = 3072 (MB)
```

---

## Issue: Kotlin Version Warning

**Symptoms:**
```
Warning: Flutter support for your project's Kotlin version (1.9.0) will 
soon be dropped. Please upgrade your Kotlin version to a version of at 
least 2.1.0 soon.
```

**Severity:** ⚠️ WARNING (non-blocking, build succeeds)

**Solution:**

Update Kotlin version in build.gradle:
```gradle
// android/app/build.gradle
ext.kotlin_version = '2.1.0'
```

Or in settings.gradle:
```gradle
// android/settings.gradle
plugins {
    id 'org.jetbrains.kotlin.android' version '2.1.0' apply false
}
```

Then rebuild:
```bash
flutter clean
flutter run -d emulator-5554 --debug
```

---

## Issue: App Won't Build - TypeScript/Compilation Errors

**Symptoms:**
- Build fails with TS2322, TS2561 errors
- `npm run build` fails in backend

**Common Causes:**

### Cause 1: AuditLog Field Names Wrong

**Error:**
```
src/routes/mobile/emergency-contacts.ts(100,9): error TS2561: 
Object literal may only specify known properties, but 'userId' 
does not exist in type
```

**Root Cause:** Using old field names (userId, details, resourceId)

**Fix:**
```typescript
// WRONG:
await prisma.auditLog.create({
  data: {
    userId: req.user!.userId,         // ❌ Wrong
    details: "Contact created",        // ❌ Wrong
  }
});

// CORRECT:
await prisma.auditLog.create({
  data: {
    performedBy: req.user!.userId,    // ✅ Correct
    description: "Contact created",   // ✅ Correct
    action: "EMERGENCY_CONTACT_CREATED",
    module: "MOBILE",
  }
});
```

### Cause 2: Phone Validation Type Mismatch

**Error:**
```
Type 'string | string[]' is not assignable to type 'string | StringFilter'
```

**Root Cause:** Zod validation returns array of strings on multiple phone formats

**Fix:**
```typescript
// WRONG:
const phone = validated.phone;  // Could be string or string[]

// CORRECT:
const phone = Array.isArray(validated.phone)
  ? validated.phone[0]
  : validated.phone;
```

**Resolution:**
```bash
# After fixing code, rebuild:
npm run build

# Verify no errors:
# Output: "Copied 6 templates to dist/"
```

---

## Issue: Mobile App Crashes on Launch

**Symptoms:**
- App launches then immediately crashes
- Emulator shows crash dialog
- adb logcat shows Dart exceptions

**Troubleshooting:**

### Check Dart Errors
```bash
# Stream logs from app
adb logcat | grep -i "exception\|error\|flutter"

# Expected: Should see "Flutter Engine" messages, not exceptions
```

### Common Crash #1: ApiService Configuration Missing

**Error in logcat:**
```
E/flutter: Unhandled Exception: MissingPluginException(No implementation found)
```

**Cause:** API_BASE_URL not provided

**Fix:**
```bash
# Rebuild with environment variable
flutter run -d emulator-5554 --debug \
  --dart-define=API_BASE_URL=http://10.0.2.2:5000
```

### Common Crash #2: LocalDb Initialization Failed

**Error in logcat:**
```
E/flutter: Unhandled Exception: DatabaseException
```

**Cause:** SQLite database corrupted

**Fix:**
```bash
# Clear app data
adb shell pm clear com.havenly.mobile

# Reinstall app
flutter run -d emulator-5554 --debug
```

### Common Crash #3: Import Not Found

**Error in logcat:**
```
E/flutter: Unhandled Exception: NoSuchMethodError: 'package:havenly_mobile/...'
```

**Cause:** Missing import in screen file

**Fix:**
```dart
// EditProfileScreen.dart - ensure imports:
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../services/local_db.dart';
```

---

## Issue: API Calls Fail (401, 422, 500 Errors)

### Error 401: Unauthorized

**Symptoms:**
- SnackBar shows "Unauthorized"
- API returns 401

**Causes & Fixes:**

```bash
# 1. Token expired
# Solution: User needs to login again

# 2. Token not being sent
# Check: Is header correct?
# Headers should include:
# Authorization: Bearer {token}

# 3. Invalid token format
# Verify token is valid JWT
echo $TOKEN | jq -R 'split(".") | .[1] | @base64d | fromjson'
```

**Fix in Code:**
```dart
// EditProfileScreen - ensure token passed
final response = await ApiService().put(
  '/api/mobile/profile',
  data: {...},
  // ApiService should automatically add Authorization header
);

// Check ApiService:
// lib/services/api_service.dart should have:
dio.options.headers['Authorization'] = 'Bearer $token';
```

### Error 422: Validation Failed

**Symptoms:**
- SnackBar shows validation error
- Response has `issues` array

**Common Validation Failures:**

```bash
# Phone validation
# Valid: 0821234567, +27821234567
# Invalid: 123, +441234567890, 27821234567 (missing 0 or +)

# Name validation
# Valid: "John Doe" (min 2 chars)
# Invalid: "A" (too short)

# Relationship validation
# Valid: "Mother", "Spouse", "Friend" (2-100 chars)
# Invalid: "X" (too short)
```

**Fix:**
```dart
// EditProfileScreen - add validation
TextFormField(
  validator: (value) {
    if (value == null || value.isEmpty) return "Required";
    if (value.length < 2) return "Min 2 characters";
    return null;
  },
);
```

### Error 500: Internal Server Error

**Symptoms:**
- SnackBar shows "Error: Internal Server Error"
- Response: `{ error: "Internal server error" }`

**Troubleshooting:**

```bash
# 1. Check backend logs
ssh user@backend-server
journalctl -u havenly-backend -f

# 2. Check database connectivity
psql $DATABASE_URL -c "SELECT 1"

# 3. Check Redis connectivity
redis-cli ping

# 4. Check Sentry for detailed error
# Visit: https://sentry.io/projects/havenly
# Filter by latest error
```

**Common Backend Issues:**

```typescript
// Database connection error
const user = await prisma.user.findUnique(...);
// Fix: Check DATABASE_URL, ensure migrations run

// Phone normalization failing
const normalized = phone.replace(/^0/, '+27');
// Fix: Ensure regex correct

// Rate limit exceeded
// Fix: Increase limit or implement backoff
```

---

## Issue: LocalDb Not Syncing

**Symptoms:**
- Changes made in app not persisting
- After restart, old data shown
- Or: New data from API not appearing in list

**Troubleshooting:**

### Check LocalDb Exists
```bash
# Connect to emulator shell
adb shell

# Navigate to app data
cd /data/data/com.havenly.mobile/databases/

# List tables
sqlite3 local.db
sqlite> .tables
# Should show: users, emergency_contacts, etc.
```

### Check Data in LocalDb
```bash
# Query users
sqlite3 /data/data/com.havenly.mobile/databases/local.db \
  "SELECT * FROM users LIMIT 1;"

# Query contacts
sqlite3 /data/data/com.havenly.mobile/databases/local.db \
  "SELECT * FROM emergency_contacts LIMIT 5;"
```

### Fix Sync Issues

**Issue 1: updateUser() not called**
```dart
// WRONG:
final response = await ApiService().put(...);
// Don't update LocalDb - data not persisted!

// CORRECT:
final response = await ApiService().put(...);
if (response['data'] != null) {
  await LocalDb.updateUser({...});  // ✅ Persist to LocalDb
}
```

**Issue 2: Field name mismatch**
```dart
// WRONG:
'phone_number': response['phone'],  // Field names wrong!

// CORRECT:
'phone_number': response['data']['phone'],  // Correct path
```

**Issue 3: Timestamp format wrong**
```dart
// WRONG:
'created_at': response['createdAt'],  // ISO string, need milliseconds

// CORRECT:
'created_at': DateTime.parse(response['createdAt'])
  .millisecondsSinceEpoch,
```

---

## Issue: Phone Number Not Normalizing

**Symptoms:**
- User enters `0821234567`
- Displayed as `0821234567` (not `+27821234567`)
- Or: Backend shows +27 but UI doesn't

**Troubleshooting:**

### Frontend Issue
```dart
// Check EditProfileScreen display
Text(user.phoneNumber)
// If showing 0XXXXXXXXX, not normalized on display

// Fix: Display normalized version
Text(user.phoneNumber.replaceAll(RegExp(r'^0'), '+27'))
```

### Backend Issue
```typescript
// Check profile.ts normalization
const normalized = phone.replace(/^0/, '+27');
// If not normalizing, update won't persist

// Verify storage
const user = await prisma.user.update({
  where: { id: userId },
  data: { phone: normalized },  // ✅ Store normalized
});
```

### Database Issue
```bash
# Check stored value
psql $DATABASE_URL -c "SELECT phone FROM users LIMIT 1;"
# Expected: +27XXXXXXXXX
# If showing: 0XXXXXXXXX, backend not normalizing
```

---

## Issue: Navigation Not Working

**Symptoms:**
- "Edit Profile" button doesn't navigate
- Emergency Contacts link does nothing
- Or: Page appears to navigate but no screen shows

**Troubleshooting:**

### Check Routes Registered
```dart
// lib/app/routes.dart - verify routes defined
static const editProfile = '/edit_profile';
static const emergencyContacts = '/emergency_contacts';

// routes map should have entries:
editProfile: (_) => const EditProfileScreen(),
emergencyContacts: (_) => const EmergencyContactsScreen(),
```

### Check Navigation Code
```dart
// ProfileScreen - verify navigation call
ElevatedButton(
  onPressed: () => Navigator.pushNamed(context, AppRoutes.editProfile),
  // ✅ Correct
)

// NOT:
onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
// ❌ Wrong route name
```

### Check Imports
```dart
// Verify screen imported in routes.dart
import 'package:havenly_mobile/features/profile/edit_profile_screen.dart';
// If missing, route won't resolve
```

---

## Issue: Rate Limiting (429 Too Many Requests)

**Symptoms:**
- Rapid successive API calls fail with 429
- Header shows: X-RateLimit-Remaining: 0

**Solution:**

**Implement backoff:**
```dart
// ApiService - add retry with exponential backoff
Future<dynamic> post(String endpoint, {required Map data}) async {
  int attempts = 0;
  const maxAttempts = 3;
  Duration delay = Duration(milliseconds: 100);
  
  while (attempts < maxAttempts) {
    try {
      return await dio.post(endpoint, data: data);
    } catch (e) {
      if (e.response?.statusCode == 429) {
        attempts++;
        await Future.delayed(delay);
        delay *= 2;  // Exponential backoff
      } else {
        rethrow;
      }
    }
  }
}
```

**Or: Batch operations:**
```dart
// Instead of:
for (contact in contacts) {
  await API.post(...);  // 429 if > 100 calls/min
}

// Do:
final List<Future> operations = contacts
  .map((c) => API.post(...))
  .toList();
await Future.wait(operations, eagerError: false);
```

---

## Issue: Sentry Not Logging Errors

**Symptoms:**
- Errors occur but not showing in Sentry dashboard
- Or: Sentry dashboard empty

**Troubleshooting:**

### Check Sentry Configuration
```bash
# Verify SENTRY_DSN set
echo $SENTRY_DSN

# Should show: https://xxxx@sentry.io/xxxx
```

### Check Manual Error Logging
```typescript
// In backend route handlers
import * as Sentry from '@sentry/node';

try {
  // operation
} catch (error) {
  Sentry.captureException(error, {
    tags: { route: 'mobile/profile', action: 'PUT' }
  });
}
```

### Test Sentry
```bash
# Backend: Trigger error and check Sentry
curl -X POST http://localhost:5000/api/mobile/profile \
  -H "Authorization: Bearer invalid_token"

# Should appear in Sentry within 30 seconds
```

---

## Issue: Emulator Won't Start

**Symptoms:**
- `emulator -avd Pixel6_API34` hangs
- Or: `adb devices` shows offline

**Solutions:**

```bash
# Solution 1: Kill existing process and restart
pkill -f emulator
pkill -f qemu

# Wait 5 seconds
sleep 5

# Start fresh
emulator -avd Pixel6_API34 -no-window &
sleep 20

adb devices
# Expected: emulator-5554   device
```

```bash
# Solution 2: Reset emulator
emulator -avd Pixel6_API34 -wipe-data

# Solution 3: Recreate AVD
android delete avd -n Pixel6_API34
android create avd -n Pixel6_API34 -k "system-images;android-34;google_apis;x86_64"
emulator -avd Pixel6_API34 -no-window &
```

---

## Debugging Quick Commands

```bash
# Stream app logs
adb logcat | grep -i flutter

# Get app crash logs
adb logcat --clear
# Trigger crash
adb logcat | grep -A 20 "Exception"

# SQLite query from emulator
adb shell "sqlite3 /data/data/com.havenly.mobile/databases/local.db \
  'SELECT sql FROM sqlite_master WHERE type=\"table\";'"

# Network logs (install http_proxy_client for logging)
adb logcat | grep -i "http\|network\|dio"

# Database logs from backend
tail -f /var/log/havenly-backend.log

# Real-time Sentry errors
curl https://sentry.io/api/0/projects/havenly/latest-events/ \
  -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" | jq '.[] | {timestamp, title}'
```

---

## Deployment Checklist

Before deploying Phase 12 to production:

- [ ] All tests passing locally
- [ ] Gradle build completes successfully
- [ ] No Kotlin version warnings (optional but recommended)
- [ ] No TypeScript compilation errors
- [ ] Emulator testing verified all features
- [ ] Database migrations applied
- [ ] Backend environment variables set
- [ ] Sentry monitoring enabled
- [ ] Rate limiting configured
- [ ] CORS properly configured
- [ ] JWT secret strong and stored securely
- [ ] Phone normalization working end-to-end
- [ ] Audit logs recording correctly

---

## Contact Support

**For Phase 12 Issues:**

1. **Quick Fix:** Check this document first
2. **Code Issues:** Review /specs/tasks/PHASE-12-HANDOFF.md
3. **API Reference:** Check /specs/tasks/PHASE-12-MOBILE-API-HANDOFF.md
4. **Backend Logs:** `journalctl -u havenly-backend -f`
5. **Sentry:** https://sentry.io/projects/havenly
6. **Database:** Direct query via psql

