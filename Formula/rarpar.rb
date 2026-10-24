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
  version "0.9.3"
  license all_of: ["GPL-3.0-or-later", :cannot_represent]

  on_macos do
    on_arm do
      url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.3/rarpar-rarpar-v0.9.3-darwin-arm64.tar.gz"
      sha256 "56927753bca491e9614d5eb5a2e7be27ef492a0f5c0cd563d61c361958658cc7"
    end

    on_intel do
      url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.3/rarpar-rarpar-v0.9.3-darwin-x86_64.tar.gz"
      sha256 "75731027334742960974e2cc25d8ae6fb15630f108cff84221f6a2bc4487d85b"
    end
  end

  on_linux do
    on_arm do
      if RarparReleaseSelection.glibc_supported?
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.3/rarpar-rarpar-v0.9.3-linux-arm64-gnu-direct.tar.gz"
        sha256 "6a7d93045960ce1281bbcbfc6b5f4e4de1d5bac401e5fd6a0f602485bf462406"
      else
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.3/rarpar-rarpar-v0.9.3-linux-arm64-musl-direct.tar.gz"
        sha256 "59a51cb418f6df48e7490d678adfe9feaecb01b325d990ff9698ee1aa8d527e9"
      end
    end

    on_intel do
      if RarparReleaseSelection.glibc_supported?
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.3/rarpar-rarpar-v0.9.3-linux-x86_64-gnu-direct.tar.gz"
        sha256 "58e2d7df2e154eca21bc89af65977b6daf3d0d32b320c9dacb73cabcddcfc9c2"
      else
        url "https://github.com/scryer-media/rarpar/releases/download/rarpar-v0.9.3/rarpar-rarpar-v0.9.3-linux-x86_64-musl-direct.tar.gz"
        sha256 "3b04010c27172dafab9289d5d2368eb1d54ea8b7db7488b47bd1349726c76982"
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
