#!/system/bin/sh
SYSTEM=$(mount|grep "/system "|awk '{ print $1 }')
DATA=$(mount|grep "/data "|awk '{ print $1 }')

# remount rw if necessary
mount | grep "/system " | grep -q rw || mount -o remount,rw $SYSTEM /system

# su fixes
[ -f /system/bin/su ] && chmod 04755 /system/bin/su
[ -f /system/xbin/su ] && chmod 04755 /system/xbin/su
[ ! -e /system/bin/su ] && [ -f /system/xbin/su ] && ln -s /system/xbin/su /system/bin/su
[ ! -e /system/xbin/su ] && [ -f /system/bin/su ] && ln -s /system/bin/su /system/xbin/su

# create symlinks for modules if not exists
[ ! -e /system/lib/modules/$(uname -r) ] && ln -s /system/lib/modules /system/lib/modules/$(uname -r)

# prepare for betterzipalign
touch /system/app/*.apk
touch /system/framework/*.apk
touch /data/app*/*.apk
rm -f /data/zipalign.log 2>/dev/null

# remount ro if necessary
mount | grep "/system " | grep -q ro || mount -o remount,ro $SYSTEM /system

exit 0
