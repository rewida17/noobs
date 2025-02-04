#!/bin/bash
# Create OpenVPN server
# Autor: Radoslaw Karasinski
# Update: Dawid Pospiech
# Usage: you can pass --port and/or --host variables to script, otherwise
# defaults will be choosen.

# Helper to keep essential code tight
function get-hostname
{
    # Return hostname as plaintext
    FQDN="$(curl -s https://ipinfo.io/hostname)"

    if [[ "$FQDN" =~ ^.*[.]mikr[.]us$ ]]; then
        host=$(echo "$FQDN" | cut -f1 -d '.' )
        echo "$host"
        export host="$host"
        
    elif [[ ! "$FQDN" =~ ^.*[.]mikr[.]us ]]; then
        echo
        echo "Valid hostname is still not known : ( "
        echo
        echo "You can set it by yourself with command:"
        echo "export host=<replace with server name eg srv100>"
        echo
        echo "example connection command:"
        echo "ssh root@srv100.mikr.us -p12333"
        echo ""
        echo "export host='srv100'"
        echo "After that you can try rerun $0"
        exit 1

    fi

}

# some bash magic: https://brianchildress.co/named-parameters-in-bash/
while [ $# -gt 0 ]; do
    if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare "$param"="$2"
    fi
  shift
done
if [[ ! -c /dev/net/tun ]]; then
    echo "TUN/TAP not activated!"
    exit 1
fi

if [[ -z "$port" ]]; then
    port="$(( 20000 + $(hostname | grep -o '[0-9]\+') ))"
fi

if lsof -i:$port > /dev/null 2>&1 ; then
    echo "Port $port is already used, try different one"
    exit 1
fi

if [ -z "$host" ]; then
    key="$( hostname | grep -o '^[a-z]' )"
    declare -A hosts
    hosts["a"]="srv03"
    hosts["b"]="srv04"
    hosts["e"]="srv07"
    hosts["f"]="srv08"
    hosts["g"]="srv09"
    hosts["h"]="srv10"
    hosts["i"]="srv11"
    hosts["j"]="srv12"
    hosts["k"]="srv14"
    hosts["l"]="srv15"
    hosts["m"]="srv16"
    hosts["p"]="srv19"
    hosts["q"]="mini01"
    hosts["x"]="maluch"
    host="${hosts[$key]}"

    if [ -z "$host" ]
    then

        echo "Server hostname not known for key: $key"
        echo
        echo "Trying to get correct value with helper utility:"
        get-hostname

    fi
    host="$host.mikr.us"
fi


echo "Using hostname $host and port $port for configuration."

echo "Download configuration script and run it."
curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
chmod +x openvpn-install.sh

export AUTO_INSTALL=y
export APPROVE_INSTALL=y
export APPROVE_IP=y
export ENDPOINT="$host"
export IPV6_SUPPORT=n
export PORT_CHOICE=2
export PORT=$port
export PROTOCOL_CHOICE=1
export DNS=1
export COMPRESSION_ENABLED=n
export CUSTOMIZE_ENC=n
export PASS=1

./openvpn-install.sh

mv openvpn-install.sh ~/openvpn-install.sh
echo "In order to add new clients, run ~/openvpn-install.sh"
