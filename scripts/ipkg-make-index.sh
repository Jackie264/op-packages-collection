#!/usr/bin/env bash
set -e

pkg_dir=$1

if [ -z "$pkg_dir" ] || [ ! -d "$pkg_dir" ]; then
    echo "Usage: ipkg-make-index <package_directory>" >&2
    exit 1
fi

empty=1

for pkg in $(find "$pkg_dir" -maxdepth 1 -name '*.ipk' | sort); do
    empty=
    name="${pkg##*/}"
    name="${name%%_*}"
    [[ "$name" = "kernel" ]] && continue
    [[ "$name" = "libc" ]] && continue

    echo "Generating index for package $pkg" >&2

    file_size=$(stat -L -c%s "$pkg")
    sha256sum=$(sha256sum "$pkg" | cut -d' ' -f1)
    filename=$(basename "$pkg")

    if ar t "$pkg" | grep -q "control.tar.gz"; then
        ar p "$pkg" control.tar.gz | tar -xzO ./control
    elif ar t "$pkg" | grep -q "control.tar.xz"; then
        ar p "$pkg" control.tar.xz | tar -xJO ./control
    else
        echo "Warning: no control.tar.gz or control.tar.xz in $pkg" >&2
        continue
    fi | sed -e "s/^Description:/Filename: $filename\\
Size: $file_size\\
SHA256sum: $sha256sum\\
Description:/"

    echo ""
done

[ -n "$empty" ] && echo
exit 0
