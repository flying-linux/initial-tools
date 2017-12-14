#!/bin/bash

devices=(
    {% for device in mount_mapping %}
    '/dev/{{target_disk}}{{device.disk_index}}'
    {% endfor %}
)
cmds=''
prefix='mkfs -t {{fs_type}} {{fs_params}}'

for device in ${devices[@]}
do
    cmds+="$prefix $device && "
done

len={{'${#cmds}'}}
cmds=${cmds::$len-3}

eval $cmds

if [ $? -ne 0 ]; then
    exit 1
fi

exit 0