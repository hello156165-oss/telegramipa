#!/usr/bin/env python3
"""
Patches telegram-src/build-system/Make/ProjectGeneration.py to propagate
disableProvisioningProfiles and disableExtensions to Bazel invocations.
Must be run from the repo root (parent of telegram-src).
"""
from pathlib import Path

p = Path("telegram-src/build-system/Make/ProjectGeneration.py")
s = p.read_text(encoding="utf-8")
original = s

marker1 = "        bazel_generate_arguments += ['--//{}:disableStripping'.format(app_target)]"
if marker1 in s and "disableProvisioningProfiles" not in s:
    s = s.replace(
        marker1,
        marker1
        + "\n        if disable_provisioning_profiles:\n"
        + "            bazel_generate_arguments += ['--//{}:disableProvisioningProfiles'.format(app_target)]",
    )
    print("patch 1 applied (generate args)")
else:
    print("patch 1 skipped")

marker2 = "        project_bazel_arguments += ['--//{}:disableStripping'.format(app_target)]"
if marker2 in s and "disableProvisioningProfiles'.format(app_target)]" not in s:
    s = s.replace(
        marker2,
        marker2
        + "\n        if disable_provisioning_profiles:\n"
        + "            project_bazel_arguments += ['--//{}:disableProvisioningProfiles'.format(app_target)]",
    )
    print("patch 2 applied (project args)")
else:
    print("patch 2 skipped")

if s != original:
    p.write_text(s, encoding="utf-8")
    print("ProjectGeneration.py patched.")
else:
    print("ProjectGeneration.py: no changes needed.")
