#!/usr/bin/env python3
"""Fail-closed static gate for stable Godot Android signing and publish workflow."""
from pathlib import Path
import subprocess

root=Path(__file__).resolve().parents[2]
preset=(root/"export_presets.cfg").read_text()
workflow=(root/".github/workflows/android-release.yml").read_text()
errors=[]
def check(ok, description):
    if not ok:
        errors.append(description)
        print("FAIL: "+description)
    else:
        print("PASS: "+description)

check('package/signed=true' in preset and 'package/unique_name="org.tabitabi.nightone"' in preset,
      "Stable package ID and signed Android export required for saved-data continuity")
check("--export-release Android" in workflow and "--export-debug" not in workflow,
      "Production pipeline uses true release export, never a debug APK")
check(all(f"secrets.{name}" in workflow for name in
          ["TABITABI_KEYSTORE_BASE64","TABITABI_KEYSTORE_PASSWORD","TABITABI_KEY_ALIAS"]),
      "All release credentials come ONLY from GitHub encrypted secrets")
check("GODOT_ANDROID_KEYSTORE_RELEASE_PATH" in workflow and
      "GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD" in workflow,
      "Godot receives permanent release keystore, not temporary debug signing")
check('package: name=\'org.tabitabi.nightone\'' in workflow and
      "application-debuggable" in workflow,
      "Manifest is checked for original package ID and absence of debuggable flag")
check("apksigner" in workflow and "SHA256SUMS.txt" in workflow,
      "Signature and release checksum are verified")
check("release-emulator:" in workflow and "needs: [build-release, release-emulator]" in workflow,
      "Publish is gated on installing this EXACT signed-release APK in Android emulator")
check('gh release create "$tag"' in workflow and "--prerelease" in workflow,
      "Signed APK is published as a versioned immutable GitHub Release")
check("github.ref == 'refs/heads/main'" in workflow,
      "Release only builds from tested main, not unmerged QA branches")
check("gh release view" in workflow and "never silently replace" in workflow,
      "Production APK signing/version cannot be silently overwritten")
result=subprocess.run(["git","ls-files","-z"],cwd=root,capture_output=True,check=True)
tracked=[x.decode(errors="replace") for x in result.stdout.split(b"\0") if x]
leaked=[f for f in tracked if f.lower().endswith((".jks",".keystore",".p12",".pfx",".p8"))]
check(not leaked,"Private signing keys are NEVER tracked in Git: "+",".join(leaked))
if errors:
    raise SystemExit(f"{len(errors)} release-readiness checks failed")
print("PASS: Release pipeline security and package compatibility gate")
