# Firebase Service Account Permission Issue

## Problem
The Firebase service account `firebase-adminsdk-fbsvc@runrealm.iam.gserviceaccount.com` doesn't have permission to read from Firestore.

## Status
Permission changes can take 5-10 minutes to propagate. If you just updated the IAM permissions, please wait a few minutes and try again.

## Alternative: Manual Test (Available Now)
Use `test_with_real_run.js` to test with real data immediately:

1. Go to [Firebase Console - Firestore](https://console.firebase.google.com/project/runrealm/firestore)
2. Open the `runs` collection
3. Click on any run document
4. Copy the `path` array field  
5. Edit `test_with_real_run.js` and paste the path data
6. Run: `node test_with_real_run.js`

## Solution Options

### Option 1: Grant Firestore Permissions (Recommended)
In Google Cloud Console (https://console.cloud.google.com):
1. Go to **IAM & Admin** > **IAM**
2. Find the service account: `firebase-adminsdk-fbsvc@runrealm.iam.gserviceaccount.com`
3. Click **Edit** (pencil icon)
4. Add role: **Cloud Datastore User** or **Firebase Admin SDK Administrator Service Agent**
5. Save
6. **Wait 5-10 minutes** for changes to propagate

### Option 2: Regenerate Service Account Key
Sometimes a new key is needed after permission changes:
1. Go to **IAM & Admin** > **Service Accounts**
2. Find `firebase-adminsdk-fbsvc@runrealm.iam.gserviceaccount.com`
3. Click **Keys** tab
4. Add new key (JSON)
5. Update `.env` with the new key JSON

## Current Status
- ✅ Territory API endpoint working
- ✅ Firebase authentication working  
- ⏳ Service account Firestore permissions pending
