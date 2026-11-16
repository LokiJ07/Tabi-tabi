# Rolling Night 1 debug prerelease delivery

Since in-chat sandbox file links have been unreliable for Android download, the Android workflow attempts to publish the validated APK as a rolling GitHub prerelease.

Stable download URL (only after a successful release job):
https://github.com/LokiJ07/Tabi-tabi/releases/download/night1-dev/tabi-tabi-night1-debug.apk

This is NOT a final release: device testing, performance, and accessibility remain pending. Each CI run currently uses a fresh temporary debug signing key, so installing over a previous build may fail. A production update channel requires a stable privately stored keystore and sensible version codes.

The workflow runs story, equipment, and settings regression tests before export/publication. GitHub Actions contents-write permissions are necessary; if repository policy disallows them, prerelease delivery will fail independently of APK export.
