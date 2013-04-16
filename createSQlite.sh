#!/bin/sh

set -e

if [ $# -ne 3 ]; then
    echo "./createSQL.sh <dbname.sqlite3> <in.bed> <table name>"
    exit 1
fi

db=$1
bed=$2
name=$3

sqlite3 ${db} <<END
.mode tabs
create table ${name}(chr text, pos integer, depth integer);
.import ${bed} ${name}
create index nameindex on ${name}(chr, pos, depth);
END
