# Phase 12: Complete Integration Testing Guide

**Purpose:** Verify all Phase 12 implementation works correctly end-to-end  
**Prerequisites:** APK built and app running on emulator  
**Estimated Time:** 15-20 minutes

---

## Pre-Test Verification

Before starting, verify:
- [ ] Emulator is running: `adb devices`
- [ ] App is installed: `adb shell pm list packages | grep havenly`
- [ ] Backend is running: `curl http://localhost:5000/health` returns 200
- [ ] Database is accessible: `psql $DATABASE_URL -c "SELECT 1"`

---

## Test Suite 1: Backend API Endpoints (Postman/curl)

### Setup
```bash
# Get authentication token
TOKEN=$(curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@havenly.dev",
    "password": "TestPassword123!"
  }' | jq -r '.data.accessToken')

echo "Using token: $TOKEN"
```

---

## Test 1.1: GET /api/mobile/profile

**Objective:** Retrieve authenticated user's profile

**Request:**
```bash
curl -X GET http://localhost:5000/api/mobile/profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

**Expected Response (200 OK):**
```json
{
  "data": {
    "id": "user_123",
    "name": "Test User",
    "email": "testuser@havenly.dev",
    "phone": "+27821234567",
    "avatar": null,
    "status": "ACTIVE",
    "department": "Community Lead",
    "province": "Gauteng",
    "community": "Test Community",
    "createdAt": "2024-01-15T10:30:00.000Z",
    "updatedAt": "2024-01-15T10:30:00.000Z"
  }
}
```

**Verification Checklist:**
- [ ] Status code is 200
- [ ] `data` object contains all fields
- [ ] No `error` field present
- [ ] Phone format is `+27XXXXXXXXX`
- [ ] Response time < 500ms

**Troubleshooting:**
- 401 Unauthorized: Token expired, regenerate with login
- 500 Internal Server Error: Check backend logs with `journalctl -u havenly-backend -f`

---

## Test 1.2: PUT /api/mobile/profile (Update Name)

**Objective:** Update user profile with new name

**Request:**
```bash
curl -X PUT http://localhost:5000/api/mobile/profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "Updated Test User"
  }'
```

**Expected Response (200 OK):**
```json
{
  "data": {
    "id": "user_123",
    "name": "Updated Test User",
    "email": "testuser@havenly.dev",
    "phone": "+27821234567",
    "updatedAt": "2024-01-15T11:30:00.000Z"
  }
}
```

**Verification Checklist:**
- [ ] Status code is 200
- [ ] Name changed to "Updated Test User"
- [ ] `updatedAt` is newer than previous
- [ ] Other fields unchanged
- [ ] Database reflects change: `psql -c "SELECT name FROM users WHERE id='user_123'"`

---

## Test 1.3: PUT /api/mobile/profile (Phone Normalization)

**Objective:** Test phone number normalization (0XXXXXXXXX → +27XXXXXXXXX)

**Request:**
```bash
curl -X PUT http://localhost:5000/api/mobile/profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "0829876543"
  }'
```

**Expected Response (200 OK):**
```json
{
  "data": {
    "phone": "+27829876543"
  }
}
```

**Verification Checklist:**
- [ ] Input `0829876543` normalized to `+27829876543`
- [ ] Stored format is `+27XXXXXXXXX`
- [ ] Database shows normalized value

**Additional Tests:**
```bash
# Test 1: +27 prefix already present (should remain unchanged)
curl -X PUT http://localhost:5000/api/mobile/profile \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"phone": "+27829876543"}'
# Expected: +27829876543

# Test 2: Invalid phone (should fail validation)
curl -X PUT http://localhost:5000/api/mobile/profile \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"phone": "123"}'
# Expected: 422 with validation error

# Test 3: Non-SA format (should fail)
curl -X PUT http://localhost:5000/api/mobile/profile \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"phone": "+441234567890"}'
# Expected: 422 validation error
```

---

## Test 1.4: POST /api/mobile/emergency-contacts (Create)

**Objective:** Create new emergency contact

**Request:**
```bash
curl -X POST http://localhost:5000/api/mobile/emergency-contacts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Mary Smith",
    "phone": "0829876543",
    "relationship": "Mother"
  }'
