#!/bin/bash

ansible-playbook roles/user/tasks/passwd_user.yml -i hosts -k -K

if [ $? -ne 0 ]; then
    exit 1
fi

exit 0