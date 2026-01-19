class WorkrsEdge < Formula
  desc "EU Edge Platform CLI - Build and deploy workers"
  homepage "https://workrs.eu"
  version "0.1.3"
  license "MIT"

  on_macos do
    on_intel do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.3/edge-x86_64-apple-darwin.tar.gz"
sha256 "3cf26752aef3585be86b7114ce4549267a4b549a15e4c780aca3d0878800795a"
    end
    on_arm do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.3/edge-aarch64-apple-darwin.tar.gz"
sha256 "f09a45770e16497ec9729411e405a73f1637340740cbb07f1a534c3733e291e4"
    end
  end

  on_linux do
    on_intel do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.3/edge-x86_64-unknown-linux-gnu.tar.gz"
sha256 "703f08b9b878a25379354cb52d07275a125e29ad3b7dcebe6b1d481b99c3fff6"
    end
    on_arm do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.3/edge-aarch64-unknown-linux-gnu.tar.gz"
sha256 "885da09a099db4045d29d95fcaf497882cb0b87a5d992040476dac0353700901"
    end
  end

  def install
    bin.install "edge"
  end

  test do
    assert_match version.to_s, shell_output("\#{bin}/edge --version")
  end
end
