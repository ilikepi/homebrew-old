require 'formula'

def pg_formula
  pg_args = ARGV.options_only.select { |v| v =~ /--postgres=/ }.uniq

  if pg_args.empty?
    return Formula.factory 'postgresql'
  else
    # An exception will be thrown if the formula specified isn't valid.
    return Formula.factory pg_args.last.split('=')[1]
  end
end

class Postgis14 < Formula
  url 'http://postgis.refractions.net/download/postgis-1.4.1.tar.gz'
  homepage 'http://postgis.refractions.net/'
  sha1 'e30062d6e38f787374866a6f4bc2920e032bc0e7'

  depends_on pg_formula.name
  depends_on 'proj'
  depends_on 'geos'

  def options
    [
      ['--postgres=PGNAME', 'Build against the named PostgreSQL formula']
    ]
  end

  def install
    ENV.deparallelize
    postgresql = pg_formula

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
    postgresql = pg_formula

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
