OpenVPN Installation Script
---------------------------

This script automates OpenVPN server installation on Linux.
There are also port forwarding scripts which allow to map server ports to client
in case if client doesn't have public IP address or don't want to expose itself completely.

1. Copy archive (or all files) to somewhere on the server (like /opt/ovpn)
   Add eXecute permissions on script files:
   `chmod +x client-script.sh ovpn-client-add ovpn-client-remove ovpn-fwd-add ovpn-fwd-remove ovpn-server-install ovpn-server-uninstall`

2. ATTENTION! Promote yourself to superuser:
   `sudo su -`
   This is neccessary as all scripts have to be run by root.

3. cd to scripts directory:
   `cd /opt/ovpn`

4. Edit "ovpn-server-config" file. Three last variables can be empty. In that case,
   the scripts will try to auto-detect their values.
   *Warning*: If you have no public IP address set on your network interfaces or
   have default route on non-public interface, then you should set all variables manually.
   In most cases, default settings should work fine.

5. Run ovpn-server-install script:
   `./ovpn-server-install`

6. Once the installation is completed, you can then create a new user account:
   `./ovpn-client-add client1`
   Where client1 is a common name of the client account (e.g. webserver, sqlserver, etc.)
   The configuration file for the client will be created in the same directory
   (e.g. client1.ovpn)

7. Transfer client .ovpn file to the OpenVPN client machine. This file contains all the
   settings, keys and certificates neccessary to connect.
   In case of Linux:
   1. Install OpenVPN: `sudo apt install openvpn`
   2. rename .ovpn file to .conf file (e.g.: client1.conf) and place in /etc/openvpn
   3. `sudo systemctl enable openvpn@client1 && sudo systemctl start openvpn@client1`
   4. you should now be connected and your default gateway should be changed to this VPN

8. To add port forwarding, run:
  `./ovpn-fwd-add client1 2222 22 tcp`
  This would create all neccessary iptables rules for tcp redirection from server:2222 to client1:22
  To remove port forwarding, run:
  `./ovpn-fwd-remove client1 2222 22 tcp`
  Port forwarding settings are kept in /etc/openvpn/VPNSERVERNAME/fwd-CLIENTNAME files

Nick Karikh
github@knn.me
