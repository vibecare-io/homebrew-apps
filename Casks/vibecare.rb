cask "vibecare" do
  version "0.8.7.26"
  sha256 "c50214a6b4dcce90862a9601dffc267e06ab8dbb0659161a2a40c8781133f5f0"

  url "https://github.com/vibecare-io/vibecare/releases/download/v#{version}/vibecare-v#{version}-macos.tar.gz",
      verified: "github.com/vibecare-io/vibecare/"
  name "VibeCare"
  desc "Wellness and routine management app with on-device BFRB detection"
  homepage "https://github.com/vibecare-io/vibecare"

  depends_on macos: ">= :sequoia"

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

  zap trash: [
    "~/Library/Application Support/VibeCare",
    "~/.vibecare",
    "~/Library/Preferences/io.vibecare.App.vibecare.plist",
    "~/Library/Caches/io.vibecare.App.vibecare",
  ]
end
