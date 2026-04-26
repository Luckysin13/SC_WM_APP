---
description: launch the smoker mobile app web preview
---
1. Ensure the project is built for web
// turbo
2. Run the preview in the background
cd smoker_mobile_app && flutter run -d chrome -t lib/main_preview.dart --web-renderer canvaskit
3. Wait for the server to start (check logs)
4. Use the browser tool to navigate to the provided localhost URL
