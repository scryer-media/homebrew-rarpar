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
  version "0.3.0"
  license all_of: ["GPL-3.0-or-later", :cannot_represent]

  on_macos do
    on_arm do
      url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.3.0/rarpar-rarpar-v0.3.0-darwin-arm64.tar.gz"
      sha256 "85ff70bc05a51ce45cedec20c56cb85a8a53deb285d32b584a7effc1507d3f4a"
    end

    on_intel do
      url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.3.0/rarpar-rarpar-v0.3.0-darwin-x86_64.tar.gz"
      sha256 "b1eb67e02f1de0953e144b2033868fa6304c1990c6d52d991407814565c1d2c0"
    end
  end

  on_linux do
    on_arm do
      if RarparReleaseSelection.glibc_supported?
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.3.0/rarpar-rarpar-v0.3.0-linux-arm64-gnu-direct.tar.gz"
        sha256 "56d69bfcab28b4981ef909826e64dfd314849b8de8a92c8edca14b98d3989ee1"
      else
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.3.0/rarpar-rarpar-v0.3.0-linux-arm64-musl-direct.tar.gz"
        sha256 "a83255b01d94fa71e5f49d7291ff279b8deba48a84ac43df80f679d07090e1d7"
      end
    end

    on_intel do
      if RarparReleaseSelection.glibc_supported?
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.3.0/rarpar-rarpar-v0.3.0-linux-x86_64-gnu-direct.tar.gz"
        sha256 "fdf117a7dae6d8022641cd48e9d1e697ecd20b4c59e1495c388fbedf8ac442e2"
      else
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.3.0/rarpar-rarpar-v0.3.0-linux-x86_64-musl-direct.tar.gz"
        sha256 "744fe75e6adb0ff7c1b9dfe1cab0aa4e430bc14a8a1cf0038e50dd60ec99a820"
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
    pkgshare.install "LICENSE.unrar-rs" if File.exist?("LICENSE.unrar-rs")
  end

  test do
    assert_match "rarpar", shell_output("#{bin}/rarpar --help")
    assert_match "rarpar #{version}", shell_output("#{bin}/rarpar --version")
    assert_path_exists man1/"rarpar.1"
  end
end
