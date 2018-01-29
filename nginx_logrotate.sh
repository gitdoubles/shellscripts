#!/bin/bash
#
#nginx_logrotate.sh    
#
#Description: rotate the nginx access_log
#Write date: 2017/08/29
#Written by: doublexi
###############################################

DATE=`date +%Y%m%d`
NGINX_PID=`cat /usr/local/nginx/logs/nginx.pid`

#如果当前Nginx没有运行就退出
if [ "$?" != 0 ]
then
    echo "Nginx is not started!"
    exit 1;
fi

#nginx 日志所在的路径
LOG_PATH=‘/usr/local/nginx/logs/’
LOG_NAME='access'

mv ${LOG_PATH}${LOG_NAME}.log ${LOG_PATH}${LOG_NAME}${DATE}.log

#删除7天前的备份文件
function deloldbak()
{
    olddate=`date +"%Y%m%d" -d "-$1 day"`
    if [ -e "${LOG_PATH}${LOG_NAME}${olddate}.log" ]
    then
        rm -f ${LOG_PATH}${LOG_NAME}${olddate}.log
        echo "${LOG_PATH}${LOG_NAME}$olddate del OK"
    fi
}

#重载nginx配置，重新生成nginx日志文件
kill -USR1 $NGINX_PID

if [ "$?" == 0 ]
then
    deloldbak 7
    exit 0;
fi
}

