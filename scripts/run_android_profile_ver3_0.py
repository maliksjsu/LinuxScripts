# Imports the monkeyrunner modules used by this program
from com.android.monkeyrunner import MonkeyRunner, MonkeyDevice
from com.android.ddmlib import ShellCommandUnresponsiveException
from com.android.ddmlib import AndroidDebugBridge, IDevice, MultiLineReceiver
from java.lang import String
import os
import sys
import string
import getopt

# |----------------------------------------------------------------
# | Setup:
# |  android_emonx_dir      = Location of MTMON driver/tool inside the android device
# |  android_scripts_dir    = (Currently not being used anywhere).
# |  wkld_runtime 	    = Workload run time
# |  wkld_name    	    = Trace workload file name
# |  android_wkld_name      = Android name of installed application
# |  android_setup_script   = Android script to install driver, set CPU freq, etc. Script located in android device.
# |  app_start_cmd    	    = Android command to start android workload app. Using adb shell from Linux to issue command.
# |  monkeyrunner_dir       = Location of monkeyrunner toolset needed to run this automation script
# |
# |  tt_max                 = Range of trace triggers from 0-(tt_max-1). Min tt_max = 1. Default is tt_max = 1 if -tt not used. Make sure to include -tt in profile_cmd if used.
# | Comments:
# | - Android workload name can be gotten by starting the app and running 
# |        >adb logcat | grep START
# |----------------------------------------------------------------		
#===========================Setup=====================================
#=====================================================================
android_emonx_dir   = "/data/emonx-07242013"
android_scripts_dir = "/data/scripts"
android_device_id   = "Medfield9FA206C2" 
#wkld_runtime = 125  #test1
#wkld_runtime = 120  #test2 
#wkld_runtime = 93   #test3  
#wkld_runtime = 167  #test4
#wkld_runtime = 48   #test5
#wkld_runtime = 548  #Total perf
wkld_runtime = 200  #Generic time
tt_max                  = 2
wkld_name               = "quicktrace_mobilexprt-perf-test3_pi_2012-32bit_android-422_-_ctl2000-100-x1_600m-lcat_1307"
profile_cmd             = "./emonxcli -j 1000000 -c mrm_counters.txt -sync -s " + str(wkld_runtime) + " -tt "
profile_output_dir      = "./profiles"
android_wkld_name       = "com.xprt/.MobileXPRT"
android_setup_script    = "./setup_android_for_tracing.sh"
#traceoffsets_dir        = ""
#monkeyrunner_dir = ""
# ---
indices 		= ['1', '2', '3']
cd_android_emonx_dir    = "cd " + android_emonx_dir + "; "
cd_android_scripts_dir  = "cd " + android_scripts_dir + "; "
app_start_cmd           = "am start -S "  + android_wkld_name
#=====================================================================
#=====================================================================


class Receiver(MultiLineReceiver):
    def __init__(self):
        MultiLineReceiver.__init__(self)

    def processNewLines(self, lines):
        for line in lines:
            print line


#===============================FUNC==================================
#def main(argv):
def main():
    #hack - Adding script termination for testing (CM 130802)
    #print "Hi"
    #mode = GetArgs(argv)
    #print mode
    #sys.exit(2)

    (device, iDevice, rec) = SetupAndroid()
    wkld_choice = RunWorkloadSelect()

    for index in indices:
        for tt_index in range(0, tt_max):
            print "============START============\n"

            print "Executing warm-up run without profiling..."
            RunWorkload(device, wkld_choice)
            MonkeyRunner.sleep(10.0 + wkld_runtime)

            print "Begin profiling..."
            RunWorkload(device, wkld_choice)

            Trigger(iDevice, tt_index, rec)

            print "Finished profiling..."
            RenameProfileFiles(iDevice, index, tt_index, rec)
               
            GetProfileFiles(index, tt_index)

            #hack - Not sure I need it since rebooting and it sometimes hangs (CM 130809)
            #print "Kill Workload"
            #KillWorkload()

            print "Sleep 10 seconds"
            MonkeyRunner.sleep(10.0)
            
            #hack - Put RestartADB() into SetupAndroid()? (CM 130726)
               
            # Reboot after capturing profile
            print "Rebooting Android system..."
            os.system("adb reboot")
            
            print "Waiting for system to boot up..."
            MonkeyRunner.sleep(60.0)

            #hack - Need to reconnect to android device make it impossible to run 2 android devices on one platform at the same time? (CM 130811)
            RestartADB()

            (device, iDevice, rec) = SetupAndroid()
                
    print "\n=============END============="
