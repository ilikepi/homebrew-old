class PostgisAT14 < Formula
  url 'http://postgis.refractions.net/download/postgis-1.4.1.tar.gz'
  homepage 'http://postgis.refractions.net/'
  sha256 '17d96c59e1653d7441c98ba0762b55cae3dc22f51e897294d3262dee22ba0a50'

  keg_only "Conflicts with postgis in main repository."

  depends_on 'postgresql8'
  depends_on 'proj'
  depends_on 'geos'

  def install
    ENV.deparallelize
    postgresql = Formula['postgresql8']

    args = [
      "--disable-dependency-tracking",
      # Can't use --prefix, PostGIS disrespects it and flat-out refuses to
      # accept it with 2.0. We specify a staging path manually when running
      # 'make install'.
      "--with-projdir=#{HOMEBREW_PREFIX}",
      # This is against Homebrew guidelines, but we have to do it as the
      # PostGIS plugin libraries can only be properly inserted into Homebrew's
      # Postgresql keg.
      "--with-pgconfig=#{postgresql.bin}/pg_config",
      # Unfortunately, NLS support causes all kinds of headaches because
      # PostGIS gets all of it's compiler flags from the PGXS makefiles. This
      # makes it nigh impossible to tell the buildsystem where our keg-only
      # gettext installations are.
      "--disable-nls"
    ]

    system "./configure", *args
    system "make"

    # PostGIS includes the PGXS makefiles and so will install __everything__
    # into the Postgres keg instead of the PostGIS keg. Unfortunately, some
    # things have to be inside the Postgres keg in order to be function. So, we
    # install everything to a staging directory and manually move the pieces
    # into the appropriate prefixes.
    mkdir 'stage'
    system 'make', 'install', "DESTDIR=#{buildpath}/stage"

    # Install PostGIS plugin libraries into the Postgres keg so that they can
    # be loaded and so PostGIS databases will continue to function even if
    # PostGIS is removed.
    postgresql.lib.install Dir['stage/**/*.so']

    bin.install Dir['stage/**/bin/*']
    # In PostGIS 1.4, only one file is installed under lib, and we have
    # already moved it to postgresql.lib in an earlier step.
    #lib.install Dir['stage/**/lib/*']

    # Stand-alone SQL files will be installed the share folder
    (share + 'postgis').install Dir['stage/**/contrib/*']

    # Extension scripts
    bin.install %w[
      utils/create_undef.pl
      utils/new_postgis_restore.pl
      utils/postgis_proc_upgrade.pl
      utils/postgis_restore.pl
      utils/profile_intersects.pl
      utils/test_estimation.pl
      utils/test_joinestimation.pl
    ]

    man1.install Dir['doc/**/*.1']
  end

  def caveats
    postgresql = Formula['postgresql8']

    <<-EOS.undent
      Postgresql 9.0 is not supported by PostGis 1.4.

      To create a spatially-enabled database, see the documentation:
        http://postgis.refractions.net/documentation/manual-1.4/ch02.html#id2754935
      and to upgrade your existing spatial databases, see here:
        http://postgis.refractions.net/documentation/manual-1.4/ch02.html#upgrading

      PostGIS SQL scripts installed to:
        #{HOMEBREW_PREFIX}/share/postgis
      PostGIS plugin libraries installed to:
        #{postgresql.lib}
    EOS
  end
end
