Initial具有以下功能：

1.环境检查：获取虚拟机资源后，检查cpu、内存、磁盘和ip的信息是否与申请的信息一致（回显以上信息，仍需人工确认）；
2.创建业务账户；
3.挂载磁盘（支持对某块磁盘分区、制作文件系统以及挂载磁盘）；
4.设置主机名；
5.设置DNS；
6.设置NTP；
7.最终检查：自动化部署后检查文件系统、DNS、NTP和主机名信息;
8.更新密码：更改远程主机用户密码
9.初始化虚拟机：完成创建业务账户，挂载磁盘，设置主机名，设置DNS,设置DNS的功能，每个功能有对应的开关来选择是否执行对应操作；
10.删除账户：可删除之前创建的业务账户；

autoInitialization.zip是支持DMK的包，可以直接上传至DMK，提供可视化界面，与服务升级操作类似。
deploy.zip是相应的playbook，如果熟悉ansible可以直接使用

##
##“配置文件”说明：
##
---

```
version: 1.1.0	此工具版本，无需关注
user_name: ces	业务账号用户名
user_group: ces	业务账号组名
user_passwd: $5$CeS$j055UbwJSKFbh6PYovfNNMJVeXlYBDm7FwlqvSYrD55	业务账户密码，在ansible主机使用python -c 'import crypt; print crypt.crypt("your_password", "$5$your_salt")'生成，这里salt字符集为[a–zA–Z0–9./].这里使用的密码是Huawe@123.
tmp_dir: '/tmp/root'	无需关注

dns: 		dns的ip地址，数组形式
  - 1.1.1.1		
  - 2.2.2.2

oldntp:	以前dns的ip地址，数组形式，如果初次设置dns，无需关注
  - 1.1.1.1

ntp: ntp的ip地址，数组形式
  - 1.1.1.1
  - 2.2.2.2

target_disk: xvde需要操作的磁盘
fs_type: 'ext3'	创建文件系统的类型
fs_params: ''	创建文件系统的参数，例如块大小、log大小等
mount_mapping:	操作磁盘的分区信息，disk_size为分区大小，单位为GB；disk_index为分区顺序，1即是/dev/xvde1；mount_point为挂载点；支持数组
  - {disk_size: 20, disk_index: 1, mount_point: '/var/log/ces'}
  - {disk_size: DEFAULT, disk_index: 2, mount_point: '/opt'}
```

##

##“节点配置文件”说明：
##
```
[base:children]
apiservice

[base:vars]
ansible_ssh_user=root	root用户访问，需要获取root用户密码，并在DMK上配置

[apiservice]
I-CES-APISVR01 ansible_ssh_host=1.1.1.1	第一列为hostname，第二列为ip
```


## 设置ntp

+ 配置设置节点的user_name，user_group, user_passwd(明文密码)
+ 设置正确ntp的服务器地址
+ 设置正确的hosts
+ 执行