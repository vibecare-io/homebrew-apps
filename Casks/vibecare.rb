cask "vibecare" do
  version "0.8.8.26"
  sha256 "0d012401048bf964820f7ac7a02860a8561cd86847f02181387077b7f8705026"

  url "https://github.com/vibecare-io/vibecare/releases/download/v#{version}/vibecare-v#{version}-macos.tar.gz",
      verified: "github.com/vibecare-io/vibecare/"
  name "VibeCare"
  desc "Wellness and routine management app with on-device BFRB detection"
  homepage "https://github.com/vibecare-io/vibecare"

  depends_on macos: :sequoia

  app "VibeCare.app"
  binary "vibecare-server"

  # The app is Developer ID signed but not yet notarized, so clear the
  # quarantine flag Homebrew applies on download — otherwise Gatekeeper blocks
  # first launch. (Restore notarization on the release side to drop this.)
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/VibeCare.app"],
                   sudo: false
  end

  caveats <<~EOS
    If VibeCare was previously installed with the .pkg installer, remove that
    copy so Homebrew can manage it (your data in ~/.vibecare is preserved):

      launchctl bootout gui/$(id -u)/io.vibecare.server 2>/dev/null || true
      rm -f ~/Library/LaunchAgents/io.vibecare.server.plist
      sudo rm -rf /Applications/VibeCare.app /usr/local/bin/vibecare-server
      sudo pkgutil --forget io.vibecare.app

    then re-run: brew install --cask vibecare
  EOS

  zap trash: [
    "~/Library/Application Support/VibeCare",
    "~/.vibecare",
    "~/Library/Preferences/io.vibecare.App.vibecare.plist",
    "~/Library/Caches/io.vibecare.App.vibecare",
  ]
end