```

**Expected Response (201 Created):**
```json
{
  "data": {
    "id": "contact_001",
    "userId": "user_123",
    "name": "Mary Smith",
    "phone": "+27829876543",
    "relationship": "Mother",
    "createdAt": "2024-01-15T11:35:00.000Z"
  }
}
```

**Verification Checklist:**
- [ ] Status code is 201
- [ ] Contact ID generated
- [ ] Phone normalized to +27XXXXXXXXX
- [ ] `createdAt` timestamp present
- [ ] Database entry created: `psql -c "SELECT * FROM emergency_contacts WHERE id='contact_001'"`

**Save contact ID for next tests:**
```bash
CONTACT_ID=$(curl -s -X POST http://localhost:5000/api/mobile/emergency-contacts \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"Test","phone":"0821234567","relationship":"Friend"}' \
  | jq -r '.data.id')
echo "Contact ID: $CONTACT_ID"
```

---

## Test 1.5: GET /api/mobile/emergency-contacts (List All)

**Objective:** Retrieve all emergency contacts for user

**Request:**
```bash
curl -X GET http://localhost:5000/api/mobile/emergency-contacts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

**Expected Response (200 OK):**
```json
{
  "data": [
    {
      "id": "contact_001",
      "userId": "user_123",
      "name": "Mary Smith",
      "phone": "+27829876543",
      "relationship": "Mother",
      "createdAt": "2024-01-15T11:35:00.000Z"
    },
    {
      "id": "contact_002",
      "userId": "user_123",
      "name": "Tom Johnson",
      "phone": "+27832123456",
      "relationship": "Brother",
      "createdAt": "2024-01-15T11:36:00.000Z"
    }
  ]
}
```

**Verification Checklist:**
- [ ] Status code is 200
- [ ] Array contains at least 1 contact
- [ ] Only current user's contacts returned (not other users')
- [ ] All contacts ordered by `createdAt` descending (newest first)
- [ ] All phones normalized

---

## Test 1.6: GET /api/mobile/emergency-contacts/:id (Get Single)

**Objective:** Retrieve specific contact

**Request:**
```bash
curl -X GET http://localhost:5000/api/mobile/emergency-contacts/$CONTACT_ID \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response (200 OK):**
```json
{
  "data": {
    "id": "contact_001",
    "userId": "user_123",
    "name": "Mary Smith",
    "phone": "+27829876543",
    "relationship": "Mother",
    "createdAt": "2024-01-15T11:35:00.000Z"
  }
}
```

**Verification Checklist:**
- [ ] Status code is 200
- [ ] Single contact object returned (not array)
- [ ] Correct contact ID
- [ ] All fields present

**Security Test:**
```bash
# Try accessing another user's contact (should fail)
curl -X GET http://localhost:5000/api/mobile/emergency-contacts/contact_999 \
  -H "Authorization: Bearer $TOKEN"
# Expected: 403 Forbidden OR 404 Not Found
```

---

## Test 1.7: PUT /api/mobile/emergency-contacts/:id (Update)

**Objective:** Update existing contact

**Request:**
```bash
curl -X PUT http://localhost:5000/api/mobile/emergency-contacts/$CONTACT_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+27829999999",
    "relationship": "Sister-in-law"
  }'
```

**Expected Response (200 OK):**
```json
{
  "data": {
    "id": "contact_001",
    "userId": "user_123",
    "name": "Mary Smith",
    "phone": "+27829999999",
    "relationship": "Sister-in-law",
    "createdAt": "2024-01-15T11:35:00.000Z"
  }
}
```

**Verification Checklist:**
- [ ] Status code is 200
- [ ] Phone updated to new value
- [ ] Relationship updated
- [ ] Name unchanged (not provided)
- [ ] `createdAt` unchanged
- [ ] Database reflects changes

---

## Test 1.8: DELETE /api/mobile/emergency-contacts/:id

**Objective:** Delete emergency contact

**Request:**
```bash
curl -X DELETE http://localhost:5000/api/mobile/emergency-contacts/$CONTACT_ID \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response (200 OK):**
```json
{
  "data": {
    "id": "contact_001",
    "deleted": true
  }
}
```

