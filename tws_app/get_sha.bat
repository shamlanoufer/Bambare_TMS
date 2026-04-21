@echo off
echo Getting SHA-1 and SHA-256 for Firebase...
echo.
cd android
call gradlew signingReport
echo.
echo Copy the SHA-1 and SHA-256 from above, then add them in:
echo Firebase Console - Project Settings - Your apps - Android - Add fingerprint
pause
