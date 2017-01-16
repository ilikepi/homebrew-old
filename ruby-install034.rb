class RubyInstall034 < Formula
  homepage 'https://github.com/postmodern/ruby-install#readme'
  url 'https://github.com/postmodern/ruby-install/archive/v0.3.4.tar.gz'
  sha256 'ccb1fe7c598e6c309c13f2b5892659247c5d21f3b0fff516a68f923048ea9f89'

  head 'https://github.com/postmodern/ruby-install.git'

  def install
    system 'make', 'install', "PREFIX=#{prefix}"
  end
end
