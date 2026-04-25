#!/usr/bin/env python3
"""
Creates a fake .mobileprovision for TrollStore/unsigned IPA builds.
Must be run from inside the telegram-src directory.
"""
import json
import plistlib
import subprocess
import sys
from datetime import datetime

cfg = json.load(open("build-config.json"))
team_id = cfg["team_id"]
bundle_id = cfg["bundle_id"]

p12_path = "build-system/fake-codesigning/certs/SelfSigned.p12"
pem_path = "/tmp/selfsigned.pem"
der_path = "/tmp/selfsigned.der"
plist_path = "/tmp/profile.plist"
out_path = "build-system/fake-codesigning/profiles/Telegram.mobileprovision"

# Extract PEM from p12 (try modern openssl, then legacy)
extracted = False
for extra in [[], ["-legacy"]]:
    r = subprocess.run(
        ["openssl", "pkcs12", "-in", p12_path, "-nodes", "-passin", "pass:"]
        + extra
        + ["-out", pem_path],
        capture_output=True,
    )
    if r.returncode == 0:
        extracted = True
        print("p12 extracted" + (" (legacy)" if extra else ""))
        break

if not extracted:
    print("ERROR: could not extract p12", file=sys.stderr)
    sys.exit(1)

# Extract DER cert bytes
subprocess.check_call(
    ["openssl", "x509", "-in", pem_path, "-outform", "DER", "-out", der_path]
)
cert_der = open(der_path, "rb").read()
print(f"Certificate DER: {len(cert_der)} bytes")

# Build the profile dict — plistlib serialises bytes as <data> automatically
profile = {
    "AppIDName": "Telegram Fake",
    "ApplicationIdentifierPrefix": [team_id],
    "TeamIdentifier": [team_id],
    "TeamName": "Fake Team",
    "CreationDate": datetime(2026, 1, 1),
    "ExpirationDate": datetime(2036, 1, 1),
    "TimeToLive": 3650,
    "Name": "Telegram Fake Profile",
    "Platform": ["iOS"],
    "UUID": "00000000-0000-0000-0000-000000000000",
    "Version": 1,
    "DeveloperCertificates": [cert_der],
    "Entitlements": {
        "application-identifier": f"{team_id}.{bundle_id}",
        "com.apple.developer.team-identifier": team_id,
        "get-task-allow": True,
        "aps-environment": "development",
        "com.apple.security.application-groups": [f"group.{bundle_id}"],
    },
}

plist_bytes = plistlib.dumps(profile, fmt=plistlib.FMT_XML)
open(plist_path, "wb").write(plist_bytes)
print("Plist written with DeveloperCertificates key.")

# Sign the plist as CMS/DER (.mobileprovision format)
subprocess.check_call(
    [
        "openssl", "smime", "-sign",
        "-in", plist_path,
        "-signer", pem_path,
        "-inkey", pem_path,
        "-outform", "der",
        "-nodetach", "-noattr",
        "-out", out_path,
    ]
)

# Quick sanity-check: decode it back and verify DeveloperCertificates is present
result = subprocess.run(
    ["openssl", "smime", "-inform", "der", "-verify", "-noverify", "-in", out_path],
    capture_output=True,
)
decoded = plistlib.loads(result.stdout)
assert "DeveloperCertificates" in decoded, "MISSING DeveloperCertificates in decoded profile!"
assert len(decoded["DeveloperCertificates"]) > 0, "DeveloperCertificates is empty!"
print(f"Profile OK — DeveloperCertificates present ({len(decoded['DeveloperCertificates'][0])} bytes)")
