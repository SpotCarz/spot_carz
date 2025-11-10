# Fix Kotlin Build Cache Error

This error is caused by corrupted Kotlin incremental compilation caches. Follow these steps:

## Quick Fix (Recommended)

1. **Stop Gradle daemon:**
   ```bash
   cd android
   ./gradlew --stop
   ```

2. **Clean Flutter build:**
   ```bash
   flutter clean
   ```

3. **Delete build folders manually:**
   - Delete `build/` folder in project root
   - Delete `android/.gradle/` folder
   - Delete `android/app/build/` folder

4. **Rebuild:**
   ```bash
   flutter pub get
   flutter run
   ```

## Alternative: Delete Specific Cache

If the above doesn't work, delete the specific corrupted cache:

1. Navigate to: `build/shared_preferences_android/kotlin/compileDebugKotlin/cacheable/caches-jvm/`

2. Delete the entire `caches-jvm` folder

3. Rebuild the project

## Windows PowerShell Commands

```powershell
# Navigate to project
cd "E:\Mobile Projects\spot_carz"

# Stop Gradle
cd android
.\gradlew.bat --stop
cd ..

# Clean Flutter
flutter clean

# Delete build folders
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force android\.gradle -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force android\app\build -ErrorAction SilentlyContinue

# Rebuild
flutter pub get
flutter run
```

## If Still Failing

1. Close Android Studio/VS Code
2. Delete `.idea/` folder (if using IntelliJ/Android Studio)
3. Delete `.dart_tool/` folder
4. Restart your IDE
5. Run `flutter pub get` again

