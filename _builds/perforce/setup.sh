#!/bin/bash
set -e

export PUID=${PUID:-911}
export PGID=${PGID:-911}
export DATAVOLUME="/data"
export NAME="${NAME:-p4depot}"
export CASE_INSENSITIVE="${CASE_INSENSITIVE:-0}"
export P4ROOT="${DATAVOLUME}/${NAME}"
export P4PORT=1666

groupmod -o -g "$PGID" perforce
usermod -o -u "$PUID" perforce
echo '
-------------------------------------
Perforce Server Starting..
-------------------------------------'

if [ ! -d $DATAVOLUME/etc ]; then
    echo >&2 "First time installation, copying configuration from /etc/perforce to $DATAVOLUME/etc and relinking"
    mkdir -p $DATAVOLUME/etc
    cp -r /etc/perforce/* $DATAVOLUME/etc/
    rm -rf /etc/perforce
    ln -s $DATAVOLUME/etc /etc/perforce
    FRESHINSTALL=1
fi

if [ -z "$P4USER" ]; then
    echo >&2 "Set the P4USER env variable"
    exit 2
fi

if [ -z "$P4PASSWD" ]; then
    echo >&2 "Set the P4PASSWD env variable"
    exit 2
fi

P4SSLDIR="$P4ROOT/ssl"
for DIR in $P4ROOT $P4SSLDIR; do
	mkdir -m 0700 -p $DIR
	chown perforce:perforce $DIR
done

#=================================
# Create server configuration 
# if service is not already running
#=================================
# Usage: configure-helix-p4d.sh [service-name] [options]
# -n                   - Use the following flags in non-interactive mode
# -p <P4PORT>          - Perforce Server's address
# -r <P4ROOT>          - Perforce Server's root directory
# -u <username>        - Perforce super-user login name
# -P <password>        - Perforce super-user password
# --unicode            - Enable unicode mode on server
# --case               - Case-sensitivity (0=sensitive[default],1=insensitive)
# -h --help            - Display this help and exit

if ! p4dctl list 2>/dev/null | grep -q $NAME; then
    /opt/perforce/sbin/configure-helix-p4d.sh $NAME -n -p $P4PORT -r $P4ROOT -u $P4USER -P "${P4PASSWD}" --case $CASE_INSENSITIVE --debug
fi

p4dctl start -t p4d $NAME

if echo "$P4PORT" | grep -q '^ssl:'; then
    p4 trust -y
fi

cat > ~perforce/.p4config <<EOF
P4USER=$P4USER
P4PORT=$P4PORT
P4PASSWD=$P4PASSWD
EOF
chmod 0600 ~perforce/.p4config
chown perforce:perforce ~perforce/.p4config

p4 login <<EOF
$P4PASSWD
EOF

if [ "$FRESHINSTALL" = "1" ]; then
	## Load up the default tables
	echo >&2 "First time installation detected. Running configs.."

	# Update the Typemap
	# Based on : https://docs.unrealengine.com/en-us/Engine/Basics/SourceControl/Perforce
	(p4 typemap -o; echo " binary+w //depot/....exe") | p4 typemap -i
	(p4 typemap -o; echo " binary+w //depot/....dll") | p4 typemap -i
	(p4 typemap -o; echo " binary+w //depot/....lib") | p4 typemap -i
	(p4 typemap -o; echo " binary+w //depot/....app") | p4 typemap -i
	(p4 typemap -o; echo " binary+w //depot/....dylib") | p4 typemap -i
	(p4 typemap -o; echo " binary+w //depot/....stub") | p4 typemap -i
	(p4 typemap -o; echo " binary+w //depot/....ipa") | p4 typemap -i
	(p4 typemap -o; echo " binary //depot/....bmp") | p4 typemap -i
	(p4 typemap -o; echo " text //depot/....ini") | p4 typemap -i
	(p4 typemap -o; echo " text //depot/....config") | p4 typemap -i
	(p4 typemap -o; echo " text //depot/....cpp") | p4 typemap -i
	(p4 typemap -o; echo " text //depot/....h") | p4 typemap -i
	(p4 typemap -o; echo " text //depot/....c") | p4 typemap -i
	(p4 typemap -o; echo " text //depot/....cs") | p4 typemap -i
	(p4 typemap -o; echo " text //depot/....m") | p4 typemap -i
	(p4 typemap -o; echo " text //depot/....mm") | p4 typemap -i
	(p4 typemap -o; echo " text //depot/....py") | p4 typemap -i
	(p4 typemap -o; echo " binary+l //depot/....uasset") | p4 typemap -i
	(p4 typemap -o; echo " binary+l //depot/....umap") | p4 typemap -i
	(p4 typemap -o; echo " binary+l //depot/....upk") | p4 typemap -i
	(p4 typemap -o; echo " binary+l //depot/....udk") | p4 typemap -i
fi

echo >&2 "
==========
FINISHED
==========
"