#!/bin/sh
set -ex
# show available schemes
xcodebuild -list -project ./BridgeAppSDK.xcodeproj
# run on pull request
if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
  fastlane test scheme:"BridgeAppSDK"
  exit $?
fi
