#!/usr/bin/env bash

REPO_URL="https://github.com/Antire-AS/antire-public-dotfiles.git"

INCLUDE_ITEMS=(
  ".gitignore"
  ".ruff.toml"
  "pyrightconfig.json"
  "pytest.ini"
  ".coveragerc"
)

tmp=$(mktemp -d)
overwrite_all=false

git clone --depth=1 "$REPO_URL" "$tmp"

shopt -s nullglob

for name in "${INCLUDE_ITEMS[@]}"; do
  item="$tmp/$name"

  if [ -e "./$name" ] && [ "$overwrite_all" = false ]; then
    while true; do
      read -rp \
        "File '$name' already exists.
[y] overwrite this file
[n] skip this file
[a] overwrite this file and ALL remaining dotfiles from antire-public-dotfiles
Choose [y/n/a]: " answer

      case "$answer" in
      y | Y)
        break
        ;;
      n | N)
        continue 2
        ;;
      a | A)
        overwrite_all=true
        break
        ;;
      *)
        echo "Please enter y, n, or a."
        ;;
      esac
    done
  fi

  cp -r "$item" .
done

rm -rf "$tmp"

echo "Done."
