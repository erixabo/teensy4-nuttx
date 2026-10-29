#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work_dir="${1:-$HOME/teensy4-nuttx-build}"
nuttx_rev="8caba095575dfa0c47fd6ca4b974dd5e69798535"
apps_rev="0c56297b043157fccee9a56b2af06aa4c49d1ed0"
gopher_url="https://github.com/erixabo/teensy-nuttx-gopher.git"
gopher_rev="7a4a287a53727dbf41dd15a7043ed0ec1d455115"

if ! command -v arm-none-eabi-gcc >/dev/null 2>&1; then
  pio_toolchain="$HOME/.platformio/packages/toolchain-gccarmnoneeabi-teensy/bin"
  if [[ -x "$pio_toolchain/arm-none-eabi-gcc" ]]; then
    export PATH="$pio_toolchain:$PATH"
  else
    echo "ARM GCC nem található. Telepítsd az arm-none-eabi-gcc csomagot." >&2
    exit 127
  fi
fi

if [[ -e "$work_dir" ]]; then
  echo "A célkönyvtár már létezik: $work_dir" >&2
  echo "Válassz új, üres célkönyvtárat; a szkript nem töröl meglévő adatot." >&2
  exit 2
fi

mkdir -p "$work_dir"

fetch_revision() {
  local url="$1" destination="$2" revision="$3"
  mkdir -p "$destination"
  git -C "$destination" init -q
  git -C "$destination" remote add origin "$url"
  git -C "$destination" fetch --depth=1 origin "$revision"
  git -C "$destination" checkout --detach FETCH_HEAD
}

fetch_revision https://github.com/apache/nuttx.git "$work_dir/nuttx" "$nuttx_rev"
fetch_revision https://github.com/apache/nuttx-apps.git "$work_dir/apps" "$apps_rev"
git -C "$work_dir/nuttx" apply "$repo_dir/patches/nuttx-local.patch"
git -C "$work_dir/apps" apply "$repo_dir/patches/apps-local.patch"

fetch_revision "$gopher_url" "$work_dir/gopher-client" "$gopher_rev"
mkdir -p "$work_dir/apps/netutils/gopher"
git -C "$work_dir/gopher-client" archive HEAD | tar -x -C "$work_dir/apps/netutils/gopher"

cd "$work_dir/nuttx"
./tools/configure.sh teensy-4.x:netnsh-4.1
make -j"$(nproc)"
echo "Build kész: $work_dir/nuttx/nuttx.hex"
