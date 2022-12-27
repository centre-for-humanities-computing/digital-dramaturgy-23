#!/bin/bash
SCRIPT_DIR=$(dirname "$(readlink -f -- ${BASH_SOURCE[0]})")


datadir=${1:-$SCRIPT_DIR}
outputdir=${2:-$SCRIPT_DIR/json}

mkdir -p "$outputdir"
# Run xslt on all page files
for f in "$datadir/"*.page; do
  outputname="$(basename $f).jsonl"
#  xsltproc stripSeq.xslt "$f" > "$outputdir/$outputname.stripped.xml"
  xsltproc stripSeq.xslt "$f" | xsltproc tei2jsonl.xslt - > "$outputdir/$outputname"
done
