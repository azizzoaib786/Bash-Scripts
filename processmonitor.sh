log_file="processmonitor1.log"

[[ ! -s $log_file ]] && touch $log_file

PROCESS=$1
wait_time="5"
script_failure="0"
attempt=0
max_attempts=3

txtred=$(tput setaf 1) # Red: will indicate a failed process and the information 
txtgrn=$(tput setaf 2) # Green: this is successful process information 
txtylw=$(tput setaf 3) # Yellow: this is used to show cautionary information 
txtrst=$(tput sgr0) # resets text

for (( attempt=$attempt ; ((attempt<$max_attempts)) ; attempt=(($attempt+1)) ))
do
	ps aux | grep "$PROCESS" | grep -v "grep $PROCESS"
	if [ $? != 0 ]
	then
		log_time=$(date)
		echo
		echo "$(tput setaf 3)$PROCESS is not running. Attempt will be made to restart. This is attempt $attempt of 3.$(tput sgr0)" echo >>$log_file
		echo "$log_time: $PROCESS is not running, Restarting. Attempt $attempt of 3.">>$log_file 
		echo 
        sudo systemctl start $PROCESS &
		sleep 2 # Pause to prevent false positives from restart attempt.
	else attempt="3"
	fi 
done
sleep 2


detect_failure() {
ps aux | grep "$PROCESS" | grep -v "grep $PROCESS"
if [ $? != 0 ]
then
	log_time=$(date)
	echo
	echo "$(tput setaf 1)$PROCESS is not running after 3 attempts. Process has failed and cannot be restarted. $(tput sgr0)" # Report failure to user
	echo "This script will now close."
	echo "">>$log_file
	echo "$log_time: $PROCESS cannot be restarted.">>$log_file # Log failure 
        script_failure="1" # Set failure flag
else
	log_time=$(date)
	echo
	echo "$log_time : $PROCESS is running."
	echo "$log_time : $PROCESS is running." >> $log_file
fi 
}

program_closing() {
# Report and log script shutdown
log_time=$(date)
echo
echo "Closing monitor script. No further monitoring of $PROCESS will be performed." #Reports closing of monitor script to user
echo
echo "$(tput setaf 1)$log_time: Monitoring for $PROCESS terminated. $(tput sgr0)" echo
echo "$log_time: Monitoring for $PROCESS terminated.">>$log_file # Logs termination of monitor script to log_file
echo >> $log_file
echo "***************" >> $log_file
echo >> $log_file
# Ensure this script is properly killed 
kill -9 > /dev/null
}

# Trap shutdown attempts to enable logging of shutdown trap 
trap 'program_closing; exit 0' 1 2 3 15
# Inform user of purpose of script
clear
echo
echo "This script will monitor $PROCESS to ensure that it is running," echo "and attempt to restart it if it is not. If it is unable to"
echo "restart after 3 attempts, it will report failure and close." 
sleep 2
#Perform monitoring
while [ $script_failure != "1" ] 
do
	# Monitors process and attempts 3 restarts if it fails. 
        detect_failure # Reports failure in the event that the process does not restart. 
	if [ $script_failure != "1" ]
	then
		sleep $wait_time 
	fi
done
program_closing #Logs script closure
exit 0
