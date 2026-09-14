class WorkrsEdge < Formula
  desc "EU Edge Platform CLI - Build and deploy workers"
  homepage "https://workrs.eu"
  version "0.2.1"
  license "MIT"

  on_macos do
    on_intel do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.2.1/workrs-edge-x86_64-apple-darwin.tar.gz"
sha256 "ea131b0f224176dfd35bc5a13d1ef379e99bd25c46faddf0f35a692926037f7d"
    end
    on_arm do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.2.1/workrs-edge-aarch64-apple-darwin.tar.gz"
sha256 "619bb6cf5290b0c6baeb7bc328fa84a4de7df70f3d126caf1371ae26b4ec0368"
    end
  end

  on_linux do
    on_intel do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.2.1/workrs-edge-x86_64-unknown-linux-gnu.tar.gz"
sha256 "4aeea6c42d7214b5f003f1555e54d0c23e5d4a37d9a99e20df0dba31ab695db4"
    end
    on_arm do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.2.1/workrs-edge-aarch64-unknown-linux-gnu.tar.gz"
sha256 "bd1a80688d08ddb496c57231b8a740db90842dc6781d41f48edeaae4ddefab08"
    end
  end

  def install
    bin.install "workrs-edge"
  end

  test do
    assert_match version.to_s, shell_output("\#{bin}/workrs-edge --version")
  end
end
