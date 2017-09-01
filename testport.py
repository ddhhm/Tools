#!/usr/bin/python

# Return values
# -1 (255) Invalid command-line parameters given, returns 255 (-1)
#  1       Port is closed
#  0       Port is open

import socket;
import sys;

port=-1
addr=""

sys.argv.pop(0) # pop off program name from args
for arg in sys.argv:
    try:
        tport=int(arg)
    except ValueError:
        try:
            # Maybe the arg is an IP address...
            socket.inet_aton(arg)
        except socket.error:
            print "%s is neither a valid port number nor a valid IP address!!" % (arg)
            sys.exit(-1)
        else:
            addr=arg
    else:
        if tport > 65535 or tport < 1:
            print ("%s is not a valid port number" %(arg))
            sys.exit(-1)
        else:
            # port is good
            port=tport

if addr=="":
    print "IP address not specified."
    sys.exit(-1)

if port < 1 or port > 65535:
    print "Port is invalid [%d]" %(port)
    sys.exit(-1)

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.settimeout(5)
result = sock.connect_ex((addr,port))
#result = sock.connect_ex(('173.13.161.5',port))
if result==0:
    print "Port %s:%d is open..." % (addr,port)
else:
    print "port %s:%d is closed!" % (addr,port)
    sys.exit(1)
