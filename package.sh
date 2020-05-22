#!/usr/bin/env sh

# first argument is path to the .app file
# second argument is path of the directory the .pkg will go in

# pkg seems to have trouble installing to the user's home directory so install for all users
productbuild --component "$1" "/Library/Input Methods/" "$2/GoftamInstaller.pkg"
