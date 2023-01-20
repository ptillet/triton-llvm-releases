
import os.path
import re
import sys

def _extract_ver(text, ver_str, default):
    r = re.compile('set\\(' + ver_str + ' (\\d+)\\)')
    m = r.search(text)
    if m:
        return m.group(1)
    else:
        return default

def get_llvm_version(path):
    major_ver, minor_ver, patch_ver = "x", "x", "x"

    with open(path, 'r') as f:
        lines = f.read()
        major_ver = _extract_ver(lines, "LLVM_VERSION_MAJOR", "x")
        minor_ver = _extract_ver(lines, "LLVM_VERSION_MINOR", "x")
        patch_ver = _extract_ver(lines, "LLVM_VERSION_PATCH", "x")

    if all([ver != "x" for ver in [major_ver, minor_ver, patch_ver]]):
        return f"{major_ver}.{minor_ver}.{patch_ver}"
    else:
        print(f"{major_ver}.{minor_ver}.{patch_ver}")
        print("Error: Failed to extract an LLVM version from CMakeLists.txt")
        exit(-1)


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Error: Invalid arguments")
        print("Usage: python3 get_llvm_version.py <path to llvm-project/llvm/CMakeLists.txt>")
        exit(-1)

    path = sys.argv[1]
    if not os.path.exists(path):
        print(f"Error: File `{path}` is not found")
        exit(-1)

    print(get_llvm_version(path))
