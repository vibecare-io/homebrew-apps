# VibeCare Homebrew Tap

Homebrew tap for [VibeCare](https://github.com/vibecare-io/vibecare) apps.

## Install

```sh
brew tap vibecare-io/apps
brew install --cask vibecare
```

Or in one line:

```sh
brew install --cask vibecare-io/apps/vibecare
```

This installs the signed, notarized VibeCare macOS app (and the bundled
`vibecare-server`) from the latest [GitHub Release](https://github.com/vibecare-io/vibecare/releases).

## Update

```sh
brew upgrade --cask vibecare
```

## Uninstall

```sh
brew uninstall --cask vibecare        # remove the app
brew uninstall --zap --cask vibecare  # also remove app data (~/.vibecare, app support)
```

## Migrating from the `.pkg` installer

If you previously installed VibeCare with the `.pkg`, `brew install` will refuse
to overwrite `/Applications/VibeCare.app` (Homebrew won't clobber an app it
didn't install). Remove the old install first — your data in `~/.vibecare` is
kept:

```sh
launchctl bootout gui/$(id -u)/io.vibecare.server 2>/dev/null || true
rm -f ~/Library/LaunchAgents/io.vibecare.server.plist
sudo rm -rf /Applications/VibeCare.app /usr/local/bin/vibecare-server
sudo pkgutil --forget io.vibecare.app
brew install --cask vibecare-io/apps/vibecare
```

Quick alternative (overwrites the app only, leaves the old backend LaunchAgent):
`brew install --cask --force vibecare-io/apps/vibecare`.

## Requirements

- macOS 15 (Sequoia) or later

## Notes

`Casks/vibecare.rb` is updated automatically by the VibeCare release workflow on
every published release (version + `.pkg` checksum). See
`vibecare-io/vibecare` → `.github/workflows/release.yml` (`update-homebrew-tap` job).
