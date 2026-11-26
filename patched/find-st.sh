#!/bin/bash
grep -rlE '^Version: 70\.3\.0' /usr/local/lib /usr/lib/python3* /usr/lib64/python3* 2>/dev/null | head
find / -xdev \( -name '*.whl' -o -name '*.egg' \) 2>/dev/null | grep -i setuptools | head
