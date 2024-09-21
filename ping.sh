#!/bin/bash
# HOSTS    = Hostnames or IP addresses from hosts to check for availability,
#            seperated by spaces, for example 'localhost 127.0.0.1'
# LOGIN    = Login name/callsign for hampager.de, for example 'N0CALL'
# PASSWORD = Password for hampager.de, for example 'P@ssw0rd'
# SENDTO   = Page message destination, for example '"N0CALL", "CL0WN"'
# TXGROUP  = Transmitter areas, for example '"pa-all", "on-all", "dl-all"'
# URL      = Dapnet server to use
# COUNT    = How many pings must be send to check a host status
# WAIT     = How long ping wait for respons from host
# STATE    = Host state output file
HOSTS'CHANGEME'
LOGIN='CHANGEME'
PASSWORD='CHANGEME'
SENDTO='CHANGEME'
TXGROUP='CHANGEME'
URL='http://www.hampager.de:8080/calls'
COUNT=3
WAIT=3
STATE='/tmp/ping_state.txt'

# If output file doesn't exist create one
{ [ -e "$STATE" ] || touch "$STATE"; }

for myHost in $HOSTS
do
  count=$(ping -w $WAIT -c $COUNT $myHost | grep 'received' | awk -F',' '{ print $2 }' | awk '{ print $1 }')
  if [ $count -eq 0 ]; then
    # 100% failed
    CHECK=`grep "$myHost" $STATE | grep -o "down"`
    if [ "$CHECK" != "down" ]; then
# Uncomment beneath line for output to terminal
    #echo -e "host $myHost ping failed"
    STATUS="ping failed"
    curl -H "Content-Type: application/json" -u "${LOGIN}:${PASSWORD}" -d '{ "text": "'"Host $myHost $STATUS at $(date)"'", "'"callSignNames"'": ["'"$SENDTO"'"], "transmitterGroupNames": ['"$TXGROUP"'], "emergency": false }' ${URL}
    #delete all previous entries of that ip
    sed -i "/$myHost/d" $STATE
    #mark host as down
    echo "$myHost - down" >> $STATE
    fi

 else
    CHECK1=`grep "$myHost" $STATE | grep -o "down"`
    if [ "$CHECK1" = "down" ]; then
# Uncomment beneath line for output to terminal
    #echo -e "host $myHost ping ok"
    STATUS="ping ok"
    curl -H "Content-Type: application/json" -u "${LOGIN}:${PASSWORD}" -d '{ "text": "'"Host $myHost $STATUS at $(date)"'", "'"callSignNames"'": ["'"$SENDTO"'"], "transmitterGroupNames": ['"$TXGROUP"'], "emergency": false }' ${URL}
      #insert email for host up here
    fi

    #delete all previous entries of that ip
    sed -i "/$myHost/d" $STATE
    echo "$myHost - up" >> $STATE
  fi
done
