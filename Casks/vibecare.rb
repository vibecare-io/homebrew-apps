cask "vibecare" do
  version "0.8.18.26-1"
  sha256 "286e71b91a186ce5bc11dccb9ab9b7983e35891aa1c9f0cdc6fb9e58b5befb76"

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
                   args:         ["kickstart", "-k", "gui/#{Process.uid}/io.vibecare.server"],
                   sudo:         false,
                   must_succeed: false
  end

  # Without this, `brew uninstall` removes VibeCare.app and leaves
  # everything it started still running. Measured on 0.8.16.26: the
  # backend kept serving HTTP 200 on :8080 with all five plugins
  # alive, executing from a bundle that no longer existed — lsof
  # showed the binary still mapped from the deleted path — and the
  # LaunchAgent stayed registered, so at the next login launchd
  # would go on trying to spawn a program that is gone. One of the
  # survivors is `vision`, which holds the camera.
  #
  # Homebrew runs the uninstall keys in a fixed order, launchctl
  # before quit, which is the order wanted here: bootout the agent
  # so it cannot respawn the backend, then quit the app that would
  # re-register it. Placement is not free either — `brew style`
  # requires uninstall to sit between postflight and zap.
  uninstall launchctl: "io.vibecare.server",
            quit:      "io.vibecare.app"

  # Alphabetised, and zap kept directly after uninstall, because
  # `brew style` flags both otherwise.
  zap trash: [
    "~/.vibecare",
    "~/Library/Application Support/VibeCare",
    "~/Library/Caches/io.vibecare.App.vibecare",
    "~/Library/Preferences/io.vibecare.App.vibecare.plist",
  ]

  caveats <<~EOS
    If VibeCare was previously installed with the .pkg installer, remove that
    copy so Homebrew can manage it (your data in ~/.vibecare is preserved):

      launchctl bootout gui/$(id -u)/io.vibecare.server 2>/dev/null || true
      rm -f ~/Library/LaunchAgents/io.vibecare.server.plist
      sudo rm -rf /Applications/VibeCare.app /usr/local/bin/vibecare-server
      sudo pkgutil --forget io.vibecare.app

    then re-run: brew install --cask vibecare
  EOS
end
