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
  version "0.3.3"
  license all_of: ["GPL-3.0-or-later", :cannot_represent]

  on_macos do
    on_arm do
      url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.3.3/rarpar-rarpar-v0.3.3-darwin-arm64.tar.gz"
      sha256 "9b8b21251417f37d7e7022c0de1ccd058436523d9d874d0148ebb069d3b32768"
    end

    on_intel do
      url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.3.3/rarpar-rarpar-v0.3.3-darwin-x86_64.tar.gz"
      sha256 "675a3ee71f34f423f1f1b6352326a731e28e716a0b871b98a5553859eecb4a59"
    end
  end

  on_linux do
    on_arm do
      if RarparReleaseSelection.glibc_supported?
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.3.3/rarpar-rarpar-v0.3.3-linux-arm64-gnu-direct.tar.gz"
        sha256 "3ac0ea86e52b9706d045ea00193b85471be1106fa66a1cfb5130bc731343ae93"
      else
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.3.3/rarpar-rarpar-v0.3.3-linux-arm64-musl-direct.tar.gz"
        sha256 "2f9eca34da763620a51932d5ea3ed08406ad006a82cf3621fc203eef3401e02e"
      end
    end

    on_intel do
      if RarparReleaseSelection.glibc_supported?
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.3.3/rarpar-rarpar-v0.3.3-linux-x86_64-gnu-direct.tar.gz"
        sha256 "27661459184c4fefb0454df172c278f81941206f4740a2d993d1ccc4cfd40051"
      else
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.3.3/rarpar-rarpar-v0.3.3-linux-x86_64-musl-direct.tar.gz"
        sha256 "4aac21d4f2dc67fbbe3956ac953c42cf3eeeee312c6b080d82d78e57286df184"
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
