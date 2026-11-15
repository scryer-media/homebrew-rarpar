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
  version "0.9.5"
  license all_of: ["GPL-3.0-or-later", :cannot_represent]

  on_macos do
    on_arm do
      url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.5/rarpar-rarpar-v0.9.5-darwin-arm64.tar.gz"
      sha256 "a13f877ca72883c0632ced6af564d1b1624793b7fb90543e61a3284128e9fbfd"
    end

    on_intel do
      url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.5/rarpar-rarpar-v0.9.5-darwin-x86_64.tar.gz"
      sha256 "2e42b2068cdfccab0132137c7c30684ea280639df2c1fa4d9c5027920a7b3a9e"
    end
  end

  on_linux do
    on_arm do
      if RarparReleaseSelection.glibc_supported?
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.5/rarpar-rarpar-v0.9.5-linux-arm64-gnu-direct.tar.gz"
        sha256 "4c3d1426217c6f7f01dbd2e61b008fdcdd66d492d50889d9c77ee0cb0ff03ce8"
      else
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.5/rarpar-rarpar-v0.9.5-linux-arm64-musl-direct.tar.gz"
        sha256 "ebf513cad684b189c01c1ca7c03ef179d282b24c27e34f9fa986bfa427ae08c6"
      end
    end

    on_intel do
      if RarparReleaseSelection.glibc_supported?
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.5/rarpar-rarpar-v0.9.5-linux-x86_64-gnu-direct.tar.gz"
        sha256 "48180563fecd5edb1620ad437d5056ca8ccfa467452482d9999b395b7363ac44"
      else
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.5/rarpar-rarpar-v0.9.5-linux-x86_64-musl-direct.tar.gz"
        sha256 "693e7d32d3256e31f4574304b12c1e140eee17a2a5746ff1f2dad2fa3ce7c5b7"
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
