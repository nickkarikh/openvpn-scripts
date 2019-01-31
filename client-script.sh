#!/bin/bash
# This script is run every time any OpenVPN client connects or disconnects

# the following variables should be filled in during OpenVPN server installation
default_iface_name=DEFAULTIFACENAME
ovpn_server_public_ip=OVPNSERVERPUBLICIP
ovpn_iface_name=OVPNIFACENAME
ovpn_server_name=OVPNSERVERNAME

ovpn_client_private_ip=$ifconfig_pool_remote_ip
ovpn_client_name=$common_name
ovpn_client_fwd_filename=/etc/openvpn/${ovpn_server_name}/fwd-${ovpn_client_name}

case $script_type in
"client-connect")
        # Create temp file to indicate that client is connected
        echo "${ovpn_client_private_ip}" > /etc/openvpn/${ovpn_server_name}/ovpn-${ovpn_client_name}-connected
        # Allow forwarding from client to Internet
        /sbin/iptables -A FORWARD -i ${ovpn_iface_name} -s ${ovpn_client_private_ip} -j ACCEPT
        # Enable source address masquerading for the client
        /sbin/iptables -t nat -A POSTROUTING -o ${default_iface_name} -s ${ovpn_client_private_ip} -j MASQUERADE

        if [ -f "${ovpn_client_fwd_filename}" ]; then
          # Read client port forwardings and apply them
          while IFS='' read -r line; do
            fwd_protocol=`echo ${line} | cut -d" " -f1`
            fwd_server_port=`echo ${line} | cut -d" " -f2`
            fwd_client_port=`echo ${line} | cut -d" " -f3`
            /sbin/iptables -t nat -A PREROUTING -p ${fwd_protocol} -d ${ovpn_server_public_ip} --dport ${fwd_server_port} -j DNAT --to-destination ${ovpn_client_private_ip}:${fwd_client_port}
            /sbin/iptables -A FORWARD -p ${fwd_protocol} -o ${ovpn_iface_name} -d ${ovpn_client_private_ip} --dport ${fwd_client_port} -j ACCEPT
            /sbin/iptables -I INPUT 1 -p ${fwd_protocol} --dport ${fwd_server_port} -j ACCEPT
          done < "${ovpn_client_fwd_filename}"
        fi

        exit 0
        ;;

"client-disconnect")
        # Remove temp file
        rm -f /etc/openvpn/${ovpn_server_name}/ovpn-${ovpn_client_name}-connected
        # Undo all changes when client disconnects
        /sbin/iptables -D FORWARD -i ${ovpn_iface_name} -s ${ovpn_client_private_ip} -j ACCEPT
        /sbin/iptables -t nat -D POSTROUTING -o ${default_iface_name} -s ${ovpn_client_private_ip} -j MASQUERADE

        if [ -f "${ovpn_client_fwd_filename}" ]; then
          # Read client port forwardings and apply them
          while read -r line || [[ -n "$line" ]]; do
            fwd_protocol=`echo ${line} | cut -d" " -f1`
            fwd_server_port=`echo ${line} | cut -d" " -f2`
            fwd_client_port=`echo ${line} | cut -d" " -f3`
            /sbin/iptables -t nat -D PREROUTING -p ${fwd_protocol} -d ${ovpn_server_public_ip} --dport ${fwd_server_port} -j DNAT --to-destination ${ovpn_client_private_ip}:${fwd_client_port}
            /sbin/iptables -D FORWARD -p ${fwd_protocol} -o ${ovpn_iface_name} -d ${ovpn_client_private_ip} --dport ${fwd_client_port} -j ACCEPT
            /sbin/iptables -D INPUT -p ${fwd_protocol} --dport ${fwd_server_port} -j ACCEPT
          done < "${ovpn_client_fwd_filename}"
        fi
        exit 0
        ;;
esac

