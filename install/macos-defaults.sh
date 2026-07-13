#!/usr/bin/env bash
# Reasonable macOS defaults.
# A few settings come from https://github.com/mathiasbynens/dotfiles/blob/master/.macos
set -euo pipefail

# Disable press-and-hold in favor of key repeat.
defaults write -g ApplePressAndHoldEnabled -bool false

# Use AirDrop over every interface.
defaults write com.apple.NetworkBrowser BrowseAllInterfaces 1

# Finder: always use list view.
defaults write com.apple.Finder FXPreferredViewStyle Nlsv

# Show ~/Library.
chflags nohidden ~/Library

# Really fast key repeat.
defaults write NSGlobalDomain KeyRepeat -int 0

# Show external volumes on the desktop.
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Screensaver in the bottom-left hot corner, ask for password right away.
defaults write com.apple.dock wvous-bl-corner -int 5
defaults write com.apple.dock wvous-bl-modifier -int 0
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Disable smart quotes and smart dashes.
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
