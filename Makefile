.PHONY: app package clean

MAKEFILE_DIR:="$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))"

# puts the app in $(MAKEFILE_DIR)/build/Build/Products/Release/name.app
app:
	pushd $(MAKEFILE_DIR); xcodebuild -project goftam.xcodeproj -scheme goftam -configuration Release -derivedDataPath build; popd

BUILT_APP_PATH:=$(MAKEFILE_DIR)/build/Build/Products/Release/goftam.app

package:
	# first argument is the path of the .app file, second argument is installation
	# directory for the app when the .pkg is run, third argument is the output
	# location for the .pkg file
	productbuild --component $(BUILT_APP_PATH) "/Library/Input Methods" $(MAKEFILE_DIR)/build/GoftamInstaller.pkg \
	# first argument is directory to zip, second is zipped directory; put the
	# zipped app file in GitHub releases too, that's what the homebrew casks use
	ditto -c -k --sequesterRsrc --keepParent $(BUILT_APP_PATH) $(MAKEFILE_DIR)/build/goftam.app.zip

clean:
	rm -rf $(MAKEFILE_DIR)/build
