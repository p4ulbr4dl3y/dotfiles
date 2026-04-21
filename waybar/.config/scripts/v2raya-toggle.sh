#!/bin/bash
if /usr/bin/systemctl is-active --quiet v2raya; then
    sudo /usr/bin/systemctl stop v2raya
else
    sudo /usr/bin/systemctl start v2raya
fi
pkill -RTMIN+8 waybar
