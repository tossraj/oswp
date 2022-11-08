#!/bin/sh

DIRECTORY='/usr/local/bin/oswp';

chmod +x oswp.sh
mv oswp.sh $DIRECTORY

if [ -d "$DIRECTORY" ]; then
  echo "[OK] oswp script updated ..."
else  
  echo "[OK] oswp script installed ..."
fi

cd ..
rm -rf oswp/
