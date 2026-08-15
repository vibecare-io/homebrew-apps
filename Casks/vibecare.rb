cask "vibecare" do
  version "0.8.15.26"
  sha256 "0a5f75b79cc97f45a53baee50f11ef7b475031e61cb4c6ea61b67d1d9c654eda"

  url "https://github.com/vibecare-io/vibecare/releases/download/v#{version}/vibecare-v#{version}-macos.tar.gz",
      verified: "github.com/vibecare-io/vibecare/"
  name "VibeCare"
  desc "Wellness and routine management app with on-device BFRB detection"
  homepage "https://github.com/vibecare-io/vibecare"

  depends_on macos: :sequoia

  app "VibeCare.app"

  # App is Developer ID signed but not notarized; clear quarantine so
  # Gatekeeper allows first launch.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/VibeCare.app"],
                   sudo: false
    # Best-effort: restart the backend only if its LaunchAgent is
    # already loaded (from a prior app launch). On a fresh install the
    # agent isn't registered yet (the app registers it via SMAppService
    # on first launch), so this must NOT abort the install.
    system_command "/bin/launchctl",
                   args: ["kickstart", "-k", "gui/#{Process.uid}/io.vibecare.server"],
                   sudo: false,
                   must_succeed: false
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
