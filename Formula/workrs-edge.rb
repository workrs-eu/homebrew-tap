class WorkrsEdge < Formula
  desc "EU Edge Platform CLI - Build and deploy workers"
  homepage "https://workrs.eu"
  version "0.1.8"
  license "MIT"

  on_macos do
    on_intel do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.8/workrs-edge-x86_64-apple-darwin.tar.gz"
sha256 "2bd4b2ef9f5750cf96697a69f0d6a0a434e25ea446fd74d8de29520ce6aa8e82"
    end
    on_arm do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.8/workrs-edge-aarch64-apple-darwin.tar.gz"
sha256 "0a5d3fb3c435682afc1fd96d4ad62872c30983bb23761042ba4a221edb553d7c"
    end
  end

  on_linux do
    on_intel do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.8/workrs-edge-x86_64-unknown-linux-gnu.tar.gz"
sha256 "2e90fe4c809dd0638d6612f072e9a246caa14d3c912a988f33e191a1fe39f9ad"
    end
    on_arm do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.8/workrs-edge-aarch64-unknown-linux-gnu.tar.gz"
sha256 "80d63471157ab33a11b46c1b8046eba1ee2c6f7fafc6237045b59f3b0141278a"
    end
  end

  def install
    bin.install "workrs-edge"
  end

  test do
    assert_match version.to_s, shell_output("\#{bin}/workrs-edge --version")
  end
end
