#!/bin/bash
nc -vz {SIEM_IP} 9997 2> /var/log/siem.log
nc -vz {ASSETMGR_IP} 17472 2> /var/log/assetmgr.log
