class WorkrsEdge < Formula
  desc "EU Edge Platform CLI - Build and deploy workers"
  homepage "https://workrs.eu"
  version "0.1.7"
  license "MIT"

  on_macos do
    on_intel do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.7/workrs-edge-x86_64-apple-darwin.tar.gz"
sha256 "0059c1a7479b8b58c1ddb81422d399f025f6b1125a95e502f2325118c0fdcb1d"
    end
    on_arm do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.7/workrs-edge-aarch64-apple-darwin.tar.gz"
sha256 "28ffca5bd12b61a998ad6de355f702a1f44bf83a2756736da71391e2db8f131f"
    end
  end

  on_linux do
    on_intel do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.7/workrs-edge-x86_64-unknown-linux-gnu.tar.gz"
sha256 "dd6aee656396387a6ac02275f3304c9689cc5f5e6fca024fe3fffa6447ee26ab"
    end
    on_arm do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.7/workrs-edge-aarch64-unknown-linux-gnu.tar.gz"
sha256 "226b69d3183bb65c1ff70e536795acbc621d8e2657076b0e2b4cde0ad2acb230"
    end
  end

  def install
    bin.install "workrs-edge"
  end

  test do
    assert_match version.to_s, shell_output("\#{bin}/workrs-edge --version")
  end
end
