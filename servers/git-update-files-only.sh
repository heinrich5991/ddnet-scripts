#!/usr/bin/env zsh
rni 10 3

cd /home/teeworlds/servers

jq . serverlist.json > /dev/null || (echo "Invalid serverlist.json" && exit 1)
(set +x; ./config_store_d maps/*.map) > /dev/null 2>/dev/null

for i in /home/teeworlds/servers /home/teeworlds/servers/halloween; do
  cd $i
  rm -f maps7.log
  find maps -name '*.map' | while read map; do
    map7="maps7/${map:t}"
    if [ ! -e "$map7" -o "$map" -nt "$map7" ]; then
      /home/teeworlds/servers/map_convert_07 "$map" "$map7.tmp" >> maps7.log && /home/teeworlds/servers/map_optimize "$map7.tmp" "../$map7" && rm -- "$map7.tmp" && git add "$map7" && echo "Converted $map to $map7"
    fi
  done
done

cd /home/teeworlds/servers

set -x
git commit -a -m "upd"
git push
echo -e "\e[1;32mMAIN updated successfully\e[0m"

(ni 12 3 nim-scripts/mapdl; rsync -avP --exclude compilations/ /var/www-maps chn11.ddnet.org:/var/) &

set +x
LOGFILE=git-update-files-only.$$.log
rm -f $LOGFILE
for i in `cat all-locations`; do
  (timeout 120 ssh $i.ddnet.org "cd servers;ni 10 3 git pull || ni 10 3 git pull || ni 10 3 git pull"
  if [ $? -eq 0 ]; then
    echo -e "\e[1;32m$i updated successfully\e[0m" >> $LOGFILE
  else
    echo -e "\e[1;33mUpdating $i failed\e[0m" >> $LOGFILE
  fi) &
done

wait
echo -e "\e[1;31m$(grep successfully $LOGFILE | wc -l)/$(wc -w < all-locations) servers updated successfully\e[0m"
grep failed $LOGFILE || true
rm $LOGFILE
