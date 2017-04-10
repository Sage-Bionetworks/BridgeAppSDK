#!/bin/sh
set -ex
# show available schemes
# xcodebuild -list -project ./BridgeAppSDK.xcodeproj
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
    bundle exec fastlane test scheme:"BridgeAppSDK"
elif [ "$TRAVIS_BRANCH" = "master" ]; then
    bundle exec fastlane ci_archive scheme:"BridgeAppSDKSample" export_method:"enterprise"
fi
exit $?
