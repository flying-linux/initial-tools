#!/bin/bash

declare DISK_NAME=$1
declare -A MOUNT_MAP
tmp=$2
tmp1=${tmp#*\"}
tmp2=${tmp1%%\"*}
eval "MOUNT_MAP=($tmp2)"
MOUNT_NUM=0
for key in ${!MOUNT_MAP[@]}
do
        MOUNT_DIR[$MOUNT_NUM]=$key
        ((MOUNT_NUM+=1))
done
if [ $MOUNT_NUM -eq 0 ]; then
echo "[ERROR]no disk need mount!"
elif [ $MOUNT_NUM -eq 1 ]; then
echo "/tmp/partitions_and_mount.sh $DISK_NAME yes $MOUNT_NUM DEFAULT DEFAULT DEFAULT  no ${MOUNT_DIR[0]}"
/tmp/partitions_and_mount.sh $DISK_NAME yes $MOUNT_NUM DEFAULT DEFAULT DEFAULT  no ${MOUNT_DIR[0]}
elif [ $MOUNT_NUM -eq 2 ]; then
echo "/tmp/partitions_and_mount.sh $DISK_NAME yes $MOUNT_NUM ${MOUNT_MAP[${MOUNT_DIR[0]}]} DEFAULT DEFAULT  no ${MOUNT_DIR[0]} ${MOUNT_DIR[1]}"
/tmp/partitions_and_mount.sh $DISK_NAME yes $MOUNT_NUM ${MOUNT_MAP[${MOUNT_DIR[0]}]} DEFAULT DEFAULT  no ${MOUNT_DIR[0]} ${MOUNT_DIR[1]}
elif [ $MOUNT_NUM -eq 3 ]; then
echo "/tmp/partitions_and_mount.sh $DISK_NAME yes $MOUNT_NUM ${MOUNT_MAP[${MOUNT_DIR[0]}]} ${MOUNT_MAP[${MOUNT_DIR[1]}]} DEFAULT  no ${MOUNT_DIR[0]} ${MOUNT_DIR[1]} ${MOUNT_DIR[2]}"
/tmp/partitions_and_mount.sh $DISK_NAME yes $MOUNT_NUM ${MOUNT_MAP[${MOUNT_DIR[0]}]} ${MOUNT_MAP[${MOUNT_DIR[1]}]} DEFAULT  no ${MOUNT_DIR[0]} ${MOUNT_DIR[1]} ${MOUNT_DIR[2]}
else
echo "[ERROR]the mount number exceed limit!"
fi

exit 0