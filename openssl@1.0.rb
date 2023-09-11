class OpensslAT10 < Formula
  desc "SSL/TLS cryptography library"
  homepage "https://openssl.org/"
  url "https://www.openssl.org/source/openssl-1.0.2t.tar.gz"
  mirror "https://dl.bintray.com/homebrew/mirror/openssl-1.0.2t.tar.gz"
  mirror "https://www.mirrorservice.org/sites/ftp.openssl.org/source/openssl-1.0.2t.tar.gz"
  sha256 "14cb464efe7ac6b54799b34456bd69558a749a4931ecfd9cf9f71d7881cac7bc"

  keg_only :provided_by_macos,
    "Apple has deprecated use of OpenSSL in favor of its own TLS and crypto libraries"

  # Fix build on macOS 12 for Apple Silicon.
  # https://gist.github.com/felixbuenemann/5f4dcb30ebb3b86e1302e2ec305bac89
  patch :DATA

  def install
    # OpenSSL will prefer the PERL environment variable if set over $PATH
    # which can cause some odd edge cases & isn't intended. Unset for safety,
    # along with perl modules in PERL5LIB.
    ENV.delete("PERL")
    ENV.delete("PERL5LIB")

    ENV.deparallelize

    if Hardware::CPU.arm?
      arch_target_string = 'darwin64-arm64-cc'
    else
      arch_target_string = 'darwin64-x86_64-cc'
    end

    args = %W[
      --prefix=#{prefix}
      --openssldir=#{openssldir}
      no-ssl2
      no-ssl3
      no-zlib
      shared
      enable-cms
      #{arch_target_string}
      enable-ec_nistp_64_gcc_128
    ]
    system "perl", "./Configure", *args
    system "make", "depend"
    system "make"

    # Disable failing step on Apple Silicon. #yolo
    unless Hardware::CPU.arm?
      system "make", "test"
    end

    system "make", "install", "MANDIR=#{man}", "MANSUFFIX=ssl"
  end

  def openssldir
    etc/"openssl@1.0"
  end

  def post_install
    keychains = %w[
      /System/Library/Keychains/SystemRootCertificates.keychain
    ]

    certs_list = `security find-certificate -a -p #{keychains.join(" ")}`
    certs = certs_list.scan(
      /-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----/m,
    )

    valid_certs = certs.select do |cert|
      IO.popen("#{bin}/openssl x509 -inform pem -checkend 0 -noout", "w") do |openssl_io|
        openssl_io.write(cert)
        openssl_io.close_write
      end

      $CHILD_STATUS.success?
    end

    openssldir.mkpath
    (openssldir/"cert.pem").atomic_write(valid_certs.join("\n") << "\n")
  end

  def caveats; <<~EOS
    A CA file has been bootstrapped using certificates from the SystemRoots
    keychain. To add additional certificates (e.g. the certificates added in
    the System keychain), place .pem files in
      #{openssldir}/certs

    and run
      #{opt_bin}/c_rehash
  EOS
  end

  test do
    # Make sure the necessary .cnf file exists, otherwise OpenSSL gets moody.
    assert_predicate HOMEBREW_PREFIX/"etc/openssl@1.0/openssl.cnf", :exist?,
            "OpenSSL requires the .cnf file for some functionality"

    # Check OpenSSL itself functions as expected.
    (testpath/"testfile.txt").write("This is a test file")
    expected_checksum = "e2d0fe1585a63ec6009c8016ff8dda8b17719a637405a4e23c0ff81339148249"
    system "#{bin}/openssl", "dgst", "-sha256", "-out", "checksum.txt", "testfile.txt"
    open("checksum.txt") do |f|
      checksum = f.read(100).split("=").last.strip
      assert_equal checksum, expected_checksum
    end
  end
