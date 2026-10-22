# The cask for the jansim/homebrew-tap tap, which serves it as
# `brew install --cask jansim/tap/custom-calendar-url`.
# It always installs the latest GitHub release, so it needs no update per
# release; `brew upgrade --greedy` picks up new ones.
cask "custom-calendar-url" do
  version :latest
  sha256 :no_check

  url "https://github.com/jansim/apple-calendar-custom-url/releases/latest/download/CustomCalendarURL.zip"
  name "Custom Calendar URL"
  desc "Adds your own meeting links to Apple Calendar's video call options"
  homepage "https://github.com/jansim/apple-calendar-custom-url"

  depends_on macos: ">= :sonoma"

  app "CustomCalendarURL.app"

  # The app is only ad-hoc signed, not notarized, so Gatekeeper would refuse
  # to open it while it carries the quarantine flag.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/CustomCalendarURL.app"]
  end

  zap trash: [
    "~/Library/Containers/io.github.jansim.CustomCalendarURL.ConferenceProvider",
    "~/Library/Preferences/io.github.jansim.CustomCalendarURL.plist",
  ]
end
