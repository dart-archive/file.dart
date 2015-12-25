# Use this script to bootstrap your Cloud9 environment. This script:
#  - Tests SSH connection to GitHub
#  - Upgrades to the latest Dart SDK

set +e
echo "Testing connection to GitHub"
ssh -T "git@github.com"
SSH_RETURN_CODE=$?
set -e

# Because GitHub doesn't allow shell access the return code is 1 for success
# and (afaik) 255 for failure.
[ $SSH_RETURN_CODE -ne 1 ] && echo "Connection to GitHub failed" && exit 1

echo "Downloading the latest Dart SDK"

# Enable HTTPS for apt.
sudo apt-get update
sudo apt-get install apt-transport-https
# Get the Google Linux package signing key.
sudo sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
# Set up the location of the stable repository.
sudo sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'

echo "Updating Dart SDK"
sudo apt-get update
sudo apt-get install dart
echo "Add the following to your .bashrc: 'PATH=$PATH:/usr/lib/dart/bin'"

echo "Installing Dart format..."
/usr/lib/dart/bin/pub global activate dart_style

echo "Make sure" `git config user.email` "is registered in your GitHub's Account Settings > Emails."
echo "Make sure" `git config user.name` "is your GitHub user account name."
echo "Make sure to add your Cloud9 SSH key to your GitHub's Account Settings > SSH Keys, which you can find on your Cloud9 Dashboard (look for 'Show your SSH key'."
echo "Done."
