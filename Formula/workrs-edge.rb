class WorkrsEdge < Formula
  desc "EU Edge Platform CLI - Build and deploy workers"
  homepage "https://workrs.eu"
  version "0.1.6"
  license "MIT"

  on_macos do
    on_intel do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.6/workrs-edge-x86_64-apple-darwin.tar.gz"
sha256 "6d2ea1ab1dde8651efb5015b460acac8bab5f12c8b92c12b0dcdb19d99410e7d"
    end
    on_arm do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.6/workrs-edge-aarch64-apple-darwin.tar.gz"
sha256 "a8b907e8b020bb3662ed920f83199d7701f9e81ff9a8c1ef3d881634250f0a88"
    end
  end

  on_linux do
    on_intel do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.6/workrs-edge-x86_64-unknown-linux-gnu.tar.gz"
sha256 "cd27c05b708c092366517423577a86860a3075f7129b17de6122410d7a0a72f5"
    end
    on_arm do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.6/workrs-edge-aarch64-unknown-linux-gnu.tar.gz"
sha256 "81f58f0d0c596469495d477d5ad7e91d6f8aafe21fe44097da94b00623610f05"
    end
  end

  def install
    bin.install "workrs-edge"
  end

  test do
    assert_match version.to_s, shell_output("\#{bin}/workrs-edge --version")
  end
end
