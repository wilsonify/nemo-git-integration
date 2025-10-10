import pytest
from nemo_git_status import parse_status

@pytest.mark.parametrize("lines,expected", [
    # basic cases
    ([], "clean"),
    (["?? newfile.txt"], "untracked"),
    (["M modified.txt"], "dirty"),
    (["1 M. N... 0000000 0000000 modified.txt"], "dirty"),

    # whitespace-only lines should be ignored
    (["   ", "\t"], "clean"),

    # multiple untracked files
    (["?? a.txt", "?? b.txt"], "untracked"),

    # unmerged conflicts
    (["u UU N... 0000000 0000000 conflict.txt"], "dirty"),

    # deleted, renamed, copied
    (["D deleted.txt"], "dirty"),
    (["R renamed.txt"], "dirty"),
    (["C copied.txt"], "dirty"),

    # porcelain v2 staged + unstaged
    (["1 M. N... 0000000 0000000 mod1.txt", "2 M. N... 0000000 0000000 mod2.txt"], "dirty"),

    # branch ahead only
    (["# branch.ab +3 -0"], "clean +3 -0"),

    # branch behind only
    (["# branch.ab +0 -4"], "clean +0 -4"),

    # branch ahead and behind with clean tree
    (["# branch.ab +1 -2"], "clean +1 -2"),

    # mix of staged changes and untracked
    (["M staged.txt", "?? untracked.txt"], "dirty"),

    # detached head
    (["# branch.oid abc123", "M modified.txt"], "dirty"),
])
def test_parse_status_fuzzed(lines, expected):
    result = parse_status(lines)
    assert expected in result
