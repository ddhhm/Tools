#!/bin/bash
# 
# Assumes TCP port 25 is open in iptables with dpt:25.  This will not 
# add a new rule if one does not already exist.
#
# IDEA.  Secondary MX is in the cloud, with very little space.
# Cloud instance is cheap.  Secondary MX can also be a loophole
# for spammers.
# 
# If I could use a script to monitor the primary MX, and only open 
# port 25 on the secondary in the event the primary is down, it
# would be very useful.
#
# This script simply finds the line number for the local SMTP iptables
# rule, and opens or closes port 25 based on if the primary MX is 
# available.  It uses a simple python script called testport.py to test.
#
# The IP address and port number are configured below within this 
# script.  It could be easily altered to parse args for more general use.

IPTABLES=/sbin/iptables
AWK=/bin/awk
GREP=/bin/grep
ECHO=/bin/echo

TESTPORT=~root/bin/testport.py
IP=173.13.161.5
PORT=26

# Check if the local port 25 is open in our own firewal
$IPTABLES -n -L INPUT | $GREP 'ACCEPT.*dpt:25' >/dev/null 2>&1
LocalPortNotOpen=$?

# Get the rule number for iptables for port 25
rulenum=`$IPTABLES -n -L INPUT --line-numbers | $GREP '\(ACCEPT\|DROP\|REJECT\).*dpt:25' | $AWK '{print $1}'`

$ECHO rulenum for iptables toggle is $rulenum
# If no rulenum found, exit as we need an SMTP iptables rule to proceed
if [[ -z $rulenum ]] || [[ $rulenum = "" ]]; then
    echo "Could not find a rule for port 25."
    exit 1
fi


# Use testport.py python script to determine if remort port 25 is open
# on test server.
$TESTPORT $IP $PORT >/dev/null 2>&1

result=$?

if [ $result -eq 1 ]; then
    $ECHO Port is closed on primary MX
    if [ $LocalPortNotOpen -eq 1 ]; then
        $ECHO Opening local port 25
        $IPTABLES -R INPUT $rulenum -p tcp -m state --state NEW -m tcp --dport 25 -j ACCEPT
    else
        $ECHO Local port is already open. Doing nothing.
    fi
elif [ $result -eq 0 ]; then
    $ECHO Port is open on primary MX
    if [ $LocalPortNotOpen -eq 0 ]; then
        $ECHO Closing local port 25
        $IPTABLES -R INPUT $rulenum -p tcp -m state --state NEW -m tcp --dport 25 -j DROP
    else
	$ECHO Local port is already closed. Doing nothing.
    fi
fi
