class Edge < Formula
  desc "EU Edge Platform CLI - Build and deploy workers"
  homepage "https://workrs.eu"
  version "0.1.2"
  license "MIT"

  on_macos do
    on_intel do
      url "https://gitlab.com/workrs-eu/edge-rust/-/releases/v0.1.2/downloads/edge-x86_64-apple-darwin.tar.gz"
      sha256 "d11bea68db9603f581d1481720a430d3eb3665b4d0d0073a6a124b8cbd359218"
    end
    on_arm do
      url "https://gitlab.com/workrs-eu/edge-rust/-/releases/v0.1.2/downloads/edge-aarch64-apple-darwin.tar.gz"
      sha256 "70a3746bfa2b55305c5b5dbde5b27ef7b8352575cca38001efc1a74c99995705"
    end
  end

  on_linux do
    on_intel do
      url "https://gitlab.com/workrs-eu/edge-rust/-/releases/v0.1.2/downloads/edge-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "00e7edc7eb86793610883bf29a76d5fb87f50677c70055791ce944efb4cd36e2"
    end
    on_arm do
      url "https://gitlab.com/workrs-eu/edge-rust/-/releases/v0.1.2/downloads/edge-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "f3ec791d432cb9f6a79f5ca38ffeef0027e33ec8aa842ade86941971205e8e0d"
    end
  end

  def install
    bin.install "edge"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/edge --version")
  end
end
