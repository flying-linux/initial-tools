#!/bin/bash
backup_dir=/mnt
parted_unit=GiB
script_proc_num=$$
default_fs_type=ext3
fstab_file=/etc/fstab
tmp_mount_path=/mnt/tmp_mount_path
sshd_proc_num=$(lsof |awk '$1=="sshd"&&$10~/LISTEN/{print $2 }')
os_type="$(awk -F'[()]' '{split($(NF-4),a," ");print toupper(a[1])}' /proc/version)"
Check_parameters ()
{
case $1 in
normal|force|force_kill)
    ;;
*)
    echo -e "\033[31m Illegal mode $1, mode should be normal or force \033[0m"
    echo -e "\033[34m Usage: sh $(basename $0) [normal|force mount-point mount-size fs-type ] \033[0m"
    echo -e "\033[33m    eg: sh $(basename $0) normal /var/log 40 ext4\n    eg: sh $(basename $0) force /var/log 40 ext4 /opt 100% ext4\033[0m"
    exit 1
esac
shift
until [ $# -lt 3 ]
do
    param1=$(echo $1|sed -r 's#(/\S+)+/?##')
    if [ x$param1 != x"" ];then
        echo -e "\033[31m Illegal mount-point $1,mount-point should be an absolute path \033[0m"
        exit 2
    fi
    param2=$(echo $2|sed -r 's#^[1-9][0-9]*(\.[0-9]+)?%?$##')
    if [ x$param2 != x"" ];then
        echo -e "\033[31m Illegal size $2,size should be number or percentage  \033[0m"
        exit 3
    fi
    case  $3 in
    btrfs|cramfs|ext2|ext3|ext4|fat|minix|msdos|vfat|xfs)
        ;;
    *)
        echo -e "\033[31m Illegal fs-type $3, fs-type should be one of "btrfs","cramfs","ext2","ext3","ext4","fat","minix","msdos","vfat",or "xfs" \033[0m"
        exit 4
    esac
    shift 3
done
}
Check_parameters $@

