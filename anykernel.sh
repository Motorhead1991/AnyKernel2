# AnyKernel 2.0 Ramdisk Mod Script 
# osm0sis @ xda-developers

## AnyKernel setup
# EDIFY properties
kernel.string=B14CKB1RD-v1.0 grouper - motorhead1991
do.devicecheck=1
do.initd=0
do.modules=0
do.cleanup=1
device.name1=grouper
device.name2=Nexus 7
device.name3=
device.name4=
device.name5=

# shell variables
block=/dev/block/platform/sdhci-tegra.3/by-name/LNX;

## end setup


## AnyKernel methods (DO NOT CHANGE)
# set up extracted files and directories
ramdisk=/tmp/anykernel/ramdisk;
bin=/tmp/anykernel/tools;
split_img=/tmp/anykernel/split_img;
patch=/tmp/anykernel/patch;
checkfile=`sha1sum "zImage" | sed 's/  zImage//'`

chmod -R 755 $bin;
mkdir -p $ramdisk $split_img;
cd $ramdisk;

OUTFD=`ps | grep -v "grep" | grep -oE "update(.*)" | cut -d" " -f3`;
ui_print() { echo "ui_print $1" >&$OUTFD; echo "ui_print" >&$OUTFD; }

# dump boot and extract ramdisk
dump_boot() {
  dd if=$block of=/tmp/anykernel/boot.img;
  $bin/unpackbootimg -i /tmp/anykernel/boot.img -o $split_img;
  if [ $? != 0 ]; then
    ui_print " "; ui_print "Dumping/unpacking image failed. Aborting...";
    echo 1 > /tmp/anykernel/exitcode; exit;
  fi;
  gunzip -c $split_img/boot.img-ramdisk.gz | cpio -i;
}

# repack ramdisk then build and write image
write_boot() {
  cd $split_img;
  cmdline=`cat *-cmdline`;
  board=`cat *-board`;
  base=`cat *-base`;
  pagesize=`cat *-pagesize`;
  kerneloff=`cat *-kerneloff`;
  ramdiskoff=`cat *-ramdiskoff`;
  tagsoff=`cat *-tagsoff`;
  if [ -f *-second ]; then
    second=`ls *-second`;
    second="--second $split_img/$second";
    secondoff=`cat *-secondoff`;
    secondoff="--second_offset $secondoff";
  fi;
  if [ -f /tmp/anykernel/zImage ]; then
    kernel=/tmp/anykernel/zImage;
  else
    kernel=`ls *-zImage`;
    kernel=$split_img/$kernel;
  fi;
  if [ -f /tmp/anykernel/dtb ]; then
    dtb="--dt /tmp/anykernel/dtb";
  elif [ -f *-dtb ]; then
    dtb=`ls *-dtb`;
    dtb="--dt $split_img/$dtb";
  fi;
  cd $ramdisk;
if [ "$checkfile" = "9c6b057a2b9d96a4067a749ee3b3b0158d390cf1" ]; then
  find . | cpio -H newc -o | gzip > /tmp/anykernel/ramdisk-new.cpio.gz;
  $bin/mkbootimg --kernel $kernel --ramdisk /tmp/anykernel/ramdisk-new.cpio.gz $second --cmdline "$cmdline" --board "$board" --base $base --pagesize $pagesize --kernel_offset $kerneloff --ramdisk_offset $ramdiskoff $secondoff --tags_offset $tagsoff $dtb --output /tmp/anykernel/boot-new.img;
  if [ $? != 0 -o `wc -c < /tmp/anykernel/boot-new.img` -gt `wc -c < /tmp/anykernel/boot.img` ]; then
    ui_print " "; ui_print "Repacking image failed. Aborting...";
    echo 1 > /tmp/anykernel/exitcode; exit;
  fi;
  dd if=/tmp/anykernel/boot-new.img of=$block;
else
    ui_print "SHA1 sum does not match"
    echo 2 > /tmp/anykernel/exitcode; exit;
fi
}

# backup_file <file>
backup_file() { cp $1 $1~; }

# replace_string <file> <if search string> <original string> <replacement string>
replace_string() {
  if [ -z "$(grep "$2" $1)" ]; then
      sed -i "s;${3};${4};" $1;
  fi;
}

