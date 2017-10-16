#!/bin/sh

# finds all executables (any executable bit is set)
# with a shell shebang that are not in .git
# POSIX-compliant

# shellcheck disable=SC2038
find . ! -path "./.git/*" ! -path "./gitlab/*" -type f \( -perm -u=x -o -perm -g=x -o -perm -o=x \) -exec grep -l '^#!/bin/sh$' {} \+ | xargs shellcheck
