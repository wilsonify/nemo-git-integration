from nemo_git_status import parse_status


# --------------------------
# parse_status tests
# --------------------------

def test_parse_status_clean():
    lines = []
    assert parse_status(lines) == "clean"


def test_parse_status_untracked():
    lines = ["?? newfile.txt"]
    assert parse_status(lines) == "untracked"


def test_parse_status_dirty():
    lines = ["M modified.txt"]
    assert parse_status(lines) == "dirty"

def test_parse_status_dirty_porcelain():
    # porcelain v2 line for a modified file
    lines = ["1 M. N... 0000000 0000000 modified.txt"]
    assert parse_status(lines) == "dirty"

def test_parse_status_with_ahead_and_behind():
    lines = [
        "# branch.ab +2 -1",
        "M foo.txt",
    ]
    result = parse_status(lines)
    assert "dirty" in result
