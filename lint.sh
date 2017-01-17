#!/bin/sh
set -o pipefail && xcodebuild test -workspace Example/Pbind.xcworkspace -scheme Pbind-Example -destination 'platform=iOS Simulator,name=iPhone 5S,OS=10.2' | xcpretty
pod lib lint
