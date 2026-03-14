#!/usr/bin/env python3
"""Patch Make.py to use bazelArguments in build command."""
import sys

path = "build-system/Make/Make.py"
if len(sys.argv) > 1:
    path = sys.argv[1]

with open(path) as f:
    content = f.read()

if "if self.additional_args is not None:" in content:
    print("Make.py already patched")
    sys.exit(0)

old1 = """        return combined_arguments

    def get_additional_build_arguments(self):
        combined_arguments = []
        if self.split_submodules:
            combined_arguments += [
                # https://github.com/bazelbuild/rules_swift
                # If enabled and whole module optimisation is being used, the `*.swiftdoc`,
                # `*.swiftmodule` and `*-Swift.h` are generated with a separate action
                # rather than as part of the compilation.
                '--features=swift.split_derived_files_generation',
            ]

        return combined_arguments"""

new1 = """        return combined_arguments

    def get_additional_build_arguments(self):
        combined_arguments = []
        if self.split_submodules:
            combined_arguments += [
                # https://github.com/bazelbuild/rules_swift
                # If enabled and whole module optimisation is being used, the `*.swiftdoc`,
                # `*.swiftmodule` and `*-Swift.h` are generated with a separate action
                # rather than as part of the compilation.
                '--features=swift.split_derived_files_generation',
            ]

        if self.additional_args is not None:
            combined_arguments += self.additional_args

        return combined_arguments"""

old2 = "    bazel_command_line.set_split_swiftmodules(arguments.enableParallelSwiftmoduleGeneration)\n\n    bazel_command_line.invoke_build()"
new2 = "    bazel_command_line.set_split_swiftmodules(arguments.enableParallelSwiftmoduleGeneration)\n\n    if arguments.bazelArguments is not None:\n        bazel_command_line.add_additional_args(shlex.split(arguments.bazelArguments))\n\n    bazel_command_line.invoke_build()"

content = content.replace(old1, new1).replace(old2, new2)
with open(path, "w") as f:
    f.write(content)
print("Make.py patched OK")
