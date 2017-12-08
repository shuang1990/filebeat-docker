#!/bin/bash
set -e

prj_path=$(cd $(dirname $0); pwd -P)
devops_prj_path="$prj_path/devops"
template_path="$devops_prj_path/template"   
config_path="$devops_prj_path/config"   

filebeat_image=docker.elastic.co/beats/filebeat:5.6.5
filebeat_container=filebeat

source $devops_prj_path/base.sh
app_storage_dir=/opt/data/filebeat

function run_9dy() {

    local host=`hostname`
    local args='--restart=always'

    args="$args -h $host"
    args="$args -v $app_storage_dir/data:/usr/share/filebeat/data"
    args="$args -v $app_storage_dir/logs:/usr/share/filebeat/logs"
    args="$args -v $config_path/jdy.yml:/usr/share/filebeat/filebeat.yml"
    args="$args -v /opt/data/jenkins-9douyu/runtime/storage:/tmp/log/9douyu"
    args="$args -v /opt/data/jenkins-9douyu/runtime/logs/nginx:/tmp/log/nginx"
    args="$args -v /opt/data/jenkins-9douyu/runtime/logs/php:/tmp/log/php-fpm"
    run_cmd "docker run -itd $args -estrict.perms=false --name $filebeat_container $filebeat_image"
}

function run_test() {

    local host=`hostname`
    local args='--restart=always'

    args="$args -h $host"
    args="$args -v $config_path/test.yml:/usr/share/filebeat/filebeat.yml"
    args="$args -v /var/log/syslog:/tmp/log/"
    run_cmd "docker run -itd $args -estrict.perms=false --name $filebeat_container $filebeat_image"
}

function stop() {
    stop_container $filebeat_container
}

function restart_9dy() {
    stop
    run_9dy
}

help() {
cat <<EOF
    Usage: manage.sh [options]

        run_9dy
        run_test
        stop
        restart
EOF
}
if [ -z "$action" ]; then
    action='help'
fi
$action "$@"
