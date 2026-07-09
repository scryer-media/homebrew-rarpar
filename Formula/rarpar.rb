require "open3"

module RarparReleaseSelection
  MIN_GLIBC_VERSION = [2, 35].freeze

  def self.glibc_supported?
    version = glibc_version
    return false unless version

    (version <=> MIN_GLIBC_VERSION) >= 0
  end

  def self.glibc_version
    output = capture_getconf || capture_ldd
    match = output.to_s.match(/(?:glibc|GNU libc|GLIBC)[^0-9]*(\d+)\.(\d+)/i)
    return unless match

    [match[1].to_i, match[2].to_i]
  end

  def self.capture_getconf
    output, status = Open3.capture2("getconf", "GNU_LIBC_VERSION")
    status.success? ? output.strip : nil
  rescue
    nil
  end

  def self.capture_ldd
    output, status = Open3.capture2e("ldd", "--version")
    status.success? ? output.lines.first.to_s.strip : nil
  rescue
    nil
  end
end

class Rarpar < Formula
  desc "Smart RAR/PAR2 repair and extraction CLI"
  homepage "https://github.com/scryer-media/rarpar"
  version "0.2.4"
  license "GPL-3.0-or-later"

  on_macos do
    on_arm do
      url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.2.4/rarpar-rarpar-v0.2.4-darwin-arm64.tar.gz"
      sha256 "6c00aafcb05d95431ff819b650edbeaab9b912b705afbe1510e048d8afdfbfe4"
    end

    on_intel do
      url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.2.4/rarpar-rarpar-v0.2.4-darwin-x86_64.tar.gz"
      sha256 "5c958782b0ebeed0411bc46582f5281a4f619547e7f0b650e0b02c3f00e3c53f"
    end
  end

  on_linux do
    on_arm do
      if RarparReleaseSelection.glibc_supported?
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.2.4/rarpar-rarpar-v0.2.4-linux-arm64-gnu.tar.gz"
        sha256 "7da9f300ddf89e4136f62bcdffc6b812e9d1cadd023552b1d453e54d9d9fa82f"
      else
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.2.4/rarpar-rarpar-v0.2.4-linux-arm64-musl.tar.gz"
        sha256 "a928c07c1900f11f01317fec2d9c96f3ea69e89db33ba0b47d6a8be3cb2ca5b2"
      end
    end

    on_intel do
      if RarparReleaseSelection.glibc_supported?
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.2.4/rarpar-rarpar-v0.2.4-linux-x86_64-gnu.tar.gz"
        sha256 "f5c290a1ed30f1b770db27fbb5843048f7699b2d0a6685aa0f6dc4de633852ba"
      else
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.2.4/rarpar-rarpar-v0.2.4-linux-x86_64-musl.tar.gz"
        sha256 "38498088d6dbc58a9f90bd4bcf079c64dcfb0e2a832ec2133f73910040de91f9"
      end
    end
  end

  def install
    bin.install "rarpar"
    man1.install "share/man/man1/rarpar.1" if File.exist?("share/man/man1/rarpar.1")
    bash_completion.install "share/bash-completion/completions/rarpar" if File.exist?("share/bash-completion/completions/rarpar")
    if File.exist?("share/zsh/site-functions/_rarpar")
      zsh_completion.install "share/zsh/site-functions/_rarpar"
    end
    if File.exist?("share/fish/vendor_completions.d/rarpar.fish")
      fish_completion.install "share/fish/vendor_completions.d/rarpar.fish"
    end
    pkgshare.install "README.md" if File.exist?("README.md")
    pkgshare.install "LICENSE" if File.exist?("LICENSE")
    pkgshare.install "LICENSE.weaver-unrar" if File.exist?("LICENSE.weaver-unrar")
  end

  test do
    assert_match "rarpar", shell_output("#{bin}/rarpar --help")
    assert_match "rarpar #{version}", shell_output("#{bin}/rarpar --version")
    assert_path_exists man1/"rarpar.1"
  end
end
