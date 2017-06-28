#!/bin/bash
set -e

prj_path=$(cd $(dirname $0); pwd -P)
devops_prj_path="$prj_path/devops"
template_path="$devops_prj_path/template"   
config_path="$devops_prj_path/config"   

filebeat_image=prima/filebeat:5.3.0
filebeat_container=filebeat

source $devops_prj_path/base.sh


function run() {

    ensure_permissions $config_path/filebeat.yml 
    local host=`hostname`

    local args='--restart=always'
    args="$args -h $host"
    args="$args -v $config_path/filebeat.yml:/filebeat.yml"
    args="$args -v /opt/data/jenkins-9douyu/runtime/storage:/tmp/log/9douyu"
    args="$args -v /opt/data/jenkins-9douyu/runtime/logs/nginx:/tmp/log/nginx"
    run_cmd "docker run -d $args --name $filebeat_container $filebeat_image"
}

function stop() {
    stop_container $filebeat_container
}

function restart() {
    stop
    run
}

help() {
cat <<EOF
    Usage: manage.sh [options]

        run
        stop
        restart
EOF
}

ALL_COMMANDS=""
ALL_COMMANDS="$ALL_COMMANDS run stop restart"

list_contains ALL_COMMANDS "$action" || action=help
$action "$@"
