echo 0 > /sys/devices/system/cpu/$1/online
cat /sys/devices/system/cpu/$1/online

