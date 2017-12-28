#!/bin/bash
set -e

prj_path=$(cd $(dirname $0); pwd -P)
devops_prj_path="$prj_path/devops"
template_path="$devops_prj_path/template"   
config_path="$devops_prj_path/config"   

filebeat_image=docker.elastic.co/beats/filebeat:5.6.5
#filebeat_image=prima/filebeat:5.3.0
filebeat_container=filebeat

source $devops_prj_path/base.sh
app_storage_dir=/opt/data/filebeat
container_log_dir=/tmp/log
container_work_dir=/usr/share/filebeat

function run_jdy() {
    local args=''
    local jdy_runtime_dir=/opt/data/jenkins-9douyu/runtime
    args="$args -v $config_path/jdy.yml:$container_work_dir/filebeat.yml"
    #args="$args -v $config_path/jdy.yml:/filebeat.yml"
    args="$args -v $jdy_runtime_dir/storage:$container_log_dir/9douyu"
    args="$args -v $jdy_runtime_dir/logs/nginx:$container_log_dir/nginx"
    args="$args -v $jdy_runtime_dir/logs/php:$container_log_dir/php-fpm"
    args="$args -v $jdy_runtime_dir/logs/php-schedule:$container_log_dir/php-schedule"
    _run_filebeat "$args"
}

function run_test() {
    local args=''
    args="$args -v $config_path/test.yml:$container_work_dir/filebeat.yml"
    args="$args -v $prj_path/data/messages:$container_log_dir/message.log"
    _run_filebeat "$args"
}

function _run_filebeat() {
    ensure_dir $app_storage_dir/data/registry
    ensure_dir $app_storage_dir/logs

    chmod 777 $app_storage_dir/data/registry

    local host=`hostname`
    local args=$1


    args="-h $host $args"
    args="--restart=always $args"
    args="$args -v /etc/timezone:/etc/timezone"
    args="$args -v $app_storage_dir/data/registry/:/usr/share/filebeat/data/registry/"
    args="$args -v $app_storage_dir/logs:$container_work_dir/logs"

    run_cmd "docker run -itd --name $filebeat_container $args $filebeat_image bash -c 'filebeat -e -strict.perms=false'"
}

function to_filebeat() {
    local cmd='bash'
    run_cmd "docker exec -it $filebeat_container bash -c '$cmd'" 
}

function stop() {
    stop_container $filebeat_container
}

function restart_jdy() {
    stop
    run_jdy
}

function restart_test() {
    stop
    run_test
}

help() {
cat <<EOF
    Usage: manage.sh [options]

        run_jdy
        run_test
        stop
        restart_jdy
        restart_test
EOF
}
if [ -z "$action" ]; then
    action='help'
fi
$action "$@"
