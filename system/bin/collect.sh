#!/system/xbin/sh
# kendon's collect symptoms script for android, v1.0
SERVICE=01collect
LOGTIME=120
LOGDIR=/dev/symptoms
BB=/system/xbin/busybox
TARFILE=/sdcard/symptoms-$($BB date +%Y-%m-%d_%H-%M-%S).tgz

# no need to edit below
SYSTEM=$($BB mount|$BB grep "/system "|$BB awk '{ print $1 }')
# here we go
case $1 in
  -i|--install)
    $BB mount | $BB grep "/system " | $BB grep -q rw || $BB mount -o remount,rw $SYSTEM /system #remount RW

    $BB echo -e "#!/system/bin/sh\n/system/bin/collect.sh --run &\n/system/bin/collect.sh --uninstall" > /system/etc/init.d/$SERVICE
    $BB chown 0:2000 /system/etc/init.d/$SERVICE ; $BB chmod 755 /system/etc/init.d/$SERVICE
    $BB mount | $BB grep "/system " | $BB grep -q ro || $BB mount -o remount,ro $SYSTEM /system #remount RO
    $BB echo "collect symptoms service is now installed for the next reboot"
  ;;
  -u|--uninstall)
    $BB mount | $BB grep "/system " | $BB grep -q rw || $BB mount -o remount,rw $SYSTEM /system #remount RW
    [ -f /system/etc/init.d/$SERVICE ] && rm /system/etc/init.d/$SERVICE
    $BB mount | $BB grep "/system " | $BB grep -q ro || $BB mount -o remount,ro $SYSTEM /system #remount RO
    $BB echo "collect symptoms service has been removed"
  ;;
  -c|--collect|--run)
    $BB echo "collect symptoms starting at $(date +%Y-%m-%d_%H-%M-%S)"
    [ -e $LOGDIR ] && $BB rm -r $LOGDIR
    $BB mkdir $LOGDIR
    case $1 in
      --run)
        # run logcat for $LOGTIME seconds during boot-up
        $BB date > /dev/symptoms/logcat.txt
        /system/bin/logcat -f /dev/symptoms/logcat.txt & LPID=$!
        $BB sleep $LOGTIME
        $BB kill $LPID
        $BB mount | $BB grep "/system " | $BB grep -q ro || $BB mount -o remount,ro $SYSTEM /system
      ;;
      *)
        # otherwise dump the current buffer and exit
        /system/bin/logcat -d -f /dev/logcat.txt
      ;;
    esac
    [ -e /proc/config.gz ] && $BB zcat /proc/config.gz > $LOGDIR/config
    /system/bin/toolbox getprop > $LOGDIR/getprop 2>&1
    /system/xbin/iptables -L > $LOGDIR/iptables 2>&1
    $BB cp /system/build.prop $LOGDIR/
    $BB cp /init.* $LOGDIR/
    $BB ps w > $LOGDIR/ps 2>&1
    $BB top -b -n 1 > $LOGDIR/top 2>&1
    $BB netstat -rn > $LOGDIR/netstat 2>&1
    $BB ifconfig -a > $LOGDIR/ifconfig 2>&1
    $BB uname -a > $LOGDIR/uname
    $BB echo $PATH > $LOGDIR/PATH 2>&1
    $BB mount > $LOGDIR/mount 2>&1
    $BB df > $LOGDIR/df 2>&1
    # some ls's for files, links, permissions etc.
    $BB ls -alR /cache > $LOGDIR/lsR-cache 2>&1
    $BB ls -alR /data > $LOGDIR/lsR-data 2>&1
    $BB ls -alR /system > $LOGDIR/lsR-system 2>&1
    # that's it, create the archive
    cd $LOGDIR
    $BB tar -cz -f /dev/symptoms.tgz *
    cd /
    $BB rm -r $LOGDIR
    if [ $($BB mount | grep "/sdcard " | wc -l) -lt 1 ] ; then
      # if sdcard isn't mounted we mount it, put the file on it and unmount
      $BB mount -t vfat /dev/block/mmcblk0p1 /sdcard
      $BB cp /dev/symptoms.tgz $TARFILE && $BB rm /dev/symptoms.tgz
      $BB umount /sdcard
    else
      $BB cp /dev/symptoms.tgz $TARFILE && $BB rm /dev/symptoms.tgz
    fi
    $BB echo "symptoms file: $TARFILE"
    $BB echo "collect symptoms finished at $(date +%Y-%m-%d_%H-%M-%S)"
  ;;
esac

exit 0
