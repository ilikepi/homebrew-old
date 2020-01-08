class PostgresqlAT84 < Formula
  desc "Object-relational database system"
  homepage "https://www.postgresql.org/"
  url "https://ftp.postgresql.org/pub/source/v8.4.22/postgresql-8.4.22.tar.bz2"
  sha256 "5c1d56ce77448706d9dd03b2896af19d9ab1b9b8dcdb96c39707c74675ca3826"

  bottle do
    sha256 "3112ea7b41cf54ef5afb870a48cadd281ad0683903f9d5a075622f471e1078c7" => :yosemite
    sha256 "5a99e0e124cc349fbf9244d470e66dae026e9b3f14c1d69bb8812eddf23dffdb" => :mavericks
    sha256 "4ac58e1036d1a0848b1642542b293c4299c44bd34b9c1aeb931a7404556b1798" => :mountain_lion
  end

  keg_only :versioned_formula

  depends_on "openssl@1.0"
  depends_on "readline"
  depends_on "libxml2" if MacOS.version == :leopard
  depends_on "ossp-uuid" => :recommended

  option "without-python", "Build without Python support"
  option "without-perl", "Build without Perl support"
  option "without-tcl", "Build without Tcl support"

  deprecated_option "no-python" => "without-python"
  deprecated_option "no-perl" => "without-perl"
  deprecated_option "no-tcl" => "without-tcl"

  conflicts_with "postgresql",
    :because => "this is an alternate version of another formula."

  # Fix build on 10.8 Mountain Lion
  # https://github.com/mxcl/homebrew/commit/cd77baf2e2f75b4ae141414bf8ff6d5c732e2b9a
  patch :DATA

  def install
    args = %W[
      --disable-debug
      --prefix=#{prefix}
      --datadir=#{pkgshare}
      --docdir=#{doc}
      --enable-thread-safety
      --with-gssapi
      --with-krb5
      --with-openssl
      --with-libxml
      --with-libxslt
    ]

    args << "--with-bonjour" unless MacOS.version >= :mavericks
    args << "--with-ossp-uuid" if build.with? "ossp-uuid"
    args << "--with-python" if build.with? "python"
    args << "--with-perl" if build.with? "perl"

    # The CLT is required to build tcl support on 10.7 and 10.8 because tclConfig.sh is not part of the SDK
    if build.with?("tcl") && (MacOS.version >= :mavericks || MacOS::CLT.installed?)
      args << "--with-tcl"

      if File.exist?("#{MacOS.sdk_path}/System/Library/Frameworks/Tcl.framework/tclConfig.sh")
        args << "--with-tclconfig=#{MacOS.sdk_path}/System/Library/Frameworks/Tcl.framework"
      end
    end

    if build.with? "ossp-uuid"
      ENV.append "CFLAGS", `uuid-config --cflags`.strip
      ENV.append "LDFLAGS", `uuid-config --ldflags`.strip
      ENV.append "LIBS", `uuid-config --libs`.strip
    end

    if build.with? "python"
      args << "ARCHFLAGS='-arch x86_64'"
    end

    # As of Xcode/CLT 10.x the Perl headers were moved from /System
    # to inside the SDK, so we need to use `-iwithsysroot` instead
    # of `-I` to point to the correct location.
    # https://www.postgresql.org/message-id/153558865647.1483.573481613491501077%40wrigleys.postgresql.org
    # FIXME: The first inreplace call fails for some unknown reason.  Disable
    # perl support if you need to install this formula.
    if build.with?("perl") && DevelopmentTools.clang_build_version >= 1000
      inreplace "configure",
                "-I$perl_archlibexp/CORE",
                "-iwithsysroot $perl_archlibexp/CORE"
      inreplace "src/pl/plperl/GNUmakefile",
                "-I$(perl_archlibexp)/CORE",
                "-iwithsysroot $(perl_archlibexp)/CORE"
    end

    system "./configure", *args
    system "make", "install"

    %w[ adminpack dblink fuzzystrmatch lo uuid-ossp pg_buffercache pg_trgm
        pgcrypto tsearch2 vacuumlo xml2 intarray ].each do |a|
      cd "contrib/#{a}" do
        system "make", "install"
      end
    end
  end

  def post_install
    (var/"log").mkpath
    (var/name).mkpath
    unless File.exist? "#{var}/#{name}/PG_VERSION"
      system "#{bin}/initdb", "#{var}/#{name}"
    end
  end

  def caveats
    <<~EOS
      To build plpython against a specific Python, set PYTHON prior to brewing:
        PYTHON=/usr/local/bin/python brew install #{name}
      See:
        https://www.postgresql.org/docs/8.4/static/install-procedure.html


      If this is your first install, create a database with:
          initdb #{var}/#{name}

      When installing the postgres gem, including ARCHFLAGS is recommended:
        ARCHFLAGS="-arch x86_64" gem install pg

      To install gems without sudo, see the Homebrew wiki.
    EOS
  end

  plist_options :manual => "pg_ctl -D #{HOMEBREW_PREFIX}/var/postgresql@8.4 -l #{HOMEBREW_PREFIX}/var/postgresql@8.4/server.log start"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>KeepAlive</key>
      <true/>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>ProgramArguments</key>
      <array>
        <string>#{opt_prefix}/bin/postgres</string>
        <string>-D</string>
        <string>#{var}/#{name}</string>
        <string>-r</string>
        <string>#{var}/#{name}/server.log</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>WorkingDirectory</key>
      <string>#{HOMEBREW_PREFIX}</string>
    </dict>
    </plist>
  EOS
  end

  test do
    system "#{bin}/initdb", testpath/"test"
  end
end

__END__
 # If we don't have a shared library and the platform doesn't allow it
--- a/contrib/uuid-ossp/uuid-ossp.c	2012-07-30 18:34:53.000000000 -0700
+++ b/contrib/uuid-ossp/uuid-ossp.c	2012-07-30 18:35:03.000000000 -0700
@@ -9,6 +9,8 @@
  *-------------------------------------------------------------------------
  */
 
+#define _XOPEN_SOURCE
+
 #include "postgres.h"
 #include "fmgr.h"
 #include "utils/builtins.h"

