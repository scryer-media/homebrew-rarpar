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
  version "0.9.7"
  license all_of: ["GPL-3.0-or-later", :cannot_represent]

  on_macos do
    on_arm do
      url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.7/rarpar-rarpar-v0.9.7-darwin-arm64.tar.gz"
      sha256 "6f261af4e8d42f8bb446075a1aeb3ca030b98f42361339cfa5a33b749bdc43ed"
    end

    on_intel do
      url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.7/rarpar-rarpar-v0.9.7-darwin-x86_64.tar.gz"
      sha256 "f4b5ddf52a3f2df344632b06e20372e09cfd70273a30fafc4f96bd842ff68aa9"
    end
  end

  on_linux do
    on_arm do
      if RarparReleaseSelection.glibc_supported?
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.7/rarpar-rarpar-v0.9.7-linux-arm64-gnu-direct.tar.gz"
        sha256 "68849ace700c41a6d2a0fb58a64e1812a9aace3a99a1f5b8088494e65be62e8e"
      else
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.7/rarpar-rarpar-v0.9.7-linux-arm64-musl-direct.tar.gz"
        sha256 "fd81da588bc82ca5d23afc9d9831a22582863fad2ae08a965ca3ef02b4ed4fb6"
      end
    end

    on_intel do
      if RarparReleaseSelection.glibc_supported?
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.7/rarpar-rarpar-v0.9.7-linux-x86_64-gnu-direct.tar.gz"
        sha256 "4cf587ec951d82e3aa08c6f93d835d0749afd6e35e28b50c8012fb714e422ef3"
      else
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.7/rarpar-rarpar-v0.9.7-linux-x86_64-musl-direct.tar.gz"
        sha256 "63e69886c9121b15f762aa1f7fde3fec7ac869ff426fb4647cc3c1cc630faf93"
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
