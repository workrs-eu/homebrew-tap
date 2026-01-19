class WorkrsEdge < Formula
  desc "EU Edge Platform CLI - Build and deploy workers"
  homepage "https://workrs.eu"
  version "0.1.5"
  license "MIT"

  on_macos do
    on_intel do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.5/workrs-edge-x86_64-apple-darwin.tar.gz"
sha256 "83d50f7456780f2af8fe4f079793d0700df192cc6a79a091c0291eee0eec9f2e"
    end
    on_arm do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.5/workrs-edge-aarch64-apple-darwin.tar.gz"
sha256 "a6c9c4554ba24c31581e2fd68fc830e2e732a30ae0e7388531dad4cff8437e18"
    end
  end

  on_linux do
    on_intel do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.5/workrs-edge-x86_64-unknown-linux-gnu.tar.gz"
sha256 "c22f3e68bc9abb0ee37228d7c663320955e0a5f48c78c8c0e8292159036c10f8"
    end
    on_arm do
url "https://github.com/workrs-eu/homebrew-tap/releases/download/v0.1.5/workrs-edge-aarch64-unknown-linux-gnu.tar.gz"
sha256 "376fe072c50c7a0f892379b23ee3d849d81b91dada6d0cb8db22f70a4d7609a1"
    end
  end

  def install
    bin.install "workrs-edge"
  end

  test do
    assert_match version.to_s, shell_output("\#{bin}/workrs-edge --version")
  end
end
