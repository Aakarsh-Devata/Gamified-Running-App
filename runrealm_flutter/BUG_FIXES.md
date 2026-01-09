# Bug Fixes Applied

## Issues Fixed

### 1. ✅ History Tab Crash (FIXED)
**Error**: `type '_Map<String,dynamic>' is not a subtype of type 'Map<String,double>'`

**Root Cause**: The Run model expected path coordinates as `Map<String, double>` but they were being saved as dynamic values.

**Fix**: 
- Modified `Run.fromMap()` in [social.dart](file:///Users/aakarsh/Downloads/flutter_app_copy/runrealm_flutter/lib/models/social.dart) to properly convert path coordinates to doubles
- Updated path saving in [run_tracker.dart](file:///Users/aakarsh/Downloads/flutter_app_copy/runrealm_flutter/lib/widgets/run_tracker.dart) to explicitly cast to doubles

### 2. ✅ Profile Not Updating (SHOULD BE FIXED)
**Issue**: Profile shows 0 runs even though runs exist in Firebase

**Root Cause**: Same as #1 - the run deserialization was failing silently, so runs weren't being loaded.

**Fix**: Same fix as #1 should resolve this.

### 3. ⚠️ Territory API Not Working on Phone (NEEDS CONFIGURATION)
**Issue**: Area not calculated, no database entries

**Root Cause**: Phone can't reach `localhost:8080` - that only works on the same device.

**Solution**: Update the API URL in `TerritoryService` with your computer's local IP.

---

## To Enable Territory API on Your Phone

1. **Find your computer's IP address:**
   - Mac/Linux: Run `ifconfig | grep "inet "`
   - Windows: Run `ipconfig`
   - Look for something like `192.168.1.x` or `10.0.x.x`

2. **Update the code:**
   Open `lib/services/territory_service.dart` and change line 10:
   ```dart
   // FROM:
   static const String baseUrl = 'http://localhost:8080';
   
   // TO (replace with YOUR computer's IP):
   static const String baseUrl = 'http://192.168.1.X:8080';
   ```

3. **Make sure both devices are on the same WiFi network**

4. **Restart the app** after making the change

---

## Alternative: Test on Chrome/Emulator Instead

The territory API works perfectly on Chrome or emulator (they can reach localhost).

For now, you can:
1. **Test the fixes on your phone** (history and profile should work now)
2. **Test territory API on Chrome** to verify the full pipeline works

---

## Verification Steps

**On your phone (after hot restart):**
1. Go to History tab - should NOT crash anymore ✅
2. Go to Profile tab - should show your runs ✅  
3. Save a new run - territory will fail (expected, unless you configure IP)

**On Chrome (for full testing):**
1. Run: `flutter run -d chrome`
2. Complete a run and save
3. Should see: "🎉 Territory created! Area: X sq meters"
4. Check API logs for successful territory creation
5. Check PostgreSQL for the entry
