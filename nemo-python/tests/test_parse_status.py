import pytest

from nemo_git_status import (
    parse_porcelain_status,
    parse_untracked,
    parse_porcelain_v1,
    parse_porcelain_v2,
)

# -----------------------------
# parse_untracked fuzz tests
# -----------------------------
@pytest.mark.parametrize("line,expected", [
    ("?? file.txt", ("file.txt", "untracked")),
    ("??  space.txt", ("space.txt", "untracked")),
    ("??/weird/path.txt", ("/weird/path.txt", "untracked")),
    ("M modified.txt", (None, None)),  # Not untracked
    ("", (None, None)),  # Empty line
])
def test_parse_untracked(line, expected):
    assert parse_untracked(line) == expected


# -----------------------------
# parse_porcelain_v1 fuzz tests
# -----------------------------
@pytest.mark.parametrize("line,expected", [
    ("M file1.txt", ("file1.txt", "dirty")),
    ("A added.txt", ("added.txt", "dirty")),
    ("D deleted.txt", ("deleted.txt", "dirty")),
    ("R renamed.txt", ("renamed.txt", "dirty")),
    ("C copied.txt", ("copied.txt", "dirty")),
    ("? unknown.txt", ("unknown.txt", "untracked")),
    ("?? new.txt", (None, None)),  # Not v1 code
    ("", (None, None)),  # Empty line
    ("X unknown.txt", (None, None)),  # Unknown code
])
def test_parse_porcelain_v1(line, expected):
    assert parse_porcelain_v1(line) == expected


# -----------------------------
# parse_porcelain_v2 fuzz tests
# -----------------------------
@pytest.mark.parametrize("line,expected", [
    ("1 M. N... 0000000 0000000 file.txt", ("file.txt", "dirty")),
    ("2 M. N... 0000000 0000000 file2.txt", ("file2.txt", "dirty")),
    ("u UU N... 0000000 0000000 conflict.txt", ("conflict.txt", "dirty")),
    ("M file.txt", (None, None)),  # Not v2
    ("?? new.txt", (None, None)),  # Not v2
])
def test_parse_porcelain_v2(line, expected):
    assert parse_porcelain_v2(line) == expected


# -----------------------------
# parse_porcelain_status fuzz tests
# -----------------------------
@pytest.mark.parametrize("lines,expected", [
    ([], {}),
    (["?? newfile.txt"], {"newfile.txt": "untracked"}),
    (["M modified.txt"], {"modified.txt": "dirty"}),
    (["1 M. N... 0000000 0000000 modified.txt"], {"modified.txt": "dirty"}),
    (["   ", "\t"], {}),
    (["?? a.txt", "?? b.txt"], {"a.txt": "untracked", "b.txt": "untracked"}),
    (["u UU N... 0000000 0000000 conflict.txt"], {"conflict.txt": "dirty"}),
    (["D deleted.txt"], {"deleted.txt": "dirty"}),
    (["R renamed.txt"], {"renamed.txt": "dirty"}),
    (["C copied.txt"], {"copied.txt": "dirty"}),
    (["1 M. N... 0000000 0000000 mod1.txt", "2 M. N... 0000000 0000000 mod2.txt"],
     {"mod1.txt": "dirty", "mod2.txt": "dirty"}),
    (["M staged.txt", "?? untracked.txt"], {"staged.txt": "dirty", "untracked.txt": "untracked"}),
    (["# branch.oid abc123", "M modified.txt"], {"modified.txt": "dirty"}),
])
def test_parse_status_fuzzed(lines, expected):
    assert parse_porcelain_status(lines) == expected
