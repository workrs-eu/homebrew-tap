class WorkrsEdge < Formula
  desc "EU Edge Platform CLI - Build and deploy workers"
  homepage "https://workrs.eu"
  version "0.2.2"
  license "MIT"

  on_macos do
    on_intel do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.2.2/workrs-edge-x86_64-apple-darwin.tar.gz"
sha256 "ade603c6707b835987e63b507dbc645728f13c28773c5a1ef8e355ae28a22458"
    end
    on_arm do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.2.2/workrs-edge-aarch64-apple-darwin.tar.gz"
sha256 "61ca136fde268a48d50e32d88cb7ec0cc5b042d8cb9c7732edb5d8eef45c3451"
    end
  end

  on_linux do
    on_intel do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.2.2/workrs-edge-x86_64-unknown-linux-gnu.tar.gz"
sha256 "0a05a5e2d468fac1e54784c89db15c82484e9161c755b681ec6c576e14f82753"
    end
    on_arm do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.2.2/workrs-edge-aarch64-unknown-linux-gnu.tar.gz"
sha256 "1055ec0e24318403afab20f56d4c3ad14aca0571178b7fac19d7cf348b639c64"
    end
  end

  def install
    bin.install "workrs-edge"
  end

  test do
    assert_match version.to_s, shell_output("\#{bin}/workrs-edge --version")
  end
end
