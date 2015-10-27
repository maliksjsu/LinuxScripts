#Simple menu driven shell script to to get information about your
# Linux server / desktop.
# Author: Kanwar Malik
# Date: 3/26/2015

# Define variables

NC='\033[0m'
red='\033[0;31m'
green='\e[0;32m'
peername=$(cat /etc/motd |grep -Eho 'PeerID[^[:space:]]*'|awk '{print substr($0,22,4)}')
report=report



# Purpose: Display pause prompt
# $1-> Message (optional)
function pause(){
        local message="$@"
        [ -z $message ] && message="Press [Enter] key to continue..."
        read -p "$message" readEnterKey
}

# Purpose  - Display a menu on screen
function show_menu(){
    date
        cat /etc/motd
                echo "--------------------------------------------------------------"
                echo "   Main Menu"
                echo "--------------------------------------------------------------"
                echo "1. Detect Modems"
                echo "2. Detect Video Input"
                echo "3. Get Transmitter Information"
                echo "4. Build Test"
                echo "5. Black Magic Test"
                echo "6. exit"
}

# Purpose - Display header message
# $1 - message
function write_header(){
        local h="$@"
        echo "----------------------------------------"
        echo "     ${h}"
        echo "----------------------------------------"
}

# Purpose - Get info about your operating system
function modem_check(){
                
		cat /etc/motd > $report"_"$peername.txt
		echo -e "--------------------------------------------------------------------------------\n" >> $report"_"$peername.txt
		echo "Testing for the modem module" >> $report"_"$peername.txt
		echo -e "--------------------------------------------------------------------------------\n" >> $report"_"$peername.txt
        write_header " Modem Module Scan"
        local ModemModule=$(lsusb | grep -i Microsystems| grep -Eho 'Bus'|uniq|xargs)

                if test "$ModemModule" = "Bus"
                then
                        tty -s && tput setaf 4;echo "************************************"
                        tty -s && tput sgr0;
                        modem_check="Found"
                        tty -s && tput setaf 2; echo -e "The Modem Module is FOUND " 2>&1 | tee -a $report"_"$peername.txt
                        echo -e "--------------------------------------------------------------------------------\n" >> $report"_"$peername.txt
						tty -s && tput sgr0
                        write_header "Getting information about the modems connected"
                        id=$(curl -s http://127.0.0.1:5003/T_STATUS|awk '/R ID/{flag=1;next}/R>/{flag=0}flag'|sort -u|grep -Eho 'ID=[^[:space:]]*'|awk    -F '"' '{print $2}'|uniq)
                        typ=$(curl -s http://127.0.0.1:5003/T_STATUS|awk '/R ID/{flag=1;next}/R>/{flag=0}flag'|sort -u|grep -Eho 'TYPE=[^[:space:]]*'|awk -F '"' '{print $2}')
                        stat=$(curl -s http://127.0.0.1:5003/T_STATUS|awk '/R ID/{flag=1;next}/R>/{flag=0}flag'|sort -u|grep -Eho 'STATUS=[^[:space:]]*'|awk -F '"' '{print $2}')
                        ip=$(curl -s http://127.0.0.1:5003/T_STATUS|awk '/R ID/{flag=1;next}/R>/{flag=0}flag'|sort -u|grep -Eho 'IP=[^[:space:]]*'|awk    -F '"' '{print $2}'|uniq)
                        AR_id=( $id )
                        AR_typ=( $typ )
                        AR_stat=( $stat )
                        AR_ip=( $ip )

                            printf 'SLOTNO TYPE STATUS     IP \n' 2>&1 | tee -a $report"_"$peername.txt
                        for ((i=0; i<${#AR_id[@]}; i++)) ;do
                            printf '%-6s %-4s %-10s %-s \n' "${AR_id[i]}" "${AR_typ[i]}" "${AR_stat[i]}" "${AR_ip[i]}" 2>&1 | tee -a $report"_"$peername.txt
							done
                        tty -s && tput setaf 4;echo "************************************"
                        tty -s && tput sgr0;

                else
                        tty -s && tput setaf 1; echo -e "The Modem Module is NOT found" 2>&1 | tee -a $report"_"$peername.txt
                        echo -e "--------------------------------------------------------------------------------\n" >> $report"_"$peername.txt
						tty -s && tput sgr0
                fi

                #Pause "Press [Enter] key to continue..."
        pause
}
function Blackmagic_check(){
                write_header "Black Magic card test"
				echo -e "--------------------------------------------------------------------------------\n" >> $report"_"$peername.txt
				echo "Testing for Black Magic Card" >> $report"_"$peername.txt
                echo -e "--------------------------------------------------------------------------------\n" >> $report"_"$peername.txt
				local Black_Input=$(BlackmagicFirmwareUpdater status |awk -F ' ' '{print $6}'|xargs)

                if test "$Black_Input" = "OK"
                then
                    Black_check="OK"
                    tty -s && tput setaf 2; echo -e "The Black Magic Card is detected and updated " 2>&1 | tee -a $report"_"$peername.txt
                    echo -e "--------------------------------------------------------------------------------\n" >> $report"_"$peername.txt
					tty -s && tput sgr0;
                elif test "$Black_Input" = "PLEASE_UPDATE"
                    then
                    tty -s && tput setaf 2; echo -e "The Black Magic Card is detected" 2>&1 | tee -a $report"_"$peername.txt
                    tty -s && tput setaf 1; echo -e "But it needs update" 2>&1 | tee -a $report"_"$peername.txt
                    echo -e "--------------------------------------------------------------------------------\n" >> $report"_"$peername.txt
					BlackmagicFirmwareUpdater update 0
                    tty -s && tput sgr0;
                else
                    tty -s && tput setaf 2; echo -e "RUN LSPCI to find if the Blackmagic card is detected or not"2>&1 | tee -a $report"_"$peername.txt
                    echo -e "--------------------------------------------------------------------------------\n" >> $report"_"$peername.txt
                fi


                    pause

}

function video_check(){
                write_header " Video Input "
				echo "Testing for Video Input" >> $report"_"$peername.txt
                echo -e "--------------------------------------------------------------------------------\n" >> $report"_"$peername.txt
                local VideoInput=$(curl -s http://127.0.0.1:5003/T_STATUS|grep -P "CAMERA"| grep -Eho "CAMERA=[^[:space:]]*"|awk -F '"' '{print $2}'|xargs)

                if test "$VideoInput" = "1"
                then
                        Video_check="DETECTED"
                        tty -s && tput setaf 2; echo -e "Video Input is detected" 2>&1 | tee -a $report"_"$peername.txt
                        echo -e "--------------------------------------------------------------------------------\n" >> $report"_"$peername.txt
						tty -s && tput sgr0;
                        IP=$(curl -s http://127.0.0.1:5003/T_STATUS| grep ETH |grep -Eho "IP=[^[:space:]]*"|uniq|awk -F '"' '{print $2}')
                    curl "http://$IP/webui/webui_data.pl?a=media" > /home/filetest123.txt

                        SRC=$(cat /home/filetest123.txt|grep -Eho ' SRC=[^[:space:]]*'|awk -F '"' '{print$2}')
                        VTYPE=$(cat /home/filetest123.txt|grep -Eho 'VTYPE=[^[:space:]]*'|awk -F '"' '{print$2}')
                        WIDTH=$(cat /home/filetest123.txt|grep -Eho 'W=[^[:space:]]*'|awk -F '"' '{print$2}')
                        HEIGHT=$(cat /home/filetest123.txt|grep -Eho 'H=[^[:space:]]*'|awk -F '"' '{print$2}')
                        FPS=$(cat /home/filetest123.txt|grep -Eho 'FPS=[^[:space:]]*'|awk -F '"' '{print$2}')
                        tty -s && tput setaf 4;echo "************************************"2>&1 | tee -a $report"_"$peername.txt
                        tty -s && tput sgr0;
                        echo -e  "The SOURCE is:                      ${green}$SRC${NC}"   2>&1 | tee -a $report"_"$peername.txt
                        echo -e  "The VIDEO type :                    ${green}$VTYPE${NC}" 2>&1 | tee -a $report"_"$peername.txt
                        echo -e  "The WIDTH of the source is :        ${green}$WIDTH${NC}" 2>&1 | tee -a $report"_"$peername.txt
                        echo -e  "The HEIGHT of srouce is:            ${green}$HEIGHT${NC}"2>&1 | tee -a $report"_"$peername.txt
                        echo -e  "The FRAME PER SERCOND of srouce is: ${green}$SRC${NC}"   2>&1 | tee -a $report"_"$peername.txt
                        tty -s && tput setaf 4;echo "************************************" 2>&1 | tee -a $report"_"$peername.txt
                        echo -e "--------------------------------------------------------------------------------\n" >> $report"_"$peername.txt
						tty -s && tput sgr0;
                else
                        tty -s && tput setaf 1; echo -e "Video Input is not detected" 2>&1 | tee -a $report"_"$peername.txt
                        echo -e "--------------------------------------------------------------------------------\n" >> $report"_"$peername.txt
						tty -s && tput sgr0;
                fi
                                                #Pause "Press [Enter] key to continue..."
        pause

}
function trans_info(){
                trans_name=$(curl -s http://127.0.0.1:5003/T_STATUS |grep TVUT| grep -Eho 'NAME=[^[:space:]]*'|awk -F '"' '{print $2}')
        echo -e "Name of the transmitter in the control center is:${green} $trans_name ${NC}" 2>&1 | tee -a $report"_"$peername.txt
        echo -e "This transmitter is Paired to the following recievers" 2>&1 | tee -a $report"_"$peername.txt
        tty -s && tput setaf 4;echo -e "************************************" 2>&1 | tee -a $report"_"$peername.txt
        tty -s && tput sgr0;
        tty -s && tput setaf 2 ;
		curl -s http://127.0.0.1:5003/T_STATUS |grep -P "R ID"| grep -Eho "R ID=[^[:space:]]*|NAME=[^[:space:]]*"| awk -F '"' '{print; if (++onr%2 == 0) print ""; }'|awk -F '"' '{print $1 $2}' 2>&1 | tee -a $report"_"$peername.txt
        tty -s && tput sgr0;
        tty -s && tput setaf 4;echo -e "************************************" 2>&1 | tee -a $report"_"$peername.txt
        tty -s && tput sgr0;

        local trans_live=$(curl -s http://127.0.0.1:5003/T_STATUS |grep -P 'LIVE='|grep -Eho 'LIVE=[^[:space:]]*'|uniq|awk -F '"' '{print $2}')
        local trans_name=$(curl -s http://127.0.0.1:5003/T_STATUS |grep -P 'LIVE="1"'|grep -Eho 'NAME=[^[:space:]]*'|awk -F '"' '{print $2}')

                        if test "$trans_live" = "0"
                        then
                            tty -s && tput setaf 1; echo -e "This Transmitter is not live on any receiver" 2>&1 | tee -a $report"_"$peername.txt
							echo -e "--------------------------------------------------------------------------------\n" >> $report"_"$peername.txt
							tty -s && tput sgr0;
                        else

                            echo -e "The name of the receiver on which this unit is live right now is: ${green}$trans_name${NC}"2>&1 | tee -a $report"_"$peername.txt
							echo -e "--------------------------------------------------------------------------------\n" >> $report"_"$peername.txt
						fi
                                #Pause "Press [Enter] key to continue..."
        pause

}

function show_menu_2(){
while :
do
        local IP=$(curl -s http://127.0.0.1:5003/T_STATUS |grep LIVE=\"1\"|grep -Eho 'IP=[^[:space:]]*'|awk -F '"' '{print $2}'|xargs)
        #Getting the information about the R -  PID
        local ID=$(curl -s http://127.0.0.1:5003/T_STATUS | grep TVUT_STATUS |grep -Eho 'ID=[^[:space:]]*'|awk -F '"' '{print $2}'|xargs)
        #Getting the information about the
        local PORT=$(curl -s http://127.0.0.1:5003/T_STATUS |grep LIVE=\"1\"|grep -Eho 'PORT=[^[:space:]]*'|awk -F    '"' '{print $2}'|xargs)
        clear
        echo "~~~~~~~~~~~~~~~~~~~~~" 2>&1 | tee -a $report"_"$peername.txt
        echo " B U I L D - T E S T"  2>&1 | tee -a $report"_"$peername.txt
        echo "~~~~~~~~~~~~~~~~~~~~~" 2>&1 | tee -a $report"_"$peername.txt
		echo -e "--------------------------------------------------------------------------------\n" >> $report"_"$peername.txt
		echo -e "The PID of this Transmitter is  ${red}$ID${NC}"2>&1 | tee -a $report"_"$peername.txt
		echo -e "--------------------------------------------------------------------------------\n" >> $report"_"$peername.txt
                
		local trans_live=$(curl -s http://127.0.0.1:5003/T_STATUS |grep -P 'LIVE='|grep -Eho 'LIVE=[^[:space:]]*'|uniq|awk -F '"' '{print $2}')
        local trans_name=$(curl -s http://127.0.0.1:5003/T_STATUS |grep -P 'LIVE="1"'|grep -Eho 'NAME=[^[:space:]]*'|awk -F '"' '{print $2}')

            if test "$trans_live" = "0"
            then
				tty -s && tput setaf 1; echo -e "This Transmitter is not live on any receiver" 2>&1 | tee -a $report"_"$peername.txt
				tty -s && tput sgr0;
            pause
				break

            else
				echo -e "The IP address of Reciever that youare paired with is: ${red}$IP${NC} port : ${red}$PORT${NC}" 2>&1 | tee -a $report"_"$peername.txt
                echo -e "The name of the receiver on which this unit is live right now is: ${green}$trans_name${NC}"    2>&1 | tee -a $report"_"$peername.txt
                echo    "-----------------------------------------------------------------------" 
                echo    "What kind of test would you like this script to perform ?"
                echo "   (x). Do you want an automatic testing?"
                echo "   (y). Do you want to select your own bitrate and latency?"
                echo "   (e). Exit"
                echo -n "Please enter your choice:"
                read c
                    case $c in
                         "x"|"X")
                         echo "AUTOMATIC TESTING"
                         pause
                         ;;
                         "y"|"Y")
                         local IP=$(curl -s http://127.0.0.1:5003/T_STATUS |grep LIVE=\"1\"|grep -Eho 'IP=[^[:space:]]*'|awk -F '"' '{print $2}'|xargs)
                         #Getting the information about the R -  PID
                         local ID=$(curl -s http://127.0.0.1:5003/T_STATUS | grep TVUT_STATUS |grep -Eho 'ID=[^[:space:]]*'|awk -F '"' '{print $2}'|xargs)
                         #Getting the information about the
                         local PORT=$(curl -s http://127.0.0.1:5003/T_STATUS |grep LIVE=\"1\"|grep -Eho 'PORT=[^[:space:]]*'|awk -F    '"' '{print $2}'|xargs)
                         echo -n "Enter the bitrate setting and press [ENTER]."
                         read BITRATE
                         echo -n "Enter the latency rate and press [ENTER]."
                         read LATENCY
                         echo "if the Command has worked then the new line will print 1 or 0 if it didn't work"
                         curl "http://127.0.0.1/webui/webui_data.pl?a=chgset&ip=$IP&port=$PORT&mode=$ID&br=$BITRATE&delay=$LATENCY"
                         printf "\nwaiting for 20 seconds to get the error report"
                         sleep 20
                         ERROR=$(curl -s http://127.0.0.1:5003/T_INFO| grep errorRateN | grep -Eho 'errorRateN=[^[:space:]]*'|awk -F '"' '{print $2}'| xargs)
                         printf "\nError Rate is: $ERROR\n"
                         pause
                         ;;
                         "e"|"E")
                         break
                         ;;
                         *)
                         echo "invalid answer, please try again"
                         pause
                         ;;
                         esac
                         fi
                         done
                          }


#Purpose - Get input via the keyboard and make a decision using case..esac
function read_input(){
        local c
        read -p "Enter your choice [ 1 - 4 ] " c
        case $c in
                1)      modem_check ;;
                2)      video_check ;;
                3)      trans_info ;;
                4)      show_menu_2;;
                5)      Blackmagic_check;;
                6)      echo "Bye!"; exit 0 ;;
                *)
                        echo "Please select between 1 to 6 choice only."
                        pause
        esac
}

# ignore CTRL+C, CTRL+Z and quit singles using the trap
trap '' SIGINT SIGQUIT SIGTSTP

# main logic
while true
do
        clear
        show_menu       # display memu
        read_input  # wait for user input
done
