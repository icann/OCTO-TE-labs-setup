#!/bin/bash

restart_shellinabox () {
  echo "Restarting shellinabox proccess..."
  systemctl restart shellinabox
  echo "---> shellinabox proccess started"
}
