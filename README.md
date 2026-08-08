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

## Requirements

- macOS 15 (Sequoia) or later

## Notes

`Casks/vibecare.rb` is updated automatically by the VibeCare release workflow on
every published release (version + `.pkg` checksum). See
`vibecare-io/vibecare` → `.github/workflows/release.yml` (`update-homebrew-tap` job).
