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
  version "0.2.5"
  license all_of: ["GPL-3.0-or-later", :cannot_represent]

  on_macos do
    on_arm do
      url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.2.5/rarpar-rarpar-v0.2.5-darwin-arm64.tar.gz"
      sha256 "c2a521cdbd819fca3e017d252c66a972a5fc02d45996a259a816d0b181eeba58"
    end

    on_intel do
      url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.2.5/rarpar-rarpar-v0.2.5-darwin-x86_64.tar.gz"
      sha256 "8cd1819f98ff271eaff4a3c13d58ba2f4d859bbd9fd210e82a618d68e1afd466"
    end
  end

  on_linux do
    on_arm do
      if RarparReleaseSelection.glibc_supported?
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.2.5/rarpar-rarpar-v0.2.5-linux-arm64-gnu-direct.tar.gz"
        sha256 "95751951f84cc30ed12f2f17e26947b8dec509d694ea646ec0e840b1d70e0ce8"
      else
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.2.5/rarpar-rarpar-v0.2.5-linux-arm64-musl-direct.tar.gz"
        sha256 "7de21f6d72a076da242abb903fc0aeaab9c2e64db42646876ef2191922ccbc66"
      end
    end

    on_intel do
      if RarparReleaseSelection.glibc_supported?
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.2.5/rarpar-rarpar-v0.2.5-linux-x86_64-gnu-direct.tar.gz"
        sha256 "54534de31dd28ddf0afa25d7e53d128650116c62a603f1951c0f667a1ee8ad66"
      else
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.2.5/rarpar-rarpar-v0.2.5-linux-x86_64-musl-direct.tar.gz"
        sha256 "7b7de40a4c6efb15a9d901a29a83f5d92dbd1052283e9cff5112cb7005886be5"
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
    if File.exist?("LICENSE.GPL-3.0-or-later")
      pkgshare.install "LICENSE.GPL-3.0-or-later"
    end
    pkgshare.install "LICENSE.weaver-unrar" if File.exist?("LICENSE.weaver-unrar")
  end

  test do
    assert_match "rarpar", shell_output("#{bin}/rarpar --help")
    assert_match "rarpar #{version}", shell_output("#{bin}/rarpar --version")
    assert_path_exists man1/"rarpar.1"
  end
end
