#!/bin/bash
# Shell script to get uptime, disk usage, cpu usage, RAM usage,system load,etc.
# from multiple Linux servers and output the information on a single server
# in html format. Read below for usage/installation info
# *---------------------------------------------------------------------------*
# * dig_remote_linux_server_information.bash,v0.1, last updated on 25-Apr-2014*
# * Copyright (c) 2014 Akkiaks project                                       *
# * Comment/bugs: https://github.com/Akkiaks/                                    *
# * Ref url: https://github.com/Akkiaks/           *
# * This script is licensed under GNU GPL version 2.0 or above                *
# *---------------------------------------------------------------------------*
# *  Installation Info                                                        *
# ----------------------------------------------------------------------------*
# You need to setup ssh-keys to avoid password prompt, see url how-to setup
# ssh-keys:
#
# [1] You need to setup correct VARIABLES script:
#
# (a) Change Q_HOST to query your host to get information
# Q_HOST="192.168.1.2 127.0.0.1 192.168.1.2"
#
# (b) Setup USR, who is used to connect via ssh and already setup to connect
# via ssh-keys
# USR="Akki"
#
# (c)Show warning if server load average is below the limit for last 5 minute.
# setup LOAD_WARN as per your need, default is 5.0
#
# LOAD_WARN=5.0
#
# (d) Setup your network title using MYNETINFO
# MYNETINFO="My Network Info"
#
# (e) Save the file
#
# Please refer to forum topic on this script:
# Also download the .gif files and put them in your output dir
#
# ----------------------------------------------------------------------------
# Execute script as follows (and copy .gif file in this dir) :
# this.script.name > /var/www/html/info.html
# ============================================================================
# This script is part of Akash shell script collection (NSSC)
# Visit https://github.com/Akkiaks/ for more information.
# -------------------------------------------------------------------------

# SSH SERVER HOST IPS, setup me
# Change this to query your host
Q_HOST="192.168.1.127 192.168.1.167 192.168.1.114 192.168.2.48"

# SSH USER, change me
USR="akki"

# Show warning if server load average is below the limit for last 5 minute
LOAD_WARN=5.0

# Your network info
MYNETINFO="Server Info"
#
# if it  is run as cgi we can do reload stuff too :D
PBY='Powered by <a href="https://github.com/Akkiaks/">script</a>'


# font colours
GREEN='<font color="#00ff00">'
RED='<font color="#ff0000">'
NOC='</font>'
LSTART='<ul><li>'
LEND='</li></ul>'
# Local path to ssh and other bins
SSH="/usr/bin/ssh"
PING="/bin/ping"
NOW="$(date)"

## functions ##
writeHead(){
 echo '<HTML><HEAD><TITLE>Network Status</TITLE></HEAD>
 <BODY alink="#0066ff" bgcolor="#000000" link="#FF0040" text="#ccddee" vlink="#8904B1">'
 echo '<CENTER><H1>'
 echo "$MYNETINFO</H1>"
 echo "Generated on $NOW"
 echo '</CENTER>'

}

writeFoot(){
 echo "<HR><center>$PBY</center>"
  echo "</BODY></HTML>"
}

## main ##

writeHead
echo '<TABLE WIDTH=100% BORDER=2 BORDERCOLOR="#000080" CELLPADDING=4 CELLSPACING=4 FRAME=HSIDES RULES=NONE" >'
echo '<TR VALIGN=TOP>'
for host in $Q_HOST
do
  #echo '<TD WIDTH=33% BGCOLOR="#0099ff">'
  echo '<TD BGCOLOR="#0099ff">'
  _CMD="$SSH $USR@$host"
  rhostname="$($_CMD hostname)"

  ruptime="$($_CMD uptime)"
  if $(echo $ruptime | grep -E "min|days" >/dev/null); then
    x=$(echo $ruptime | awk '{ print $3 $4}')
  else
    x=$(echo $ruptime | sed s/,//g| awk '{ print $3 " (hh:mm)"}')
  fi
  ruptime="$x"

  rload="$($_CMD uptime |awk -F'average:' '{ print $2}')"
  x="$(echo $rload | sed s/,//g | awk '{ print $2}')"
  y="$(echo "$x >= $LOAD_WARN" | bc)"
  [ "$y" == "1" ] && rload="$RED $rload (High) $NOC" || rload="$GREEN $rload (Ok) $NOC"

  rclock="$($_CMD date +"%r")"
  rtotalprocess="$($_CMD ps axue | grep -vE "^USER|grep|ps" | wc -l)"
  rfs="$($_CMD df -hT | grep -vE "^Filesystem|shm" \
  | awk 'BEGIN{print "<ul>"}{w=sprintf("%d",$6);print "<li>" $7 \
  "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" $6 \
  "(" $2 ")<BR> <img src=\"indicator.gif\" height=\"4\" width=\"" w "\"> \
  <BR><img src=\"graph.gif\"> \
  <BR>" $4"/"$3 "</li>"}END{ print "</ul>"}')"

  rusedram="$($_CMD free -mto | grep Mem: | awk '{ print $3 " MB" }')"
  rfreeram="$($_CMD free -mto | grep Mem: | awk '{ print $4 " MB" }')"
  rtotalram="$($_CMD free -mto | grep Mem: | awk '{ print $2 " MB" }')"

  $PING -c1  $host>/dev/null
  if [ "$?" != "0" ] ; then
    rping="$RED Failed $NOC"
  else
    rping="$GREEN Ok $NOC"
    echo "<b><u>$rhostname</u></b><BR>"
    echo "Ping status: $rping<BR>"
    echo "Time: $rclock<BR>"
    echo "Uptime: $ruptime <BR>"
    echo "Load avarage: $LSTART $rload $LEND"
    echo "Total running process: $LSTART $rtotalprocess $LEND"
    echo "Disk status:"
    echo "$rfs"
    echo "Ram/swap status:<ul>"
    echo "<li>Used RAM: $rusedram</li>"
    echo "<li>Free RAM: $rfreeram</li>"
    echo "<li>Total RAM: $rtotalram </li></ul>"
  fi

 # echo "</td>"
done
 # echo "</tr></table>"
writeFoot
#copy html to your web server root dir and see the Magic
scp test.html 192.168.1.167:/var/www/adminer/
