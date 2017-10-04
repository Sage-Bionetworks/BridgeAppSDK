#!/bin/sh
set -ex

if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then     # on pull requests
    FASTLANE_EXPLICIT_OPEN_SIMULATOR=2 bundle exec fastlane scan
elif [[ -z "$TRAVIS_TAG" && "$TRAVIS_BRANCH" == "master" ]]; then  # non-tag commits to master branch
    bundle exec fastlane ci_archive scheme:"BridgeAppSDKSample" export_method:"development"
fi
exit $?