# insert_line <file> <if search string> <before/after> <line match string> <inserted line>
insert_line() {
  if [ -z "$(grep "$2" $1)" ]; then
    case $3 in
      before) offset=0;;
      after) offset=1;;
    esac;
    line=$((`grep -n "$4" $1 | cut -d: -f1` + offset));
    sed -i "${line}s;^;${5};" $1;
  fi;
}

# replace_line <file> <line replace string> <replacement line>
replace_line() {
  if [ ! -z "$(grep "$2" $1)" ]; then
    line=`grep -n "$2" $1 | cut -d: -f1`;
    sed -i "${line}s;.*;${3};" $1;
  fi;
}

# remove_line <file> <line match string>
remove_line() {
  if [ ! -z "$(grep "$2" $1)" ]; then
    line=`grep -n "$2" $1 | cut -d: -f1`;
    sed -i "${line}d" $1;
  fi;
}

# prepend_file <file> <if search string> <patch file>
prepend_file() {
  if [ -z "$(grep "$2" $1)" ]; then
    echo "$(cat $patch/$3 $1)" > $1;
  fi;
}

# append_file <file> <if search string> <patch file>
append_file() {
  if [ -z "$(grep "$2" $1)" ]; then
    echo -ne "\n" >> $1;
    cat $patch/$3 >> $1;
    echo -ne "\n" >> $1;
  fi;
}

# replace_file <file> <permissions> <patch file>
replace_file() {
  cp -fp $patch/$3 $1;
  chmod $2 $1;
}

## end methods


## AnyKernel permissions
# set permissions for included files
#chmod -R 755 $ramdisk
#chmod 644 $ramdisk/sbin/media_profiles.xml


## AnyKernel install
dump_boot;

# begin ramdisk changes

# init.rc
#backup_file init.rc;
#replace_string init.rc "cpuctl cpu,timer_slack" "mount cgroup none /dev/cpuctl cpu" "mount cgroup none /dev/cpuctl cpu,timer_slack";
#append_file init.rc "run-parts" init;

# init.tuna.rc
#backup_file init.qcom.rc;
#replace_line init.qcom.rc "write /sys/block/mmcblk0/queue/read_ahead_kb 512" "	write /sys/block/mmcblk0/queue/read_ahead_kb 2048"
#replace_line init.qcom.rc "write /sys/block/mmcblk1/queue/read_ahead_kb 512" "	write /sys/block/mmcblk1/queue/read_ahead_kb 2048"
#remove_line init.qcom.rc "start thermald"

# init.superuser.rc
#if [ -f init.superuser.rc ]; then
#  backup_file init.superuser.rc;
#  replace_string init.superuser.rc "Superuser su_daemon" "# su daemon" "\n# Superuser su_daemon";
#  prepend_file init.superuser.rc "SuperSU daemonsu" init.superuser;
#else
#  replace_file init.superuser.rc 750 init.superuser.rc;
#  insert_line init.rc "init.superuser.rc" after "on post-fs-data" "    import /init.superuser.rc\n";
#fi;

# fstab.tuna
#backup_file fstab.tuna;
#replace_line fstab.tuna "/by-name/system" "/dev/block/platform/omap/omap_hsmmc.0/by-name/system    /system             ext4      nodev,noatime,nodiratime,barrier=0,data=writeback,noauto_da_alloc,discard    wait";
#replace_line fstab.tuna "/by-name/cache" "/dev/block/platform/omap/omap_hsmmc.0/by-name/cache     /cache              ext4      nosuid,nodev,noatime,nodiratime,errors=panic,barrier=0,nomblk_io_submit,data=writeback,noauto_da_alloc    wait,check";
#replace_line fstab.tuna "/by-name/userdata" "/dev/block/platform/omap/omap_hsmmc.0/by-name/userdata  /data               ext4      nosuid,nodev,noatime,errors=panic,nomblk_io_submit,data=writeback,noauto_da_alloc    wait,check,encryptable=/dev/block/platform/omap/omap_hsmmc.0/by-name/metadata";
#append_file fstab.tuna "usbdisk" fstab;

# end ramdisk changes

write_boot;

## end install

