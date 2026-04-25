#!/usr/bin/env python3
"""
Re-signs an IPA with minimal entitlements for TrollStore installation.

Removes entitlements that cause issues on TrollStore:
  - com.apple.security.application-groups (shared container doesn't exist → app hangs)
  - aps-environment (push notifications, not needed for TrollStore)

Usage: python3 resign_trollstore.py <input.ipa> <output.ipa> <team_id> <bundle_id>
"""
import subprocess
import sys
import os
import shutil
import tempfile
import zipfile
import plistlib
from pathlib import Path


def run(cmd, **kwargs):
    print("+", " ".join(str(c) for c in cmd))
    subprocess.check_call(cmd, **kwargs)


def main():
    input_ipa, output_ipa, team_id, bundle_id = sys.argv[1:5]

    work = tempfile.mkdtemp(prefix="trollstore_resign_")
    try:
        # Unpack IPA
        print(f"Unpacking {input_ipa} …")
        with zipfile.ZipFile(input_ipa) as z:
            z.extractall(work)

        payload = Path(work) / "Payload"
        apps = list(payload.glob("*.app"))
        if not apps:
            print("ERROR: no .app found in Payload", file=sys.stderr)
            sys.exit(1)
        app = apps[0]
        print(f"App bundle: {app.name}")

        # Remove embedded provisioning profile
        (app / "embedded.mobileprovision").unlink(missing_ok=True)

        # Write minimal entitlements plist
        ent_path = Path(work) / "trollstore.entitlements"
        ent = {
            "application-identifier": f"{team_id}.{bundle_id}",
            "com.apple.developer.team-identifier": team_id,
            "get-task-allow": False,
            "keychain-access-groups": [f"{team_id}.{bundle_id}"],
        }
        ent_path.write_bytes(plistlib.dumps(ent))
        print(f"Entitlements: {ent}")

        # Re-sign frameworks and dylibs (ad-hoc, no entitlements)
        for item in sorted(app.rglob("*.framework")):
            if item.is_dir():
                run(["codesign", "-f", "-s", "-", str(item)])
        for item in sorted(app.rglob("*.dylib")):
            if item.is_file():
                run(["codesign", "-f", "-s", "-", str(item)])

        # Re-sign the main executable and the .app bundle
        main_exe = app / app.stem
        if main_exe.exists():
            run(["codesign", "-f", "-s", "-", "--entitlements", str(ent_path), str(main_exe)])
        run(["codesign", "-f", "-s", "-", "--entitlements", str(ent_path), str(app)])

        # Verify
        result = subprocess.run(
            ["codesign", "-d", "--entitlements", "-", str(app)],
            capture_output=True, text=True
        )
        print("Entitlements in signed bundle:")
        print(result.stdout or result.stderr)

        # Repack IPA
        print(f"Repacking → {output_ipa} …")
        with zipfile.ZipFile(output_ipa, "w", zipfile.ZIP_DEFLATED) as z:
            for f in sorted(Path(work).rglob("*")):
                if f.is_file():
                    z.write(f, f.relative_to(work))
        size_mb = Path(output_ipa).stat().st_size / 1_048_576
        print(f"Done. Output: {output_ipa} ({size_mb:.1f} MB)")

    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    main()
