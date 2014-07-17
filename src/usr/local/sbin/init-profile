#!/bin/sh -e

# This script can be executed several times for a given
# profile, but does not support switching between different
# profiles (currently irrelevant).

profile="$1"
save=/var/run/usage-profile


case "${profile}" in
    # Non-anonymous connections (unless using explicit URLs)
    noanon)
        # Privoxy: disable default forwarding to Tor SOCKS
        sed -i 's/^forward-socks5 \+\/ /# &/'         /etc/privoxy/config

        # SSH: disable Tor SOCKS proxy
        sed -i 's/^ProxyCommand\>/# &/'               /home/anon/config/ssh/config

        # HexChat: disable Tor SOCKS proxy, and enable automatic DCC IP,
        #          restore default servers list
        sed -i 's/^\(net_proxy_type =\) 3$/\1 0/'     /home/anon/config/hexchat/hexchat.conf
        sed -i 's/^\(dcc_ip_from_server =\) 0$/\1 1/' /home/anon/config/hexchat/hexchat.conf
        rm -f                                         /home/anon/config/hexchat/servlist.conf

        # GnuPG: replace .onion keyserver
        sed -i 's/^keyserver\>/# &/; s/^# \[noanon\] //' /home/anon/config/pgp/gpg.conf

        # Browser: disable Tor SOCKS proxy, replace default homepage and .onion search bookmarks
        sed -i 's/\("network\.proxy\.type",\) 1/\1 5/' /home/anon/config/firefox/profile.anon/prefs.js
        sed -i 's/browser\.html/browser-noanon.html/'  /home/anon/config/firefox/profile.anon/prefs.js
        # sed -i 's@http://3g2upl4pq6kufc4m.onion@https://duckduckgo.com@'

        rm -f /etc/dconf/db/anon
        dconf update

        # Unsafe Browser: remove menu icon
        rm -f /home/anon/config/local/applications/unsafe-browser.desktop

        # Remove torification wrappers
        rm -f /home/anon/bin/wrappers/whois
        ;;


    *)
        echo "Unknown profile"
        exit 1
        ;;
esac


echo "${profile}" > ${save}