end
__END__
--- openssl-1.0.2t/Configure	2019-12-20 14:02:41.000000000 +0100
+++ openssl-1.0.2t/Configure	2020-11-22 16:23:13.000000000 +0100
@@ -650,7 +650,9 @@
 "darwin-i386-cc","cc:-arch i386 -O3 -fomit-frame-pointer -DL_ENDIAN::-D_REENTRANT:MACOSX:-Wl,-search_paths_first%:BN_LLONG RC4_INT RC4_CHUNK DES_UNROLL BF_PTR:".eval{my $asm=$x86_asm;$asm=~s/cast\-586\.o//;$asm}.":macosx:dlfcn:darwin-shared:-fPIC -fno-common:-arch i386 -dynamiclib:.\$(SHLIB_MAJOR).\$(SHLIB_MINOR).dylib",
 "debug-darwin-i386-cc","cc:-arch i386 -g3 -DL_ENDIAN::-D_REENTRANT:MACOSX:-Wl,-search_paths_first%:BN_LLONG RC4_INT RC4_CHUNK DES_UNROLL BF_PTR:${x86_asm}:macosx:dlfcn:darwin-shared:-fPIC -fno-common:-arch i386 -dynamiclib:.\$(SHLIB_MAJOR).\$(SHLIB_MINOR).dylib",
 "darwin64-x86_64-cc","cc:-arch x86_64 -O3 -DL_ENDIAN -Wall::-D_REENTRANT:MACOSX:-Wl,-search_paths_first%:SIXTY_FOUR_BIT_LONG RC4_CHUNK DES_INT DES_UNROLL:".eval{my $asm=$x86_64_asm;$asm=~s/rc4\-[^:]+//;$asm}.":macosx:dlfcn:darwin-shared:-fPIC -fno-common:-arch x86_64 -dynamiclib:.\$(SHLIB_MAJOR).\$(SHLIB_MINOR).dylib",
+"darwin64-arm64-cc","cc:-arch arm64 -O3 -DL_ENDIAN -Wall::-D_REENTRANT:MACOSX:-Wl,-search_paths_first%:SIXTY_FOUR_BIT_LONG RC4_CHUNK DES_INT DES_UNROLL:${no_asm}:dlfcn:darwin-shared:-fPIC -fno-common:-arch arm64 -dynamiclib:.\$(SHLIB_MAJOR).\$(SHLIB_MINOR).dylib",
 "debug-darwin64-x86_64-cc","cc:-arch x86_64 -ggdb -g2 -O0 -DL_ENDIAN -Wall::-D_REENTRANT:MACOSX:-Wl,-search_paths_first%:SIXTY_FOUR_BIT_LONG RC4_CHUNK DES_INT DES_UNROLL:".eval{my $asm=$x86_64_asm;$asm=~s/rc4\-[^:]+//;$asm}.":macosx:dlfcn:darwin-shared:-fPIC -fno-common:-arch x86_64 -dynamiclib:.\$(SHLIB_MAJOR).\$(SHLIB_MINOR).dylib",
+"debug-darwin64-arm64-cc","cc:-arch arm64 -ggdb -g2 -O0 -DL_ENDIAN -Wall::-D_REENTRANT:MACOSX:-Wl,-search_paths_first%:SIXTY_FOUR_BIT_LONG RC4_CHUNK DES_INT DES_UNROLL:${no_asm}:dlfcn:darwin-shared:-fPIC -fno-common:-arch arm64 -dynamiclib:.\$(SHLIB_MAJOR).\$(SHLIB_MINOR).dylib",
 "debug-darwin-ppc-cc","cc:-DBN_DEBUG -DREF_CHECK -DCONF_DEBUG -DCRYPTO_MDEBUG -DB_ENDIAN -g -Wall -O::-D_REENTRANT:MACOSX::BN_LLONG RC4_CHAR RC4_CHUNK DES_UNROLL BF_PTR:${ppc32_asm}:osx32:dlfcn:darwin-shared:-fPIC:-dynamiclib:.\$(SHLIB_MAJOR).\$(SHLIB_MINOR).dylib",
 # iPhoneOS/iOS
 "iphoneos-cross","llvm-gcc:-O3 -isysroot \$(CROSS_TOP)/SDKs/\$(CROSS_SDK) -fomit-frame-pointer -fno-common::-D_REENTRANT:iOS:-Wl,-search_paths_first%:BN_LLONG RC4_CHAR RC4_CHUNK DES_UNROLL BF_PTR:${no_asm}:dlfcn:darwin-shared:-fPIC -fno-common:-dynamiclib:.\$(SHLIB_MAJOR).\$(SHLIB_MINOR).dylib",

