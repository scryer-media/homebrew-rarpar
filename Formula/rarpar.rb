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
  rescue StandardError
    nil
  end

  def self.capture_ldd
    output, status = Open3.capture2e("ldd", "--version")
    status.success? ? output.lines.first.to_s.strip : nil
  rescue StandardError
    nil
  end
end

class Rarpar < Formula
  desc "Smart RAR/PAR2 repair and extraction CLI"
  homepage "https://github.com/scryer-media/rarpar"
  version "0.2.3"
  license "GPL-3.0-or-later"

  on_macos do
    on_arm do
      url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.2.3/rarpar-rarpar-v0.2.3-darwin-arm64.tar.gz"
      sha256 "13b68a4495267ecd447b03cfa51dc68a34b1ca0c5252cb6217d3507f36822244"
    end

    on_intel do
      url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.2.3/rarpar-rarpar-v0.2.3-darwin-x86_64.tar.gz"
      sha256 "3029c017aa530492adf9d10b54ec38d7f8c939c348d430426a1b99fac860ef87"
    end
  end

  on_linux do
    on_arm do
      if RarparReleaseSelection.glibc_supported?
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.2.3/rarpar-rarpar-v0.2.3-linux-arm64-gnu.tar.gz"
        sha256 "1aaaf075446df4593f545222c8619155918a6f5fa0be8ec02f23a40749f8a1bf"
      else
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.2.3/rarpar-rarpar-v0.2.3-linux-arm64-musl.tar.gz"
        sha256 "11fd7a34b5cbacfd784dc7536eb2183cc0bd023396b2b9bc4740cc7695678ba1"
      end
    end

    on_intel do
      if RarparReleaseSelection.glibc_supported?
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.2.3/rarpar-rarpar-v0.2.3-linux-x86_64-gnu.tar.gz"
        sha256 "da8b8270e5cd4e9902758b83146260003a8d6cc7730b825379d423bbb5ab9c77"
      else
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.2.3/rarpar-rarpar-v0.2.3-linux-x86_64-musl.tar.gz"
        sha256 "9a42dbea76feffdc1aef3f5a2acc8352c3e86009bc938a9b1a5e3c758b2553d2"
      end
    end
  end

  def install
    bin.install "rarpar"
    man1.install "share/man/man1/rarpar.1" if File.exist?("share/man/man1/rarpar.1")
    bash_completion.install "share/bash-completion/completions/rarpar" if File.exist?("share/bash-completion/completions/rarpar")
    zsh_completion.install "share/zsh/site-functions/_rarpar" if File.exist?("share/zsh/site-functions/_rarpar")
    fish_completion.install "share/fish/vendor_completions.d/rarpar.fish" if File.exist?("share/fish/vendor_completions.d/rarpar.fish")
    pkgshare.install "README.md" if File.exist?("README.md")
    pkgshare.install "LICENSE" if File.exist?("LICENSE")
    pkgshare.install "LICENSE.weaver-unrar" if File.exist?("LICENSE.weaver-unrar")
  end

  test do
    assert_match "rarpar", shell_output("#{bin}/rarpar --help")
    assert_path_exists man1/"rarpar.1"
  end
end
