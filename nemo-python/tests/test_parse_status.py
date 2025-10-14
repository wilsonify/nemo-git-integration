import pytest

from nemo_git_status import parse_porcelain_status


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
def test_parse_status_fuzzed2(lines, expected):
    result = parse_porcelain_status(lines)
    assert result == expected
