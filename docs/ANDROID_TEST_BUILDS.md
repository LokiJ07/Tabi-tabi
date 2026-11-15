# Android test APK

This experimental ARM64 Android APK is built on the feature branch using GitHub Actions. It is not an approved gameplay release.

Debug keys are generated fresh for each CI run. Therefore, builds from different runs cannot update one another without uninstalling. Release/update signing must use a stable private key stored securely in GitHub Actions secrets, not in this repository.

The APK contains a temporary 3D and UI prototype only. Installation, controls, graphics, and sustained device performance must be validated on a real Android phone before any G1/G6 sign-off.
