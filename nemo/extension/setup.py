#!/usr/bin/python3
"""
Nemo Git Status
"""
from setuptools import setup

setup( packages=[],
    name         = "nemo-git-status",
    version      = "1.0.0",
    description  = "Column provider for nemo to show additional metadata for media and image files",
    author       = "Tom Andrew Wilson",
    author_email = "tom.andrew.wilson@gmail.com",
    url          = "https://github.com/wilsonify/nemo-git-integration",
    license      = "GPL3",
    data_files   = [
        ('/usr/share/nemo-python/extensions', ['nemo-git-status.py']),
        ('/usr/bin',                          ['git_status.prefs']),
        ('/usr/share/glib-2.0/schemas',       ['org.nemo.extensions.nemo-git-status.gschema.xml'])
    ]
)