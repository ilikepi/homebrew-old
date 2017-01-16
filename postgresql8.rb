class Postgresql8 < Formula
  desc "Object-relational database system"
  homepage "http://www.postgresql.org/"
  url "http://ftp.postgresql.org/pub/source/v8.4.22/postgresql-8.4.22.tar.bz2"
  sha256 "5c1d56ce77448706d9dd03b2896af19d9ab1b9b8dcdb96c39707c74675ca3826"

  bottle do
    sha256 "3112ea7b41cf54ef5afb870a48cadd281ad0683903f9d5a075622f471e1078c7" => :yosemite
    sha256 "5a99e0e124cc349fbf9244d470e66dae026e9b3f14c1d69bb8812eddf23dffdb" => :mavericks
    sha256 "4ac58e1036d1a0848b1642542b293c4299c44bd34b9c1aeb931a7404556b1798" => :mountain_lion
  end

  depends_on "openssl"
  depends_on "readline"
  depends_on "libxml2" if MacOS.version == :leopard
  depends_on "ossp-uuid" => :recommended

  option "without-python", "Build without Python support"
  option "without-perl", "Build without Perl support"
  option "without-tcl", "Build without Tcl support"

  deprecated_option "no-python" => "without-python"
  deprecated_option "no-perl" => "without-perl"
  deprecated_option "no-tcl" => "without-tcl"

  # Fix build on 10.8 Mountain Lion
  # https://github.com/mxcl/homebrew/commit/cd77baf2e2f75b4ae141414bf8ff6d5c732e2b9a
  patch :DATA

  def install
    ENV.libxml2 if MacOS.version >= :snow_leopard

    args = %W[
      --disable-debug
      --prefix=#{prefix}
      --datadir=#{share}/#{name}
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

      if File.exist?("#{MacOS.sdk_path}/usr/lib/tclConfig.sh")
        args << "--with-tclconfig=#{MacOS.sdk_path}/usr/lib"
      end
    end

    if build.with? "ossp-uuid"
      ENV.append "CFLAGS", `uuid-config --cflags`.strip
      ENV.append "LDFLAGS", `uuid-config --ldflags`.strip
      ENV.append "LIBS", `uuid-config --libs`.strip
    end

    if MacOS.prefer_64_bit? and build.with? "python"
      args << "ARCHFLAGS='-arch x86_64'"
      check_python_arch
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

  def check_python_arch
    # On 64-bit systems, we need to look for a 32-bit Framework Python.
    # The configure script prefers this Python version, and if it doesn't
    # have 64-bit support then linking will fail.
    framework_python = Pathname.new "/Library/Frameworks/Python.framework/Versions/Current/Python"
    return unless framework_python.exist?
    unless (archs_for_command framework_python).include? :x86_64
      opoo "Detected a framework Python that does not have 64-bit support in:"
      puts <<-EOS.undent
          #{framework_python}

        The configure script seems to prefer this version of Python over any others,
        so you may experience linker problems as described in:
          http://osdir.com/ml/pgsql-general/2009-09/msg00160.html

        To fix this issue, you may need to either delete the version of Python
        shown above, or move it out of the way before brewing PostgreSQL.

        Note that a framework Python in /Library/Frameworks/Python.framework is
        the "MacPython" verison, and not the system-provided version which is in:
          /System/Library/Frameworks/Python.framework
      EOS
    end
  end

  def caveats
    s = <<-EOS.undent
      To build plpython against a specific Python, set PYTHON prior to brewing:
        PYTHON=/usr/local/bin/python brew install postgresql
      See:
        http://www.postgresql.org/docs/8.4/static/install-procedure.html


      If this is your first install, create a database with:
          initdb #{var}/postgres
    EOS

    if MacOS.prefer_64_bit?
      s << "\n" << <<-EOS.undent
        When installing the postgres gem, including ARCHFLAGS is recommended:
          ARCHFLAGS="-arch x86_64" gem install pg

        To install gems without sudo, see the Homebrew wiki.
      EOS
    end
    s
  end

  plist_options :manual => "pg_ctl -D #{HOMEBREW_PREFIX}/var/postgres -l #{HOMEBREW_PREFIX}/var/postgres/server.log start"

  def plist; <<-EOS.undent
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
        <string>#{var}/postgres</string>
        <string>-r</string>
        <string>#{var}/postgres/server.log</string>
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

