#!/bin/bash
export ANSIBLE_LOG_PATH=/pkg_repo/data/jobs/033f0fee-affa-4763-a720-3faaf23548a2/real_time_playbook.log
export ANSIBLE_RETRY_FILES_SAVE_PATH=/pkg_repo/data/jobs/033f0fee-affa-4763-a720-3faaf23548a2
export ANSIBLE_SSH_CONTROL_PATH='~/.ansible/cp/3df55497-a53f-4e7e-8a51-ee07e41b7e08-ssh-%%h-%%p-%%r'
sh autoInitialization.sh InitialVM >> /pkg_repo/data/jobs/033f0fee-affa-4763-a720-3faaf23548a2/playbook.log 2>&1; cmd_result=$?
echo $cmd_result > /pkg_repo/data/jobs/033f0fee-affa-4763-a720-3faaf23548a2/playbook.result
if [ $cmd_result -ne 0 ];then
  exit 1
fi
