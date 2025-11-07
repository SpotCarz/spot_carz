@echo off
echo Generating app icons from App_logo.png...
flutter pub get
dart run flutter_launcher_icons
echo.
echo Icons generated successfully!
echo Please rebuild your app to see the new icon.
pause

