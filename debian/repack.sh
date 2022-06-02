#!/bin/sh
# Repack an upstream tarball, unpacking waf files inside it.
#
# Meant to be run by uscan(1) as the "command param", after repacking
# (if any) by mk-origtargz. So you shouldn't give "repacksuffix" to
# debian/watch; instead you should set it below; however this should
# still match the dversionmangle in that file.

repacksuffix="+repack"
dfsgremovals="Makefile.bak \
     .gitattributes \
     .gitignore \
     .hg_archival \
     .hg_archival.txt \
     .hgignore \
     .hgtags \
     fontlucida.png \
     sqlite \
     json \
     lua \
     liberationmono.ttf \
     liberationsans.ttf \
     *.jar"
#jthread # upstream patched that lib, which seem dead upstream itself, so use minetest's version even if I don't like it.

included_games="minetest_game"

# You shouldn't need to change anything below here.

USAGE="Usage: $0 --upstream-version version filename"

test "$1" = "--upstream-version" || { echo >&2 "$USAGE"; exit 2; }
upstream="$2"
filename="$3"

source="$(dpkg-parsechangelog -SSource)"
newups="${upstream}${repacksuffix}"
basedir="$(dirname "$filename")"

set -e

mkdir temp
cd temp
tar -xf "../$filename"

cd "${source}-${upstream}"

# Remove non-free content
set +ex
for file in $dfsgremovals ; do
  filelist="$filelist "`find . -name $file`
done
set -ex
rm -rf $filelist

# Add the basic game
for game in $included_games ; do 
  wget --no-verbose https://github.com/minetest/${game}/archive/${upstream}.tar.gz -O - | tar xfz - 
  mv ${game}-${upstream} games/${game}
done

# Repack everything
cd ..
mv "${source}-${upstream}" "${source}-${newups}"
if [ -e "../$basedir/${source}_${newups}.orig.tar.gz" ]; then
  mv "../$basedir/${source}_${newups}.orig.tar.gz" "../$basedir/${source}_${newups}.orig.tar.gz.bak"
fi
GZIP="-9n" tar -czf "../$basedir/${source}_${newups}.orig.tar.gz" "${source}-${newups}"
if [ ! -e "../$basedir/${source}_${newups}.orig.tar.gz" ] && \
   [ -e "../$basedir/${source}_${newups}.orig.tar.gz.bak" ]; then
  mv "../$basedir/${source}_${newups}.orig.tar.gz.bak" "../$basedir/${source}_${newups}.orig.tar.gz"
fi
rm -rf "${source}-${newups}"

cd ../ # out of temp
rm -rf temp
