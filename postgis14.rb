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
  md5 '78d13c4294f3336502ad35c8a30e5583'

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
      "--prefix=#{prefix}",
      "--with-projdir=#{HOMEBREW_PREFIX}"
    ]

    # Apple ship a postgres client in Lion, conflicts with installed PostgreSQL server.
    if MacOS.lion?
      postgresql = pg_formula
      args << "--with-pgconfig=#{postgresql.bin}/pg_config"
    end

    system "./configure", *args
    system "make install"

    # Copy some of the generated files to the share folder
    (share+'postgis').install %w(
      spatial_ref_sys.sql postgis/postgis.sql
      postgis/postgis_upgrade.sql
      postgis/uninstall_postgis.sql
    )
    # Copy loader and utils binaries to bin folder
    bin.install %w(
      loader/pgsql2shp loader/shp2pgsql
      utils/new_postgis_restore.pl utils/postgis_proc_upgrade.pl
      utils/postgis_restore.pl utils/profile_intersects.pl
    )

  end

  def caveats; <<-EOS.undent
      Postgresql 9.0 is not supported by PostGis 1.4.

      To create a spatially-enabled database, see the documentation:
        http://postgis.refractions.net/documentation/manual-1.4/ch02.html#id2754935
    EOS
  end
end