#---------------------------------------------------------------------

#===============================FUNC==================================
# |------------------------------------------------------- 
# | def GetArgs()
# |     Get command line arguments. Needed to determine if
# |      running profiling or collecting.
# | Comments: Can't use -p because monkeyrunner is using this flag
# | o GetoptError not working correctly. Fix later
# | o Modify so only expect 1 argument?
# | o Maybe get rid of flags and just run options from menu
# |-------------------------------------------------------
def GetArgs(f_argv):
    f_mode = ""
    
    print "Getting arguments..."
    try:
        opts, args = getopt.getopt(f_argv, "fc")
    except getopt.GetoptError:
        print "run_android_profile.py [-f|-c]"
        print "  -f  Run profiling."
        print "  -c  Run collection."
        sys.exit(2)

    for opt, arg in opts:
        if opt == "-f":
            print "Running in profiling mode"
            f_mode = "profiling"
        elif opt == "-c":
            print "Running in collection mode"
            f_mode = "collection"
    if f_mode == "":
        print "run_android_profile.py [-f|-c]"
        sys.exit(2)
        
    return f_mode

   
#---------------------------------------------------------------------

#===============================FUNC==================================
#def KillWorkload(device):
def KillWorkload():
#    app_kill_cmd = "adb -s " + android_device_id + " shell kill `adb shell ps | grep mobilexprt | awk '{print $2}'`"
    app_kill_cmd = "adb shell ps | grep com.xprt | awk '{print $2}' | xargs adb shell kill"
   
    print "Exiting workload..."
    MonkeyRunner.sleep(2.0)
    #device.touch(120, 120, device.DOWN_AND_UP)
    os.system(app_kill_cmd)
    MonkeyRunner.sleep(2.0)
    os.system(app_kill_cmd)
   
#---------------------------------------------------------------------

#===============================FUNC==================================
# |-------------------------------------------------------
# | def RenameProfileFiles(f_iDevice, f_index, f_rec)
# |     
# | 
# |-------------------------------------------------------
def RenameProfileFiles(f_iDevice, f_index, f_tt_index, f_rec):
    print "Renaming emonx.txt to " + wkld_name + "-p" + str(f_index) + "_" + str(f_tt_index) + ".emon.txt"
    ##hack - Script is looking for emonx.txt but in cd_android_scripts_dir? but its in emonx-05092013 dir   (CM 130612)
    #print "Executing... " + android_scripts_dir + "/saveprofile " + wkld_name + " " + str(index)
    print "Executing... " + cd_android_emonx_dir + "mv emonx.txt " + profile_output_dir + "/" + wkld_name + " " + str(f_index) + "_" + str(f_tt_index)
    f_iDevice.executeShellCommand(cd_android_emonx_dir + "./saveprofile " + wkld_name + " " + str(f_index) + "_" + str(f_tt_index), f_rec, 0)
    #iDevice.executeShellCommand(cd_android_emonx_dir + "mv emonx.txt " + profile_output_dir + "/" + wkld_name + " " + str(index), rec, 0)
#---------------------------------------------------------------------

#===============================FUNC==================================
# |-------------------------------------------------------
# | def RestartADB()
# |     
# | 
# |-------------------------------------------------------    
def RestartADB():
    print "Kill adb server..."
    os.system("adb kill-server")
    MonkeyRunner.sleep(10)

    print "Start adb server..."
    os.system("adb start-server")
    MonkeyRunner.sleep(5)
#---------------------------------------------------------------------

#===============================FUNC==================================
# |-------------------------------------------------------
# | def RootADB()
# |     
# | 
# |-------------------------------------------------------    
def RootADB():
    print "Restarting adb deamon with root permissions..."
    os.system("adb -s Medfield9FA206C2 root")
#---------------------------------------------------------------------

