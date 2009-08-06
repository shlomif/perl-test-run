#!/bin/bash
# This file is licensed under the MIT X11 License:
# http://www.opensource.org/licenses/mit-license.php
cat file-list.txt | grep -v '/$' | sort | diff -u MANIFEST - |
    grep -vP '^\+bin/prove$' | grep -vP '^\+check-manifest\.sh$' |
    grep -vF META.yml | grep -v '^ ' | grep -vP '^(\+\+\+|\-\-\-|@@)'
