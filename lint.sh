#!/bin/sh
set -o pipefail && xcodebuild test -workspace Example/Pbind.xcworkspace -scheme Pbind-Example -destination 'platform=iOS Simulator,name=iPhone 6S,OS=10.2' | xcpretty
pod lib lint
