echo "Setting up Android System for tracing..."
cd /data/scripts/
echo "Disabling EIP Randomization"
./eiprandomizeoff
echo "Disabling Power Management"
./powerstateoff
echo "Configuring System to 1 active core"
./enable_disable_cpu.sh cpu1
echo "   Core 1 disabled..."
./enable_disable_cpu.sh cpu2
echo "   Core 2 disabled..."
./enable_disable_cpu.sh cpu3
echo "   Core 3 disabled..."
echo "Fixing CPU frequency to 2GHz"
./setConstantCPUFreq.sh 2000000

echo "Installing EMONX driver..."
cd /data/emonx-05092013/
./install_driver

