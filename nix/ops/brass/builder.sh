source $stdenv/setup

set -ex

cp -r $PIER ./pier
chmod -R u+rw ./pier

$URBIT -d ./pier

cleanup () {
  if [ -e ./pier/.vere.lock ]
  then kill $(< ./pier/.vere.lock) || true;
  fi
}

trap cleanup EXIT

herb ./pier -P brass.pill -d '+brass'

mv brass.pill $out

set +x