#===============================FUNC==================================			
# |------------------------------------------------------- 
# | 1. Run workload
# | 2. Kill workload
# | 
# | Note: device or iDevice NOT used for killing app
# |       because grep is not installed on tablet
# |-------------------------------------------------------
def RunWorkload(f_device, f_choice):
    if f_choice == 1:
        
        print "Starting up workload application..."
        f_device.shell(app_start_cmd)
        MonkeyRunner.sleep(2.0)

        print "====READY TO RUN WORKLOAD===="
        MonkeyRunner.sleep(3.0)
       
        #Select performance suite from main screen
        f_device.touch(170, 350, f_device.DOWN)
        MonkeyRunner.sleep(1.0)
        f_device.touch(170, 350, f_device.UP)

        #Select individual performance workload
        MonkeyRunner.sleep(3.0)
        f_device.touch(170, 220, f_device.DOWN_AND_UP)

        #Press Start
        MonkeyRunner.sleep(3.0)
        f_device.touch(170, 1220, f_device.DOWN_AND_UP)
        
    elif f_choice == 2:
        
        print "Starting up workload application..."
        f_device.shell(app_start_cmd)
        MonkeyRunner.sleep(2.0)

        print "====READY TO RUN WORKLOAD===="
        MonkeyRunner.sleep(3.0)
       
        #Select performance suite from main screen
        f_device.touch(170, 350, f_device.DOWN)
        MonkeyRunner.sleep(1.0)
        f_device.touch(170, 350, f_device.UP)

        #Select individual performance workload
        MonkeyRunner.sleep(3.0)
        f_device.touch(170, 330, f_device.DOWN_AND_UP)

        #Press Start
        MonkeyRunner.sleep(3.0)
        f_device.touch(170, 1220, f_device.DOWN_AND_UP)
        
    elif f_choice == 3:
        
        print "Starting up workload application..."
        f_device.shell(app_start_cmd)
        MonkeyRunner.sleep(2.0)

        print "====READY TO RUN WORKLOAD===="
        MonkeyRunner.sleep(3.0)
       
        #Select performance suite from main screen
        f_device.touch(170, 350, f_device.DOWN)
        MonkeyRunner.sleep(1.0)
        f_device.touch(170, 350, f_device.UP)

        #Select individual performance workload
        MonkeyRunner.sleep(3.0)
        f_device.touch(170, 430, f_device.DOWN_AND_UP)

        #Press Start
        MonkeyRunner.sleep(3.0)
        f_device.touch(170, 1220, f_device.DOWN_AND_UP)
        
    elif f_choice == 4:
        
        print "Starting up workload application..."
        f_device.shell(app_start_cmd)
        MonkeyRunner.sleep(2.0)

        print "====RUN WORKLOAD===="
        MonkeyRunner.sleep(3.0)
       
        #Select performance suite from main screen
        f_device.touch(170, 350, f_device.DOWN)
        MonkeyRunner.sleep(1.0)
        f_device.touch(170, 350, f_device.UP)

        #Select individual performance workload
        MonkeyRunner.sleep(3.0)
        f_device.touch(170, 530, f_device.DOWN_AND_UP)

        #Press Start
        MonkeyRunner.sleep(3.0)
        f_device.touch(170, 1220, f_device.DOWN_AND_UP)
        
    elif f_choice == 5:
        
        print "Starting up workload application..."
        f_device.shell(app_start_cmd)
        MonkeyRunner.sleep(2.0)

        print "====RUN WORKLOAD===="
        MonkeyRunner.sleep(3.0)
       
        #Select performance suite from main screen
        f_device.touch(170, 350, f_device.DOWN)
        MonkeyRunner.sleep(1.0)
        f_device.touch(170, 350, f_device.UP)

        #Select individual performance workload
        MonkeyRunner.sleep(3.0)
        f_device.touch(170, 630, f_device.DOWN_AND_UP)

        #Press Start
        MonkeyRunner.sleep(3.0)
        f_device.touch(170, 1220, f_device.DOWN_AND_UP)
        
    else:
        print "Non existent choice."
        sys.exit(2)
#---------------------------------------------------------------------

