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
  version "0.9.6"
  license all_of: ["GPL-3.0-or-later", :cannot_represent]

  on_macos do
    on_arm do
      url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.6/rarpar-rarpar-v0.9.6-darwin-arm64.tar.gz"
      sha256 "ddb2c4a9f3c9a6071e5840d62c0cbf807d088a0d12821836fc309515acf4ee2d"
    end

    on_intel do
      url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.6/rarpar-rarpar-v0.9.6-darwin-x86_64.tar.gz"
      sha256 "75d6fa699e0f2a9890ff7eb19f5bd82cb1e16eeaf6d07d1324ed515099f4618b"
    end
  end

  on_linux do
    on_arm do
      if RarparReleaseSelection.glibc_supported?
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.6/rarpar-rarpar-v0.9.6-linux-arm64-gnu-direct.tar.gz"
        sha256 "61a467ec07e344aab314bf23e718468b6b22728d13c73fba734894fa8502acdf"
      else
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.6/rarpar-rarpar-v0.9.6-linux-arm64-musl-direct.tar.gz"
        sha256 "4622636537080a539a898f008f99ae94f3bd5b0cfeb162a5a0382211a860650b"
      end
    end

    on_intel do
      if RarparReleaseSelection.glibc_supported?
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.6/rarpar-rarpar-v0.9.6-linux-x86_64-gnu-direct.tar.gz"
        sha256 "fc6e356d5c74a33f25e362b1168a3289529bf8618feb1cfd909904b9ffacab08"
      else
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.6/rarpar-rarpar-v0.9.6-linux-x86_64-musl-direct.tar.gz"
        sha256 "fa2fc12297f3a7f1fd83d4eeca11fa8d9217cbcea772166f504a01b7eceea86c"
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
