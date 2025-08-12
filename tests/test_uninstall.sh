#!/usr/bin/env bats

# Path to scripts (adjust if in a different location)
INSTALL_SCRIPT="./install.sh"
UNINSTALL_SCRIPT="./uninstall.sh"

# Temporary HOME for testing
setup() {
    TEST_HOME="$(mktemp -d)"
    export HOME="$TEST_HOME"

    mkdir -p "$HOME/.local/share"
    cp -r ./icons "$HOME/.local/share/"
    cp -r ./nemo "$HOME/.local/share/"
    cp -r ./nemo-git-integration "$HOME/.local/share/"

    # Create a dummy actions-tree.json
    mkdir -p "$HOME/.local/share/nemo"
    echo '{"test":"data"}' > "$HOME/.local/share/nemo/actions-tree.json"
}

teardown() {
    rm -rf "$TEST_HOME"
}

@test "uninstall.sh restores original actions-tree.json" {
    run "$INSTALL_SCRIPT"
    [ "$status" -eq 0 ]
    [ -f "$HOME/.local/share/nemo/actions-tree-bkup.json" ]

    # Modify actions-tree.json to simulate installation changes
    echo '{"modified":"data"}' > "$HOME/.local/share/nemo/actions-tree.json"

    run "$UNINSTALL_SCRIPT"
    [ "$status" -eq 0 ]

    # After uninstall, backup should be restored
    restored_content="$(<"$HOME/.local/share/nemo/actions-tree.json")"
    backup_content="$(<"$HOME/.local/share/nemo/actions-tree-bkup.json")"
    [ "$restored_content" = "$backup_content" ]
}

@test "uninstall.sh removes icons, nemo actions, and integration dir" {
    run "$INSTALL_SCRIPT"
    [ "$status" -eq 0 ]

    run "$UNINSTALL_SCRIPT"
    [ "$status" -eq 0 ]

    # Check that icons are removed
    for file in ./icons/*; do
        [ ! -f "$HOME/.local/share/icons/$(basename "$file")" ]
    done

    # Check that nemo actions are removed
    for file in ./nemo/actions/*; do
        [ ! -f "$HOME/.local/share/nemo/actions/$(basename "$file")" ]
    done

    # Check that integration dir is gone
    [ ! -d "$HOME/.local/share/nemo-git-integration" ]
}
