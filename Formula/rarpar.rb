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
  version "0.9.4"
  license all_of: ["GPL-3.0-or-later", :cannot_represent]

  on_macos do
    on_arm do
      url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.4/rarpar-rarpar-v0.9.4-darwin-arm64.tar.gz"
      sha256 "aab7cb89c368c0463f2081f910217be85da95fc5363174c600056fd90908b9ec"
    end

    on_intel do
      url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.4/rarpar-rarpar-v0.9.4-darwin-x86_64.tar.gz"
      sha256 "6e2a8d32ffcf9f35f02854e5d17cee66a86434bcc09df41f2e375e5e8bf3cd68"
    end
  end

  on_linux do
    on_arm do
      if RarparReleaseSelection.glibc_supported?
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.4/rarpar-rarpar-v0.9.4-linux-arm64-gnu-direct.tar.gz"
        sha256 "306910f3d4f1c5a3a289f8c753fe245e69173ce6face4917bcd1fe58d065e3bc"
      else
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.4/rarpar-rarpar-v0.9.4-linux-arm64-musl-direct.tar.gz"
        sha256 "5d38bfb9e017593399a390957a8808aecd426e24a42a2d9ca1b92782769842f9"
      end
    end

    on_intel do
      if RarparReleaseSelection.glibc_supported?
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.4/rarpar-rarpar-v0.9.4-linux-x86_64-gnu-direct.tar.gz"
        sha256 "903109a5c12cf7b497112967da8b921e631b6d1b5e71c72e4fe97cf38db65b6b"
      else
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.4/rarpar-rarpar-v0.9.4-linux-x86_64-musl-direct.tar.gz"
        sha256 "33be0dd5f6f2b9a5a01628794ae1662d35c43ce865a4632d4274c202f02cf74c"
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
  end

  test do
    assert_match "rarpar", shell_output("#{bin}/rarpar --help")
    assert_match "rarpar #{version}", shell_output("#{bin}/rarpar --version")
    assert_path_exists man1/"rarpar.1"
  end
end
