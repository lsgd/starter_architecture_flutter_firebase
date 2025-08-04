#!/bin/bash

SELECTED_OS="${1}"

if [ "${FLUTTER_APPLE_API_KEY}" = "" ]
then
    read -p "Enter Apple API key: " FLUTTER_APPLE_API_KEY
fi
FLUTTER_APPLE_API_KEYFILE="~/.appstoreconnect/private_keys/AuthKey_${FLUTTER_APPLE_API_KEY}.p8"

if [ ! -f "${FLUTTER_APPLE_API_KEYFILE}" ]
then
    echo "Apple API key file does not exist in ${FLUTTER_APPLE_API_KEYFILE}."
    echo "Abort execution!"
    FLUTTER_APPLE_API_KEY=""
    FLUTTER_APPLE_API_KEYFILE=""
    exit 1
fi

if [ "${FLUTTER_APPLE_API_ISSUER}" = "" ]
then
    read -p "Enter Apple API issuer: " FLUTTER_APPLE_API_ISSUER
fi

# Enter directory where the release file is stored so relative paths work properly
cd $(dirname "$0")

# Increase build number by 1
perl -i -pe 's/^(version:\s+\d+\.\d+\.\d+\+)(\d+)$/$1.($2+1)/e' pubspec.yaml
version=`grep 'version: ' pubspec.yaml | sed 's/version: //'`
echo "Increased build to version \"${version}\""

echo
echo

git reset . 1> /dev/null
git add pubspec.yaml 1> /dev/null
git commit -m "Increase build number." 1> /dev/null

# Create ./_releases if it does not exist yet.
mkdir -p ./_releases


if [ "${SELECTED_OS}" = "" ] || [ "${SELECTED_OS}" = "android" ]
then
    # Create Android app bundle
    flutter build appbundle

    # Copy Android bundle
    cp ./build/app/outputs/bundle/release/app-release.aab ./_releases/android.aab
fi


if [ "${SELECTED_OS}" = "" ] || [ "${SELECTED_OS}" = "ios" ]
then
    # Delete existing IPA bundles.
    # If apps get renamed, a stale *.ipa bundle will remain in this directory.
    # This can later cause the COPY command to copy the wrong IPA bundle.
    rm -f ./build/ios/ipa/*.ipa 1> /dev/null

    # Create iOS app bundle
    flutter build ipa

    # Copy iOS bundle
    cp ./build/ios/ipa/*.ipa ./_releases/ios.ipa

    # Upload iOS bundle
    # Requires the P8 key file to be located in ~/.appstoreconnect/private_keys
    echo "Upload to Apple"
    xcrun altool --upload-app --type ios -f ./_releases/ios.ipa --apiKey ${FLUTTER_APPLE_API_KEY} --apiIssuer ${FLUTTER_APPLE_API_ISSUER}
fi
