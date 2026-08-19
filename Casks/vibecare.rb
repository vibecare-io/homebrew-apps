cask "vibecare" do
  version "0.8.18.26-2"
  sha256 "96cb826b7a1a2c04753018327a0e1bc970737a7f63c30d760c7e624ae4183f28"

  url "https://github.com/vibecare-io/vibecare/releases/download/v#{version}/vibecare-v#{version}-macos.tar.gz",
      verified: "github.com/vibecare-io/vibecare/"
  name "VibeCare"
  desc "Wellness and routine management app with on-device BFRB detection"
  homepage "https://github.com/vibecare-io/vibecare"

  depends_on macos: :sequoia

  # `binary` must sit directly under `app` with no blank line
  # between them — `brew style` treats them as one stanza group.
  # The server ships inside the bundle, so put it on PATH too:
  # `vibecare-server --help` should not require anyone to type a
  # path into /Applications.
  app "VibeCare.app"
  binary "#{appdir}/VibeCare.app/Contents/Resources/vibecare-server"

  postflight do
    # App is Developer ID signed but not notarized; clear quarantine
    # so Gatekeeper allows first launch.
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/VibeCare.app"],
                   sudo: false

    # Install and start the backend's LaunchAgent HERE, rather than
    # leaving it to the app.
    #
    # Everything the app needs is already installed correctly — the
    # server binary and all five plugins sit in
    # Contents/Resources/, and when the server runs it finds them
    # ("discovered plugins ... count: 5"). The only missing piece on
    # a clean machine was a running process: nothing started it.
    #
    # The app was supposed to, via SMAppService. On a clean install
    # it does not, and it fails silently — measured on a fresh Mac,
    # launchd knew the label ("io.vibecare.server" => enabled in
    # print-disabled) while no job existed in the domain, no
    # ServiceManagement traffic came from the app at launch, and no
    # error was ever raised for the app to report. The user saw only
    # "Connection refused" on :50051 with no way to find out why.
    #
    # A plist in ~/Library/LaunchAgents has none of that ambiguity:
    # it exists as a file you can read, launchctl bootstrap either
    # works or says why, and it runs at every login whether or not
    # anyone opens the app. The app's own SMAppService call is left
    # alone and becomes harmless — the label is already loaded, so a
    # duplicate registration is refused and the backend it wanted is
    # the one already running.
    agent_plist = File.expand_path("~/Library/LaunchAgents/io.vibecare.server.plist")
    server      = "#{appdir}/VibeCare.app/Contents/Resources/vibecare-server"
    logs        = File.expand_path("~/.vibecare/logs")
    FileUtils.mkdir_p(File.dirname(agent_plist))
    FileUtils.mkdir_p(logs)
    # StandardOutPath/StandardErrorPath are the point of writing our
    # own plist rather than reusing the bundle's: the server only
    # starts logging to ~/.vibecare/logs/server.log once it is far
    # enough along to configure logging. Anything that kills it
    # before that — a port already bound, a migration failure —
    # previously left no trace anywhere.
    File.write(agent_plist, <<~PLIST)
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>Label</key><string>io.vibecare.server</string>
          <key>ProgramArguments</key>
          <array>
              <string>#{server}</string>
              <string>--port</string><string>50051</string>
              <string>--web-port</string><string>8080</string>
          </array>
          <key>RunAtLoad</key><true/>
          <key>KeepAlive</key><dict><key>SuccessfulExit</key><false/></dict>
          <key>ProcessType</key><string>Background</string>
          <key>StandardOutPath</key><string>#{logs}/agent.out.log</string>
          <key>StandardErrorPath</key><string>#{logs}/agent.err.log</string>
      </dict>
      </plist>
    PLIST

    # Bootout first so an upgrade replaces a running agent instead of
    # colliding with it. Must not abort the install: on a first
    # install there is nothing to bootout.
    system_command "/bin/launchctl",
                   args:         ["bootout", "gui/#{Process.uid}/io.vibecare.server"],
                   sudo:         false,
                   must_succeed: false
    system_command "/bin/launchctl",
                   args:         ["bootstrap", "gui/#{Process.uid}", agent_plist],
                   sudo:         false,
                   must_succeed: false
    # RunAtLoad covers a fresh bootstrap; kickstart covers the case
    # where the label was already loaded and needs to pick up the
    # newly installed binary.
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
  #
  # `trash:`, NOT `delete:`, for the plist the postflight writes.
  # Homebrew runs `delete:` under sudo — it is meant for root-owned
  # paths — so on a user file it prompts for a password, and in a
  # non-interactive uninstall it fails the whole operation:
  #   sudo: a terminal is required to read the password
  #   Error: Failure while executing; `/usr/bin/sudo ... /bin/rm` exited with 1
  # which aborts partway, leaving the app installed and the PATH
  # symlink behind. `trash:` needs no privileges.
  #
  # Removing the file matters as much as booting the agent out:
  # a plist left in ~/Library/LaunchAgents reloads at the next login
  # and points into /Applications at an app that is no longer there.
  uninstall launchctl: "io.vibecare.server",
            quit:      "io.vibecare.app",
            trash:     "~/Library/LaunchAgents/io.vibecare.server.plist"

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