#===============================FUNC=================st=================			
# |------------------------------------------------------- 
# | 1. Run workload
# | 2. Kill workload
# | 
# | Note: device or iDevice NOT used for killing app
# |       because grep is not installed on tablet
# |-------------------------------------------------------
def RunWorkloadSelect():
    print "====================================================================="
    print "= Choose workload to run (1-5):"
    print "=   1: MobileXPRT->Performance Tests->Apply Photo Effects"
    print "=   2: MobileXPRT->Performance Tests->Create Photo Collages"
    print "=   3: MobileXPRT->Performance Tests->Create Slideshow"
    print "=   4: MobileXPRT->Performance Tests->Encrypt Personal Content"
    print "=   5: MobileXPRT->Performance Tests->Detect Faces to Organize Photos"
    print "====================================================================="

    f_choice = input("Enter choice: ")
    
    return f_choice

#---------------------------------------------------------------------
    
#===============================FUNC==================================
# |------------------------------------------------------- 
# | def SetupAndroid()
# |     Run setup commands and scripts to get Android ready for profiling.
# |
# |
# |-------------------------------------------------------
def SetupAndroid():
    RootADB()
    
    # |----------------------------------------------------------------
    # | Connects to the current device returning a MonkeyDevice object
    # | used to simulate screen touches and other events. It may also
    # | be used to issue shell commands using device.shell(cmd).
    # | 
    # |----------------------------------------------------------------
    f_device = MonkeyRunner.waitForConnection()

    # Gets the debug bridge for the device currently connected
    adb = AndroidDebugBridge.getBridge()

    # |----------------------------------------------------------------
    # | Gets an IDevice object used to execute adb shell commands
    # | that may throw a ShellUnresponsiveException.
    # |----------------------------------------------------------------
    f_iDevice = adb.getDevices()[0]
    print "Connected to: ", f_iDevice   

    # Receives output, if any, from commands executed in shell
    f_rec = Receiver()

    # |----------------------------------------------------------------
    # | Preparing Android device for next profiling run
    # |    => Disable EIP randomization
    # |    => Disable Power management
    # |    => Configure to 1P
    # |    => Set constant CPU frequency
    # |    => Install Driver
    # | Comment: Android setup script located in android device
    # |----------------------------------------------------------------
    f_iDevice.executeShellCommand(cd_android_emonx_dir + android_setup_script, f_rec, 0)
    MonkeyRunner.sleep(5.0)

    return (f_device, f_iDevice, f_rec)
#---------------------------------------------------------------------			

#===============================FUNC==================================
# |-------------------------------------------------------
# | def Trigger()
# |     Run emonxcli.
# | 
# |-------------------------------------------------------
def Trigger(f_iDevice, f_tt_index, f_rec):
    print "Executing trigger command...\n" + profile_cmd + str(f_tt_index)
    f_iDevice.executeShellCommand(cd_android_emonx_dir + profile_cmd + str(f_tt_index), f_rec, 0)
    ##hack - Adding print statement to know when emonxcli is done (CM 130612) 
    print "!!!!!!!DONE!!!!!!!!!!!!"
    MonkeyRunner.sleep(3.0)

#---------------------------------------------------------------------

#===============================FUNC==================================
# |------------------------------------------------------- 
# | def GetProfileFiles()
# |     Get profile (emon.txt) files from android device.
# |
# |
# |-------------------------------------------------------
def GetProfileFiles(f_index, f_tt_index):
#    print "Executing... " + "adb -s " + android_device_id + " pull " + android_emonx_dir + "/" + profile_output_dir + "/" + wkld_name + " " + str(f_index) + "_" + str(f_tt_index) + ".emon.txt" + " " + profile_output_dir
    print "Executing... " + "adb pull " + android_emonx_dir + "/" + profile_output_dir + "/" + wkld_name + " " + str(f_index) + "_" + str(f_tt_index) + ".emon.txt" + " " + profile_output_dir
#    os.system("adb -s " + android_device_id + "pull " + android_emonx_dir + "/" + profile_output_dir + "/" + wkld_name + "-p" + str(f_index) + "_" + str(f_tt_index) + ".emon.txt" + " " + profile_output_dir)
    os.system("adb pull " + android_emonx_dir + "/" + profile_output_dir + "/" + wkld_name + "-p" + str(f_index) + "_" + str(f_tt_index) + ".emon.txt" + " " + profile_output_dir)

#---------------------------------------------------------------------

#===============================main program start==================================
#hack - Getting error with line below(CM 130726)
#if __name__
#main(sys.argv[1:])
main()

