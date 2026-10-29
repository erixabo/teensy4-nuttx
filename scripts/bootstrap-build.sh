#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work_dir="${1:-$HOME/teensy4-nuttx-build}"
nuttx_rev="8caba095575dfa0c47fd6ca4b974dd5e69798535"
apps_rev="0c56297b043157fccee9a56b2af06aa4c49d1ed0"
gopher_url="https://github.com/erixabo/teensy-nuttx-gopher.git"

if [[ -e "$work_dir" ]]; then
  echo "A célkönyvtár már létezik: $work_dir" >&2
  echo "Válassz új, üres célkönyvtárat; a szkript nem töröl meglévő adatot." >&2
  exit 2
fi

mkdir -p "$work_dir"
git clone https://github.com/apache/nuttx.git "$work_dir/nuttx"
git -C "$work_dir/nuttx" checkout "$nuttx_rev"
git clone https://github.com/apache/nuttx-apps.git "$work_dir/apps"
git -C "$work_dir/apps" checkout "$apps_rev"
git -C "$work_dir/nuttx" apply "$repo_dir/patches/nuttx-local.patch"
git -C "$work_dir/apps" apply "$repo_dir/patches/apps-local.patch"

git clone "$gopher_url" "$work_dir/gopher-client"
mkdir -p "$work_dir/apps/netutils/gopher"
git -C "$work_dir/gopher-client" archive HEAD | tar -x -C "$work_dir/apps/netutils/gopher"

cd "$work_dir/nuttx"
./tools/configure.sh teensy-4.x:netnsh-4.1
make -j"$(nproc)"
echo "Build kész: $work_dir/nuttx/nuttx.hex"
