#!/usr/bin/env bats

setup() {
  export HOME="$(mktemp -d)"
  mkdir -p "$HOME/.local/share/icons" "$HOME/.local/share/nemo/actions" "$HOME/.local/share/nemo-git-integration"

  cp -r ./icons/* "$HOME/.local/share/icons/"
  cp -r ./nemo/actions/* "$HOME/.local/share/nemo/actions/"
  cp -r ./nemo-git-integration/* "$HOME/.local/share/nemo-git-integration/"

  # Prepare a dummy backup file to simulate prior install
  mkdir -p "$HOME/.config/nemo/actions"
  echo '{"backup":"data"}' > "$HOME/.config/nemo/actions/actions-tree-bkup.json"
  echo '{"modified":"data"}' > "$HOME/.config/nemo/actions/actions-tree.json"

  cp ./install.sh ./uninstall.sh
  chmod +x ./install.sh ./uninstall.sh
}

teardown() {
  rm -rf "$HOME"
}

@test "uninstall.sh restores backup layout" {
  run ./install.sh
  [ "$status" -eq 0 ]
  [ -f "$HOME/.config/nemo/actions/actions-tree-bkup.json" ]

  # Overwrite layout to simulate change
  echo '{"changed":true}' > "$HOME/.config/nemo/actions/actions-tree.json"

  run ./uninstall.sh
  [ "$status" -eq 0 ]

  diff "$HOME/.config/nemo/actions/actions-tree.json" "$HOME/.config/nemo/actions/actions-tree-bkup.json"
}

@test "uninstall.sh removes installed files" {
  run ./install.sh
  [ "$status" -eq 0 ]

  run ./uninstall.sh
  [ "$status" -eq 0 ]

  # Icons removed
  for icon in ./icons/*; do
    [ ! -f "$HOME/.local/share/icons/$(basename "$icon")" ]
  done

  # Nemo actions removed
  for action in ./nemo/actions/*; do
    [ ! -f "$HOME/.local/share/nemo/actions/$(basename "$action")" ]
  done

  # Git integration removed
  [ ! -d "$HOME/.local/share/nemo-git-integration" ]
}