Backup_Restore_partition_table ()
{
    local dev_name=$(echo ${unparted_dev_name##*/})
case $1 in
backup)
    echo -e "\033[32m Backup partition table and fstable for $unparted_dev_name  \033[0m"
    dd if=${unparted_dev_name} of=${backup_dir}/${dev_name}.partition_table bs=512 count=1
    \cp -f $fstab_file $backup_dir/ ;;
restore)
    echo -e "\033[32m Restore partition table and fstable for $unparted_dev_name \033[0m"
    dd if=${backup_dir}/${dev_name}.partition_table of=${unparted_dev_name} bs=512 count=1
    \cp -f $backup_dir/fstab $fstab_file
esac
}
##############
MountPartition ()
{
    mounted_size=$(df -m|awk -v z=$mount_point '$1~/\dev\/[a-z][a-z][b-z]?[b-z][1-9]/&&$6==z{print $2 }')
    if [ -n "$mounted_size" ];then
        Release_the_Catalog $mount_point
        umount $mount_point
        if [ $? != 0 ];then
            Release_the_Catalog $mount_point
	          sleep 1
            umount -f $mount_point
        fi
    fi
    sleep 2
    local P_name=$(echo ${p_name//\//\\/})
    local Mount_point=$(echo ${mount_point//\//\\/})
    sed -i -e  "/${P_name}/d" -e "/${Mount_point} /d"  ${fstab_file}
    echo "${p_name} ${mount_point} ${mount_fs_type} defaults,errors=panic 1 2" >> ${fstab_file}
}
##############
Transfer_Data()
{
    echo -e "\033[33m Transfer data for $mount_point Begin. \033[0m" 
    cd /tmp
    Release_the_Catalog $mount_point
    tar -cpf - -C  ${mount_point}  ./  |tar -xf - -C ${tmp_mount_path} 
	if [ $? != 0 ];then
            echo -e "\033[31m Transfer data for $mount_point Failed ,please reboot your system and try it again \033[0m"
	    Backup_Restore_partition_table restore
	    umount ${tmp_mount_path}
   	    exit 5
    else
            echo -e "\033[32m Transfer data for $mount_point Success! \033[0m" 
	fi
    mounted_size=$(df -m|awk -v z=$mount_point '$1~/\dev\/[a-z][a-z][b-z]?[b-z][1-9]/&&$6==z{print $2 }')
    if [ -n "$mounted_size" ];then
        Release_the_Catalog $mount_point
        umount $mount_point
    fi
    Release_the_Catalog ${tmp_mount_path}
    umount  ${tmp_mount_path}
    echo -e "\033[32m End Transfer data For $mount_point.\033[0m" 
}
##############
Release_the_Catalog ()
{
# Example: Release_the_Catalog /var/log
    get_process_list()
    {
     lsof $1|awk -v ssh_proc_num=$sshd_proc_num -v script_proc_num=$script_proc_num '$2!="PID"&&$2!=ssh_proc_num&&$2!=script_proc_num&&$1!="sshd"{print $2 }'|sort -un
    }
    process_list=$(get_process_list /opt)
    if [ -n  "$process_list" ];then
        kill $process_list &>/dev/null
        process_list=$(get_process_list /opt)
        if [ -n  "$process_list" -a $action == "force_kill" ];then
            kill -9 $process_list &>/dev/null
        fi
    fi
}
##############
mkfs_tmp_mount()
{
    echo -e "\033[33m Mkfs for $p_name Begin.\033[0m" 
    if [ ! -b "$p_name" ];then
        eval $(ls -l  $unparted_dev_name|awk -F"[ ,]" '{print "dev_major_id="$5,"dev_minor_id="$7}')
        partition_minor_id=$(echo "${p_num:-0} + $dev_minor_id"|bc)
        mknod  -m 0660 $p_name b $dev_major_id $partition_minor_id
        chown root:disk $p_name
    fi
    mkfs -t  $mount_fs_type  $p_name 
    if [ $? == 0 ];then
        echo -e "\033[32m Mkfs for $p_name Success.\033[0m"
        echo -e "\033[32m Mount $p_name temporarily on $tmp_mount_path .\033[0m"
        tmp_mounted_size=$(df -m|awk -v z=$tmp_mount_path '$1~/\dev\/[a-z][a-z][b-z]?[b-z][1-9]/&&$6==z{print $2 }')
        if [ -n "$tmp_mounted_size" ];then
           fuser -km $tmp_mount_path
           umount  $tmp_mount_path
        fi
        mount $p_name $tmp_mount_path -o errors=panic
    else
        Backup_Restore_partition_table restore
        echo -e "\033[31m mkfs for $p_name Faild.\n  please reboot the system and try it again \033[0m"
        exit 5
    fi
}
##############
Create_Partitions()
{
    if [ -z "${unparted_dev_name}" ];then
    {
        echo -e "\033[31m no available disk found. Please check and run again \033[0m"
        return 1
    }
    fi
    echo -e "\033[33m Create partition for $mount_point will Begin.\033[0m" 
    [[ $mount_size =~ % ]]&&end_flag=$mount_size||end_flag=$(echo "$start_flag + $mount_size"|sed -r 's/[a-zA-Z]+//g'|bc)$parted_unit
    parted -s ${unparted_dev_name}  mkpart primary $mount_fs_type $start_flag $end_flag
    if [ $? != 0 ];then
        echo -e "\033[31m Create partition Failed\033[0m"
        Backup_Restore_partition_table restore
        exit 10
    fi
    start_flag=$(parted ${unparted_dev_name} unit $parted_unit print|awk '/^[[:space:]]?[1-9][0-9]*\>/{print $3}'|sed '$!d')
    p_num=$(parted ${unparted_dev_name} unit $parted_unit print|awk '/^[[:space:]]?[1-9][0-9]*\>/{print $1}'|sed '$!d')
    if [ -z "$p_num" ];then
        echo -e "\033[31m Illegal parameters of partition number for variable p_num \033[0m"
        exit 11
    fi  
    p_name=${unparted_dev_name}${p_num}
    echo -e "\033[32m Create partition for $mount_point End.\033[0m"
    # force fresh the linux core to know the new partition
    echo -e "\033[33m Force to refresh partition table for kernel \033[0m" 
    partprobe &>/dev/null
    sleep 3
    partx ${unparted_dev_name} || partx $p_name
    sleep 3
}
##############
Get_Unparted_device()
{
    echo -e "\033[33m Begin to Get unparted device\033[0m" 
    local disk_list=$(parted -l 2>/dev/null|egrep -o '/dev/[a-z]{2}[b-z]{1,2}\>')
    if [ -z "$disk_list" ];then
        echo -e "\033[31m there is no extra disk, please insert a new one\033[0m"
        exit 0
    else
        for i in $disk_list
        do
            local isdisk_unparted=$(parted  $i print 2>&1|egrep -c '^[[:space:]]?[1-9][0-9]*\>')
            if  [ $isdisk_unparted == 0  ];then
                unparted_dev_list="$unparted_dev_list $i"
            fi
        done
        if [ -z "$unparted_dev_list" ];then
            echo -e "\033[31m The disk have no extra space,please insert new one\033[0m"
            exit 0
        else
            max_size=0
            for i in $unparted_dev_list
            do
                dev_size=`parted $i  print 2>/dev/null|awk '$1=="Disk"&&$2~/\/dev\/[a-z][a-z][b-z]?[b-z]:/{if($3~/GB/){coefficient=1000}else if($3~/MB/){coefficient=1};gsub(/[A-Z]/,"",$3);print $3*coefficient}'`
                if [ $(echo "${dev_size:-0} > $max_size "|bc) -eq 1 ];then
                    max_size=$dev_size
                    unparted_dev_name=$i
		    Backup_Restore_partition_table backup
                fi
            done
        fi
    fi
    parted -s ${unparted_dev_name}  mklabel msdos &>/dev/null
    start_flag=0
    local Unparted_dev=$(echo ${unparted_dev_name//\//\\/})
    sed -i  "/${Unparted_dev}/d"  ${fstab_file}
    echo -e "\033[33m End to get unparted device,unparted_dev_name=${unparted_dev_name}\033[0m" 
}

#############
Main_Process()
{
    Create_Partitions
    mkfs_tmp_mount
    Transfer_Data
    MountPartition
}
#############
Pre_Process()
{
    mkdir -p $tmp_mount_path
    if [ $os_type == 'SUSE' ];then
        service ntp  stop
        service cron stop
    else
        systemctl stop ntpd
        systemctl stop crond
    fi
    start_flag=0
    until [ $# -lt 3 ]
    do
        mount_point=$(echo $1|sed -r 's#/$##')
        mkdir -p  $mount_point
        mount_size=$2
        if [ $os_type == 'SUSE' ];then
            mount_fs_type=$default_fs_type
        else
            mount_fs_type=$3
        fi
        if [ $action == "normal" ];then
          Pre_Check
        else
          Main_Process
        fi
        shift 3
    done
    if [ $os_type == 'SUSE' ];then
      service ntp  restart
      service cron restart
      service sshd restart
    else
      systemctl restart crond
      systemctl restart ntpd
      systemctl restart sshd
    fi
    rmdir  ${tmp_mount_path}
    mount -a
    df -h
}
##############
Pre_Check()
{
    local mounted_size=$(df -m|awk -v z=$mount_point '$1~/\dev\/[a-z][a-z][b-z]?[b-z][1-9]/&&$6==z{print $2 }')
    if [ -z "$mounted_size" ];then
        echo -e "\033[33m Prepare for disk partition.\033[0m" 
        Main_Process
    else
        echo -e "\033[33m $mount_point directory has been already mounted\033[0m" 
    fi

}
case $1 in
normal)
Get_Unparted_device
action=$1
shift
Pre_Process $@ ;;
force|force_kill)
Get_Unparted_device
action=$1
shift
Pre_Process $@ ;;
*)
echo -e  "Usage: sh $(basename $0) [normal|force mount-point mount-size fs-type ]\n   eg: sh $shell_name normal /var/log 40 ext4"
esac
