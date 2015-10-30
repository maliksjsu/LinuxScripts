if [ $# -eq 0 ] 
then
   echo ""
   echo "ERROR   : Missing argument - CPU Frequency (in Hertz)!!!"
   echo "Syntax  : $0 cpu_frequency"
   echo "Example : $0 1600000"
   echo "Usage   : To set a constant operating CPU frequency for device."
   echo ""
   exit 1
fi

export scaling_governor=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`
export scaling_max_freq=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq`
export scaling_min_freq=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq`

echo "CPU frequency scaling governor currently set to: ${scaling_governor}"
echo "CPU maximum scaling frequency currently set to : ${scaling_max_freq}"
echo "CPU minimum scaling frequency currently set to : ${scaling_min_freq}"

echo "Changing scaling governor to maintain constant CPU speed..."
echo userspace > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
export scaling_governor=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`
echo "CPU frequency scaling governor NOW set to: ${scaling_governor}"

echo "Setting max CPU frequency to $1 Hz..."
echo $1 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo "Setting min CPU frequency to $1 Hz..."
echo $1 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

echo "CPU frequency has been set to be constant at $1 Hz"

