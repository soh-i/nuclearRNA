#!/bin/sh

set -e

# SQLite DB name
db=$1

sqlite3 $1 <<END
.mode tabs
create table dmBED(chr text, pos integer, depth integer);
.import ./test.bed dmBED
END

echo "Finished storing BED to SQLite3";
