# Android CI performance improvement (Night 1)

The experimental `-gpu host` Android emulator job repeatedly occupied a GitHub runner for a long time while offering no reliable rendered 3D screenshot, blocking newer debug APK uploads because the rolling release workflow used one concurrency group.

The default push workflow now uses `cancel-in-progress: true` to prioritize the most recent branch head, preserves the successful standard emulator APK install/launch/screenshot checks, and omits the unreliable experimental host-GPU job. No rendering method in the actual Godot game has been changed, and known SwiftShader GLSL shader errors remain an emulator-specific blocker, not verified on the physical phone.

Any final graphics signoff still requires an actual phone/GPU playtest of the latest build, particularly with the additional painted NPC portraits.
