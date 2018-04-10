#!/bin/bash
set -ex

echo "$PWD"

export PATH="$HOME/dart-sdk/bin:$PATH"
export ROOT="$PWD"
export PACKAGES=("file" "file_testing")

wget \
    --tries=3 \
    --output-document=dart-sdk.zip \
    https://storage.googleapis.com/dart-archive/channels/dev/release/latest/sdk/dartsdk-linux-x64-release.zip
echo "Unzipping dart-sdk..."
unzip dart-sdk.zip -d "$HOME" > /dev/null

for package in "${PACKAGES[@]}"; do
  cd $ROOT/packages/$package
  pub get
done
