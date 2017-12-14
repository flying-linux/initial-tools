#!/bin/bash

# Copyright (c) 2012-2016 Public Cloud Solution, Huawei, China.

declare CURDIR=`dirname $0`
declare CURPATH=`readlink -f $CURDIR`
declare PM_LOG="$CURPATH/pm_log"
declare DISK_NAME=$1
declare ANS1=$2
declare DISK_COUNT=$3
declare DISK_SIZE_1=$4
declare DISK_SIZE_2=$5
declare DISK_SIZE_3=$6
declare ANS2=$7
declare DIR_1=$8
declare DIR_2=$9
declare DIR_3=${10}
function backup_old_file()
{
	disk_num=1
	while (( $disk_num <= $DISK_COUNT )) 
	do
		dir_n=DIR_$disk_num
		eval dir=\$$dir_n
		if [[ -d $dir ]];then
			rm -rf /dir_${disk_num}
			mkdir -p /dir_${disk_num}
			cp -af $dir/* /dir_${disk_num}/  >> $PM_LOG 2>&1
		fi
		let ++disk_num
	done
	cp -a /etc/fstab /etc/fstab.bak
}

function delete_old_partitions()
{
	old_disk_num=`fdisk -l $DISK_NAME |grep  $DISK_NAME  | awk -F ' ' '{print $1}'|wc -l`
	while (( $old_disk_num > 1 ))
        do
		let --old_disk_num
		fuser -km $DISK_NAME$old_disk_num >> $PM_LOG 2>&1
		umount -l $DISK_NAME$old_disk_num >> $PM_LOG 2>&1
        done
    dd if=/dev/zero of=$DISK_NAME bs=1M count=1
	sed -i "/^${DISK_NAME//\//\\/}/d" /etc/fstab
}

function create_partitions_for_disk()
{
	while :
	do
		if [[ $DISK_NAME =~ /dev/* ]];then
			if [ -b $DISK_NAME ];then
				if [ $ANS1 == yes ];then
					case $DISK_COUNT in
					1)
					if [[ (-n $DISK_SIZE_1) &&  (-n $DIR_1) ]];then
						echo   "n
								p
								1
								
								
								w" | fdisk $DISK_NAME | grep -q "Value out of range" >> $PM_LOG 2>&1 
								if [ $? -ne 1 ]; then
									echo "The disk size is out of range!" >> $PM_LOG 2>&1  
									exit 1
								fi
								echo -e "\n"
								fdisk -l $DISK_NAME | grep  "^$DISK_NAME[1-9]\{1,\}" >> $PM_LOG 2>&1 
								if [ $? -ne 1 ]; then
									echo -e "create partitions successful" >> $PM_LOG 2>&1 
									break
								else
									fdisk -l $DISK_NAME >> $PM_LOG 2>&1 
									echo "there has something wrong!" >> $PM_LOG 2>&1
									exit 1
								fi
					else
						echo "input error!" 
						exit 1
					fi
					;;
					2) 
					if [[ (-n $DISK_SIZE_1) &&  ($DISK_SIZE_1 =~ 'G') && (-n $DIR_1)]];then
						if [[ (-n $DISK_SIZE_2) &&  (-n DIR_2) ]];then
							echo   "n
									p
									1
									
									+$DISK_SIZE_1
									n
									p
									2
									
									
									w" | fdisk $DISK_NAME | grep -q "Value out of range" >> $PM_LOG 2>&1 
								if [ $? -ne 1 ]; then
									echo "The disk size is out of range!" >> $PM_LOG 2>&1 
									exit 1
								fi
								echo -e "\n"
								fdisk -l $DISK_NAME | grep  "^$DISK_NAME[1-9]\{1,\}" >> $PM_LOG 2>&1 
								if [ $? -ne 1 ]; then
									echo -e "create partitions \033[32msuccessful\033[0m" >> $PM_LOG 2>&1 
									break
								else
									fdisk -l $DISK_NAME >> $PM_LOG 2>&1 
									echo "there has something wrong!" >> $PM_LOG 2>&1
									exit 1
								fi
						else
							echo "input error!" 
							exit 1
						fi
					else
						echo "input error!" 
						exit 1
					fi
					;;
					3) 
					if [[ (-n $DISK_SIZE_1) &&  ($DISK_SIZE_1 =~ 'G') && (-n $DIR_1)]];then
						if [[ (-n $DISK_SIZE_2) &&  ($DISK_SIZE_2 =~ 'G') && (-n $DIR_2)]];then
							if [[ (-n $DISK_SIZE_3) &&  (-n $DIR_3) ]];then 
								echo   "n
										p
										1
										
										+$DISK_SIZE_1
										n
										p
										2
										
										+$DISK_SIZE_2
										n
										p
										3
										
										
										w" | fdisk $DISK_NAME | grep -q "Value out of range" >> $PM_LOG 2>&1 
									if [ $? -ne 1 ]; then
										echo "The disk size is out of range!" >> $PM_LOG 2>&1
										exit 1
									fi
								echo -e "\n"
								fdisk -l $DISK_NAME | grep "^$DISK_NAME[1-9]\{1,\}" >> $PM_LOG 2>&1 
								if [ $? -ne 1 ]; then
									echo -e "create partitions successful" >> $PM_LOG 2>&1 
									break
								else
									fdisk -l $DISK_NAME >> $PM_LOG 2>&1 
									echo "there has something wrong!" >> $PM_LOG 2>&1
									exit 1
								fi
							else
							    echo "there has something wrong!" 
								exit 1
							fi
						else
							echo "there has something wrong!" 
							exit 1
						fi
					else
						echo "there has something wrong!" 
						exit 1
					fi
					;;
					*)
					echo "there has something wrong!" 
					exit 1
					;;
					esac
				elif [ $ANS1 == no ];then
					echo "exit...." 
					exit 1
				else
					echo "there has something wrong!" 
					exit 1
				fi
			else
				echo "$DISK_NAME does not exist,please input a exist device file!" >> $PM_LOG 2>&1
				exit 1
			fi
		else
			echo "$DISK_NAME is not a device file!" >> $PM_LOG 2>&1
			exit 1
		fi     
	done

}
function exist_swap()
{
	if [ $ANS2 == yes ];then
		echo   "t
				1
				82
				w" | fdisk $DISK_NAME | grep -q "Linux swap / Solaris" >> $PM_LOG 2>&1 
				if [ $? -ne 1 ]; then
					echo -e "create swap successful" >> $PM_LOG 2>&1 
					disk_num=1
					sleep 3
					mkswap $DISK_NAME$disk_num >> $PM_LOG 2>&1
					if [[ $? -ne 0 ]];then
						fdisk -l $DISK_NAME >> $PM_LOG 2>&1 
						free -m >> $PM_LOG 2>&1 
						echo "there has something wrong when do mkswap!" >> $PM_LOG 2>&1 
						exit 1
					fi
					sleep 3
					swapon $DISK_NAME$disk_num >> $PM_LOG 2>&1
					if [[ $? -ne 0 ]];then
						fdisk -l $DISK_NAME >> $PM_LOG 2>&1 
						free -m >> $PM_LOG 2>&1 
						echo "there has something wrong when do swapon!" >> $PM_LOG 2>&1 
						exit 1
					fi
					free -m >> $PM_LOG 2>&1 
					echo "$DISK_NAME$disk_num swap swap defaults 0 0" >> /etc/fstab
					disk_num=2
				else
					fdisk -l $DISK_NAME >> $PM_LOG 2>&1 
					echo "there has something wrong!" >> $PM_LOG 2>&1 
					exit 1
				fi
	elif [ $ANS2 == no ];then
		disk_num=1
	fi
}
function mount_disk_to_dir()
{
	while (( $disk_num <= $DISK_COUNT )) 
	do
        	dir_n=DIR_$disk_num
		eval dir=\$$dir_n		
		if [[ $dir = "/var" ]];then
			echo "it can not be /var!" >> $PM_LOG 2>&1
			continue
		fi
		if [[ -d $dir ]];then
			if  [[ -b "$DISK_NAME$disk_num" ]];then
                                mkfs.ext3 "$DISK_NAME$disk_num" >> $PM_LOG 2>&1
                        else
                                echo "$DISK_NAME$disk_num does not exist!" >> $PM_LOG 2>&1
                                exit 1
			fi
		else
			mkdir -p $dir
			if  [[ -b "$DISK_NAME$disk_num" ]];then
				mkfs.ext3 "$DISK_NAME$disk_num" >> $PM_LOG 2>&1 
			else
				echo "$DISK_NAME$disk_num does not exist!" >> $PM_LOG 2>&1 
				exit 1
			fi
		fi
		mount -t ext3 $DISK_NAME$disk_num $dir >> $PM_LOG 2>&1		
		if [[ -d /dir_$disk_num ]];then
			cp -af /dir_$disk_num/* $dir/ >> $PM_LOG 2>&1
		fi
		grep  " $dir " /etc/fstab >> $PM_LOG 2>&1
                if [[ $? -ne 1 ]];then
					disk_name=$(grep  " ${dir} " /etc/fstab | awk -F ' ' '{print $1}')
					sed -i "/${disk_name//\//\\/}/ s/^/#/" /etc/fstab
					sed -i "/${disk_name//\//\\/}/a $DISK_NAME$disk_num $dir ext3 nodev,nosuid,errors=panic 1 2" /etc/fstab
                    mount -a >> $PM_LOG 2>&1
                else
                    echo "$DISK_NAME$disk_num $dir ext3 nodev,nosuid,errors=panic 1 2" >> /etc/fstab
                    mount -a >> $PM_LOG 2>&1
                fi
		rm -rf /dir_${disk_num} >> $PM_LOG 2>&1
		let ++disk_num
	done
}
main()
{
	echo "--------Backup the file----------------------------"
	backup_old_file
		sleep 3
	echo "----------delete old partitions--------------------"
	delete_old_partitions
        echo "--------Begin to create partitions for disk--------" 
        create_partitions_for_disk
		sleep 3
        echo "---------------if need create swap----------------" 
        exist_swap
		sleep 3
        echo "------Begin to mount disk to document folder------" 
        mount_disk_to_dir
        echo "-------------------Show  Result-------------------" 
        df -hl 
        echo "-----------------------End------------------------" 
        return 0

}
main 
