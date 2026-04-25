#!/usr/bin/env python3
"""
Patches telegram-src/build-system/Make/Make.py for unsigned TrollStore CI builds.
Must be run from the repo root (parent of telegram-src).
"""
from pathlib import Path
import sys

p = Path("telegram-src/build-system/Make/Make.py")
s = p.read_text(encoding="utf-8")
original = s

# ── 1) Allow --bazelArguments placed after the subcommand ─────────────────────
# argparse only accepts global flags BEFORE the subcommand, so we normalise argv.
if "Normalize argv" not in s and "args = parser.parse_args()" in s:
    s = s.replace(
        "args = parser.parse_args()",
        "# Normalize argv: move --bazelArguments before the subcommand\n"
        "    import re as _re\n"
        "    _ba_pat = _re.compile(r'(--bazelArguments(?:=\\S+|\\s+\\S+)?)')\n"
        "    _argv = sys.argv[1:]\n"
        "    _ba_args = _ba_pat.findall(' '.join(_argv))\n"
        "    if _ba_args:\n"
        "        _argv = _ba_pat.sub('', ' '.join(_argv)).split()\n"
        "        _argv = [a for a in _ba_args] + _argv\n"
        "        sys.argv = [sys.argv[0]] + _argv\n"
        "    args = parser.parse_args()",
    )
    print("patch 1 applied (bazelArguments normalisation)")
else:
    print("patch 1 skipped")

# ── 2) Ensure additional_args are forwarded to bazel build ────────────────────
needle2 = (
    "        combined_arguments += self.get_additional_build_arguments()\n"
    "\n"
    "        if self.additional_args is not None:\n"
    "            combined_arguments += self.additional_args\n"
)
replacement2 = (
    "        combined_arguments += self.get_additional_build_arguments()\n"
    "\n"
    "        if self.additional_args is not None:\n"
    "            combined_arguments += self.additional_args\n"
)
if needle2 not in s:
    # Try alternate form where add_additional_args is missing
    alt = (
        "        combined_arguments += self.get_additional_build_arguments()\n"
    )
    if alt in s and "self.additional_args" not in s:
        s = s.replace(
            alt,
            alt
            + "\n        if self.additional_args is not None:\n"
            + "            combined_arguments += self.additional_args\n",
        )
        print("patch 2 applied (additional_args forwarding)")
    else:
        print("patch 2 skipped")
else:
    print("patch 2 skipped (already present)")

# ── 3) Skip aps-environment check when provisioning is disabled ───────────────
needle3 = (
    "    if codesigning_data.aps_environment is None:\n"
    "        print('Could not find a valid aps-environment entitlement in the provided provisioning profiles')\n"
    "        sys.exit(1)\n"
)
if needle3 in s:
    s = s.replace(
        needle3,
        "    if codesigning_data.aps_environment is None:\n"
        "        _dis = getattr(arguments, 'disableProvisioningProfiles', False)\n"
        "        if getattr(arguments, 'bazelArguments', None):\n"
        "            _dis = _dis or ('--//Telegram:disableProvisioningProfiles' in str(arguments.bazelArguments))\n"
        "        if _dis:\n"
        "            codesigning_data.aps_environment = ''\n"
        "        else:\n"
        "            print('Could not find a valid aps-environment entitlement in the provided provisioning profiles')\n"
        "            sys.exit(1)\n",
    )
    print("patch 3 applied (aps-environment bypass)")
else:
    print("patch 3 skipped")

# ── 4) Create placeholder .mobileprovision files when provisioning disabled ───
needle4 = (
    "    provisioning_profile_files = []\n"
    "    for file_name in os.listdir(provisioning_path):\n"
    "        if file_name.endswith('.mobileprovision'):\n"
    "            provisioning_profile_files.append(file_name)\n"
)
if needle4 in s and "PLACEHOLDER_PROFILES" not in s:
    s = s.replace(
        needle4,
        needle4
        + "\n    # PLACEHOLDER_PROFILES\n"
        + "    _dis_prov = getattr(arguments, 'disableProvisioningProfiles', False)\n"
        + "    if getattr(arguments, 'bazelArguments', None):\n"
        + "        _dis_prov = _dis_prov or ('--//Telegram:disableProvisioningProfiles' in str(arguments.bazelArguments))\n"
        + "    if _dis_prov:\n"
        + "        for _name in ['Telegram.mobileprovision','Share.mobileprovision',\n"
        + "                      'NotificationContent.mobileprovision','Widget.mobileprovision',\n"
        + "                      'Intents.mobileprovision','BroadcastUpload.mobileprovision',\n"
        + "                      'NotificationService.mobileprovision']:\n"
        + "            _path = provisioning_path + '/' + _name\n"
        + "            if not os.path.exists(_path):\n"
        + "                open(_path, 'wb').close()\n"
        + "                provisioning_profile_files.append(_name)\n",
    )
    print("patch 4 applied (placeholder profiles)")
else:
    print("patch 4 skipped")

if s != original:
    p.write_text(s, encoding="utf-8")
    print(f"Make.py patched.")
else:
    print("Make.py: no changes needed.")
