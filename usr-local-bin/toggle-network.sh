#!/bin/bash
if nmcli networking | grep -q "enabled"; then
    nmcli networking off
else
    nmcli networking on
fi
