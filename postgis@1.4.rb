class PostgisAT14 < Formula
  url 'https://postgis.net/download/postgis-1.4.1.tar.gz'
  homepage 'https://postgis.net/'
  sha256 '17d96c59e1653d7441c98ba0762b55cae3dc22f51e897294d3262dee22ba0a50'

  keg_only :versioned_formula

  depends_on 'postgresql@8.4'
  depends_on 'proj@5.2'
  depends_on 'geos'

  conflicts_with "postgis",
    :because => "Conflicts with postgis in main repository."

  def install
    ENV.deparallelize
    postgresql = Formula['postgresql@8.4']
    proj       = Formula['proj@5.2']

    args = [
      "--disable-dependency-tracking",
      # Can't use --prefix, PostGIS disrespects it and flat-out refuses to
      # accept it with 2.0. We specify a staging path manually when running
      # 'make install'.
      "--with-projdir=#{proj.opt_prefix}",
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

    lib.install Dir['stage/**/*.so']

    bin.install Dir['stage/**/bin/*']

    # Stand-alone SQL files will be installed the share folder
    (share + name).install Dir['stage/**/contrib/*']

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
    <<-EOS.undent
      Postgresql 9.0 is not supported by PostGis 1.4.

      To create a spatially-enabled database, see the documentation:
        https://postgis.net/documentation/manual-1.4/ch02.html#id2754935
      and to upgrade your existing spatial databases, see here:
        https://postgis.net/documentation/manual-1.4/ch02.html#upgrading

      PostGIS SQL scripts installed to:
        #{share}/#{name}
      PostGIS plugin libraries installed to:
        #{lib}
    EOS
  end
end
