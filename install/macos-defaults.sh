#!/usr/bin/env bash
# Defaults macOS raisonnables.
# Quelques réglages inspirés de https://github.com/mathiasbynens/dotfiles/blob/master/.macos
set -euo pipefail

# Désactive press-and-hold au profit de la répétition de touche.
defaults write -g ApplePressAndHoldEnabled -bool false

# AirDrop sur toutes les interfaces.
defaults write com.apple.NetworkBrowser BrowseAllInterfaces 1

# Finder : toujours en vue liste.
defaults write com.apple.Finder FXPreferredViewStyle Nlsv

# Affiche ~/Library.
chflags nohidden ~/Library

# Répétition de touche très rapide.
defaults write NSGlobalDomain KeyRepeat -int 0

# Volumes externes visibles sur le bureau.
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Écran de veille dans le coin bas-gauche, mot de passe immédiat.
defaults write com.apple.dock wvous-bl-corner -int 5
defaults write com.apple.dock wvous-bl-modifier -int 0
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Désactive guillemets et tirets « intelligents ».
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
