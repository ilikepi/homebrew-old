require 'formula'

class Postgis <Formula
  url 'http://postgis.refractions.net/download/postgis-1.4.1.tar.gz'
  homepage 'http://postgis.refractions.net/'
  md5 '78d13c4294f3336502ad35c8a30e5583'

  depends_on 'postgresql'
  depends_on 'proj'
  depends_on 'geos'

  def install
    ENV.deparallelize

    args = [
      "--disable-dependency-tracking",
      "--prefix=#{prefix}",
      "--with-projdir=#{HOMEBREW_PREFIX}"
    ]

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
