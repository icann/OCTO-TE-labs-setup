#!/bin/bash

stop_webssh () {
    echo "Stoping webssh proccess..."
    systemctl is-active --quiet wsshd && systemctl stop wsshd
    echo "---> webssh proccess stoped"
}

start_webssh () {
    echo "Starting webssh proccess..."
    systemctl start wsshd
    echo "---> webssh proccess started"
}