**Verification Checklist:**
- [ ] Status code is 200
- [ ] `deleted` field is true
- [ ] Contact ID included
- [ ] Contact removed from database: `psql -c "SELECT * FROM emergency_contacts WHERE id='$CONTACT_ID'"`
- [ ] Subsequent GET returns 404

---

## Test Suite 2: Audit Logging

**Objective:** Verify all mutations are logged to AuditLog

**Query:**
```bash
psql $DATABASE_URL -c "
SELECT 
  id,
  action,
  performedBy,
  module,
  description,
  created_at
FROM audit_logs
WHERE module = 'MOBILE'
ORDER BY created_at DESC
LIMIT 20;
"
```

**Verification Checklist:**
- [ ] PROFILE_UPDATED action logged on PUT /api/mobile/profile
- [ ] EMERGENCY_CONTACT_CREATED logged on POST
- [ ] EMERGENCY_CONTACT_UPDATED logged on PUT
- [ ] EMERGENCY_CONTACT_DELETED logged on DELETE
- [ ] All have `performedBy` set to user ID
- [ ] All have module = 'MOBILE'
- [ ] All have `description` with human-readable text
- [ ] Timestamps are recent

---

## Test Suite 3: Mobile App UI (Emulator)

### Test 3.1: Profile Screen Initial Load

**Steps:**
1. Launch app
2. Navigate to Profile tab
3. Observe ProfileScreen displays

**Verification:**
- [ ] Profile screen loads without errors
- [ ] User name displayed
- [ ] User phone number displayed
- [ ] "Edit Profile" button visible
- [ ] Emergency contacts count displayed
- [ ] Security section shows proper status
- [ ] Personal details card displays fields

**Expected Screenshot:** Profile with mountain banner, user info, all sections visible

---

### Test 3.2: Edit Profile Screen - Open

**Steps:**
1. From ProfileScreen, tap "Edit Profile" button
2. Wait for EditProfileScreen to load

**Verification:**
- [ ] Screen navigates without errors
- [ ] Form fields pre-populated with current values
- [ ] fullName field shows user name
- [ ] phone field shows user phone
- [ ] email field shows user email
- [ ] province dropdown shows current value
- [ ] community field shows current value
- [ ] Cancel button available
- [ ] Save button available

---

### Test 3.3: Edit Profile - Update Name

**Steps:**
1. Clear fullName field
2. Enter new name (e.g., "Jane Doe Updated")
3. Tap "Save Profile"
4. Wait for response

**Verification:**
- [ ] Loading indicator appears
- [ ] No validation errors for valid input
- [ ] API call succeeds (check adb logcat for network logs)
- [ ] Screen closes after success
- [ ] ProfileScreen updated with new name
- [ ] SnackBar message shows success

**Logcat Command:**
```bash
adb logcat | grep -i "profile\|network\|api"
```

---

### Test 3.4: Edit Profile - Update Phone (Format 0XXXXXXXXX)

**Steps:**
1. From EditProfileScreen, clear phone field
2. Enter phone: `0825551234`
3. Tap "Save Profile"

**Verification:**
- [ ] No validation errors (0 format is valid)
- [ ] API accepts input
- [ ] Backend normalizes to +27XXXXXXXXX
- [ ] ProfileScreen shows updated phone with +27 prefix
- [ ] LocalDb stores normalized format

**Database Check:**
```bash
adb shell "sqlite3 /data/data/com.havenly.mobile/databases/local.db \
  'SELECT phone_number FROM users LIMIT 1;'"
# Expected output: +27825551234
```

---

### Test 3.5: Edit Profile - Update Phone (Format +27XXXXXXXXX)

**Steps:**
1. From EditProfileScreen, enter phone: `+27835551234`
2. Tap "Save Profile"

**Verification:**
- [ ] No validation errors
- [ ] API accepts input
- [ ] Backend stores as-is
- [ ] ProfileScreen shows +27 format

---

### Test 3.6: Edit Profile - Invalid Phone Rejection

**Steps:**
1. Enter invalid phone: `123` (too short)
2. Try to save

**Verification:**
- [ ] Validation error displayed below field
- [ ] Error message: "Phone must be valid SA number"
- [ ] Save button disabled OR prevents submission
- [ ] Form not submitted to API

---

### Test 3.7: Edit Profile - Update Province

**Steps:**
1. From EditProfileScreen, tap province dropdown
2. Select different province (e.g., "Western Cape")
3. Tap "Save Profile"

