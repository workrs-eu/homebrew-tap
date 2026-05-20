class WorkrsEdge < Formula
  desc "EU Edge Platform CLI - Build and deploy workers"
  homepage "https://workrs.eu"
  version "0.1.10"
  license "MIT"

  on_macos do
    on_intel do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.10/workrs-edge-x86_64-apple-darwin.tar.gz"
sha256 "f4e94f8e9528682300d11fde035900d3ff801925be18d25e4f51bc2c863cddd1"
    end
    on_arm do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.10/workrs-edge-aarch64-apple-darwin.tar.gz"
sha256 "322a50edc032b245370dd33b299a5e0ea82f09f54feba32588a36d86e39c435b"
    end
  end

  on_linux do
    on_intel do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.10/workrs-edge-x86_64-unknown-linux-gnu.tar.gz"
sha256 "4f2671e3fc000e500a6297aba67a78b5669ba1e48d47416c0e153c1d835a662b"
    end
    on_arm do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.10/workrs-edge-aarch64-unknown-linux-gnu.tar.gz"
sha256 "dd072af9c31a3fed65f3d748d1a259ac837b29fed2ba437f5f0be578a295ba6f"
    end
  end

  def install
    bin.install "workrs-edge"
  end

  test do
    assert_match version.to_s, shell_output("\#{bin}/workrs-edge --version")
  end
end
