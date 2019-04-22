# process_monitor_bash_script

You need to pass service name while running the script.

./processmonitor.sh httpd

httpd is the service we are monitoring.

It will start the service if not running, if this script is facing any issues it will attempt 3 times to start the service
before terminating itself.