**Verification:**
- [ ] Dropdown opens
- [ ] All provinces selectable
- [ ] Selection persists on save
- [ ] ProfileScreen shows updated province

---

### Test 3.8: Emergency Contacts Screen - Open

**Steps:**
1. From ProfileScreen, tap "Emergency Contacts" or "X Contacts" link
2. Wait for EmergencyContactsScreen to load

**Verification:**
- [ ] Screen navigates without errors
- [ ] ListView displays all contacts
- [ ] Each contact shows name, phone, relationship
- [ ] Add button (FAB) visible
- [ ] Empty state message if no contacts

---

### Test 3.9: Add Emergency Contact

**Steps:**
1. From EmergencyContactsScreen, tap "+" FAB
2. Modal form opens
3. Enter: Name="John Doe", Phone="0821111111", Relationship="Friend"
4. Tap "Add Contact"

**Verification:**
- [ ] Modal opens without errors
- [ ] Form fields visible
- [ ] Relationship dropdown shows options: spouse, sibling, friend, parent, etc.
- [ ] Submit button labeled "Add Contact"
- [ ] After submit, contact appears in list
- [ ] List re-sorts by creation time
- [ ] Phone stored as +27821111111
- [ ] LocalDb entry created

---

### Test 3.10: Edit Emergency Contact

**Steps:**
1. Tap existing contact in list
2. Update form opens (or swipe to reveal edit button)
3. Change phone to `0822222222`
4. Tap "Update" or "Save"

**Verification:**
- [ ] Edit form pre-populated with contact data
- [ ] Changes submitted to API
- [ ] Contact updated in list
- [ ] Phone normalized
- [ ] LocalDb updated

---

### Test 3.11: Delete Emergency Contact

**Steps:**
1. Long-press or swipe contact
2. Delete option appears
3. Confirm delete

**Verification:**
- [ ] Confirmation dialog appears
- [ ] Dialog shows: "Remove Contact? They will no longer receive your SOS alerts."
- [ ] Cancel and Remove buttons
- [ ] On confirm, API DELETE called
- [ ] Contact removed from list
- [ ] LocalDb entry deleted
- [ ] No contacts displayed if list empty

---

### Test 3.12: Phone Number Normalization in UI

**Steps:**
1. Add contact with phone `0829876543`
2. Observe in list

**Verification:**
- [ ] List displays phone as `+27 82 987 6543` (formatted for display) OR `+27829876543`
- [ ] Backend stores as `+27829876543`
- [ ] If edited and re-opened, displays correctly

---

## Test Suite 4: Offline Behavior

**Objective:** Verify app works offline and queues requests

**Prerequisites:** Disconnect WiFi and disable mobile data

### Test 4.1: View Profile Offline

**Steps:**
1. Turn off all network connectivity
2. Open app
3. Navigate to ProfileScreen

**Verification:**
- [ ] Profile displays from LocalDb (cached data)
- [ ] No network errors shown
- [ ] Fields show last known values

---

### Test 4.2: Edit Profile Offline (Request Queueing)

**Steps:**
1. While offline, tap "Edit Profile"
2. Update name
3. Tap "Save"

**Verification:**
- [ ] Request shows as pending/queued in UI (optional indicator)
- [ ] SnackBar indicates: "Queued - will sync when online"
- [ ] Form remains editable
- [ ] LocalDb updated optimistically

**Continuation:**
4. Re-enable network
5. Wait 5-10 seconds

**Verification:**
- [ ] Request automatically retried
- [ ] API response received
- [ ] SnackBar confirms sync success

---

### Test 4.3: View Emergency Contacts Offline

**Steps:**
1. Offline, navigate to EmergencyContactsScreen
2. Observe list

**Verification:**
- [ ] All contacts display from LocalDb
- [ ] No network errors
- [ ] Data is stale (cached from last sync)

---

## Test Suite 5: Error Handling

### Test 5.1: Network Error During Profile Update

**Steps:**
1. Open EditProfileScreen
2. During form submission, disconnect network (turn off WiFi quickly)
3. Observe error handling

**Verification:**
- [ ] Network error caught
- [ ] SnackBar shows: "Error: Network error"
- [ ] User can retry
- [ ] Form state preserved

---

