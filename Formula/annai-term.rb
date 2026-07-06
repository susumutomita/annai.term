# Homebrew formula。ソースからビルドする（macOS 26 + Apple Intelligence が前提）。
#
# 使い方:
#   brew tap susumutomita/annai-term https://github.com/susumutomita/annai.term
#   brew install annai-term
#
# または最新の main から:
#   brew install --HEAD susumutomita/annai-term/annai-term
class AnnaiTerm < Formula
  desc "Answer Ghostty and Herdr keybindings in Japanese, on-device (macOS)"
  homepage "https://github.com/susumutomita/annai.term"
  url "https://github.com/susumutomita/annai.term/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "SHA256_PLACEHOLDER"
  license "MIT"
  head "https://github.com/susumutomita/annai.term.git", branch: "main"

  depends_on :macos

  def install
    system "swift", "build", "--disable-sandbox", "-c", "release", "--product", "annai-term"
    bin.install ".build/release/annai-term"
  end

  test do
    assert_match "0.1.1", shell_output("#{bin}/annai-term --version")
  end
end