### Test 5.2: Validation Error From Backend

**Steps:**
1. Open EditProfileScreen
2. Manually craft invalid request (if possible via debugging)
3. OR: Use backend API with invalid data

**Verification:**
- [ ] Error response received (422)
- [ ] Validation errors displayed in UI
- [ ] Error message specific to field (e.g., "Invalid SA phone number")

---

### Test 5.3: Unauthorized Access (Expired Token)

**Steps:**
1. Open ProfileScreen
2. Wait for token to expire (set short expiry for testing) OR manually invalidate
3. Try to edit profile

**Verification:**
- [ ] 401 Unauthorized response received
- [ ] User redirected to login screen
- [ ] App logs out user
- [ ] Session cleared

---

## Test Suite 6: Database Verification

**Objective:** Verify all data persisted correctly

### Users Table
```bash
psql $DATABASE_URL -c "
SELECT id, name, phone, email, province, community, updated_at
FROM users
WHERE email = 'testuser@havenly.dev';
"
```

**Verification:**
- [ ] Name field matches last edited value
- [ ] Phone in +27 format
- [ ] email correct
- [ ] Updated timestamps are recent

### Emergency Contacts Table
```bash
psql $DATABASE_URL -c "
SELECT id, user_id, name, phone, relationship, created_at
FROM emergency_contacts
WHERE user_id = (SELECT id FROM users WHERE email = 'testuser@havenly.dev')
ORDER BY created_at DESC;
"
```

**Verification:**
- [ ] All created contacts present
- [ ] Phone numbers normalized
- [ ] User ID correct
- [ ] Deleted contacts removed from table
- [ ] Relationships accurate

### Audit Log Table
```bash
psql $DATABASE_URL -c "
SELECT action, performed_by, module, description, created_at
FROM audit_logs
WHERE module = 'MOBILE'
ORDER BY created_at DESC LIMIT 30;
"
```

**Verification:**
- [ ] All mutations logged
- [ ] Actions: PROFILE_UPDATED, EMERGENCY_CONTACT_CREATED/UPDATED/DELETED
- [ ] Module: MOBILE
- [ ] Description human-readable
- [ ] Timestamps chronological

---

## Test Results Summary

**Date:** ____________  
**Tester:** ____________

### Backend API
- [ ] GET /api/mobile/profile - PASS / FAIL
- [ ] PUT /api/mobile/profile - PASS / FAIL
- [ ] POST /api/mobile/emergency-contacts - PASS / FAIL
- [ ] GET /api/mobile/emergency-contacts - PASS / FAIL
- [ ] GET /api/mobile/emergency-contacts/:id - PASS / FAIL
- [ ] PUT /api/mobile/emergency-contacts/:id - PASS / FAIL
- [ ] DELETE /api/mobile/emergency-contacts/:id - PASS / FAIL

### Mobile App
- [ ] ProfileScreen loads - PASS / FAIL
- [ ] EditProfileScreen loads - PASS / FAIL
- [ ] Update name succeeds - PASS / FAIL
- [ ] Phone normalization works - PASS / FAIL
- [ ] EmergencyContactsScreen loads - PASS / FAIL
- [ ] Add contact succeeds - PASS / FAIL
- [ ] Edit contact succeeds - PASS / FAIL
- [ ] Delete contact succeeds - PASS / FAIL

### Database
- [ ] User profile updated - PASS / FAIL
- [ ] Contacts created - PASS / FAIL
- [ ] Audit logs recorded - PASS / FAIL

### Overall Result
- [ ] ALL TESTS PASSED ✅
- [ ] SOME TESTS FAILED ⚠️
- [ ] CRITICAL FAILURES ❌

**Issues Found:**
(List any bugs or issues discovered)

---

## Cleanup After Testing

```bash
# Stop emulator
adb emu kill

# Stop backend (if running locally)
pkill -f "npm start"

# Archive test logs
mkdir -p ~/test-results/phase-12
cp ~/logcat_*.txt ~/test-results/phase-12/ 2>/dev/null
```

---

## Sign-Off

**Testing Complete:** _____________  
**Tested By:** _____________  
**Backend Status:** ✅ VERIFIED  
**Mobile Status:** ✅ VERIFIED (pending runtime test)  
**Ready for Production:** YES / NO

