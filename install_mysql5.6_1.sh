#!/bin/bash

GROUP_NAME=mysql  
USER_NAME=mysql  
MYSQLDB_BASE_HOME=/usr/local/mysql  
MYSQLDB_DATA_HOME=/data/mysql
MYSQL_VERSION="mysql-5.6.37-linux-glibc2.12-x86_64"
VERSION_NUM=`echo $MYSQL_VERSION|awk -F - '{print $2}'`
MYSQL_START_SCRIPTNAME=mysql
ERROR_EXIT=65

#==============================
# Function--> echo motd
#==============================
Echo_motd()
{
    echo "========================================"
    echo "Setup $MYSQL_VERSION on your system..."
    echo "You will input mysql's root password later..."
    echo "======================================="
    sleep 1
}

#==============================
# Function--> add user and group
#==============================
Add_user()
{
    # check if user is root
    if [ $(id -u) != "0" ];then  
        echo "Error: You must be root to run this script!"  
        exit 1  
    fi

    # addGroup    
    if [ -z $(cat /etc/group|awk -F: '{print $1}'| grep -w "$GROUP_NAME") ]  
    then  
         groupadd -g 27 $GROUP_NAME  
        if(( $? == 0 ))  
        then  
            echo "group $GROUP_NAME add sucessfully!"  
        fi     
    else  
        echo "$GROUP_NAME is exsits"  
    fi   
  
    # addUser    
    if [ -z $(cat /etc/passwd|awk -F: '{print $1}'| grep -w "$USE_NAME") ]  
    then  
        adduser  -u 27 -g $GROUP_NAME $USER_NAME  
        if (( $? == 0 ))  
        then  
            echo "user $USER_NAME add sucessfully!"  
        fi  
    else  
        echo "$USER_NAME is exsits"  
    fi
}

#==============================
# Function-->download mysql
#==============================
Down_mysql()
{
    # download mysql  
    rm -rf /tmp/${MYSQL_VERSION}*  
    wget https://dev.mysql.com/get/Downloads/MySQL-5.6/${MYSQL_VERSION}.tar.gz -P /tmp  
    if(( $? == 0 ))  
    then   
        echo "MySQL DownLoad sucessfully!"   
    else   
        echo "MySQL DownLoad failed!"  
        exit $ERROR_EXIT  
    fi  
}
#==============================
# Function-->create basedir and datadir
#==============================
Add_dir()
{    
    cd /tmp  
    tar xzvf ${MYSQL_VERSION}.tar.gz  
    # if the basedir ${MYSQLDB_BASE_HOME} is exsits.....
    if [ -d "${MYSQLDB_BASE_HOME}" ]
    then
        echo "The basedir ${MYSQLDB_BASE_HOME} is exsits"
        if [ -d "/usr/local/${MYSQL_START_SCRIPTNAME}" ]
        then
            echo "The basedir /usr/local/${MYSQL_START_SCRIPTNAME} also exsits,please modify the basedir..."
            exit 1
        else
            MYSQLDB_BASE_HOME=/usr/local/$MYSQL_START_SCRIPTNAME
            mv ${MYSQL_VERSION} ${MYSQLDB_BASE_HOME}
        fi
    else
        mv ${MYSQL_VERSION} ${MYSQLDB_BASE_HOME}
    fi
    # if the datadir ${MYSQLDB_DATA_HOME} is exsits.....
    if [ -d "${MYSQLDB_DATA_HOME}" ]
    then
        echo "The datadir $MYSQLDB_DATA_HOME is exsits"
        if [ -d "/data/${MYSQL_START_SCRIPTNAME}" ]
        then
            echo "The datadir /data/${MYSQL_START_SCRIPTNAME} also exsits,please modify the datadir..."
            exit 1
        else
            MYSQLDB_DATA_HOME=/data/$MYSQL_START_SCRIPTNAME
            mkdir -p ${MYSQLDB_DATA_HOME}
        fi 
    else
        mkdir -p ${MYSQLDB_DATA_HOME}
    fi

    # add privileges to the basedir and datadir
    chown -R USER_NAME:GROUP_NAME ${MYSQLDB_BASE_HOME}
    chown -R USER_NAME:GROUP_NAME ${MYSQLDB_DATA_HOME}
}

#==============================
# Function-->install mysql
#==============================
Install_mysql()
{
    yum install -y perl-Module-Install.noarch
    # initialize the mysql
    ${MYSQLDB_BASE_HOME}/scripts/mysql_install_db --user=$USER_NAME --datadir=${MYSQLDB_DATA_HOME} --basedir=${MYSQLDB_BASE_HOME}
    if(( $? == 0 ))
    then
        echo "MySQL Initialize sucessfully!"   
    else
        echo "MySQL Initialize failed!"  
        exit $ERROR_EXIT
    fi

    # modify the my.cnf
    cd ${MYSQLDB_BASE_HOME}
    if [ -s my.cnf ];then
        echo "the my.cnf is exsits,it will be overwrite!"
        echo "[mysqld]
 basedir = $MYSQLDB_BASE_HOME
 datadir = $MYSQLDB_DATA_HOME
 port = 3307
 socket = ${MYSQLDB_DATA_HOME}/mysql.sock
 innodb_file_per_table=1
 default-storage-engine=INNODB
 explicit_defaults_for_timestamp=true
 symbolic-links=0
 max_connections=1000

[mysqld_safe]
log-error=${MYSQLDB_DATA_HOME}/mysqld.log
pid-file=${MYSQLDB_DATA_HOME}/mysqld.pid" >./my.cnf
    fi
    [ $? -eq 0 ] && echo "my.cnf created successfull!!"
    if [ -s /etc/my.cnf ]; then  
        mv /etc/my.cnf /etc/my.cnf.`date +%Y%m%d%H%M%S`.bak  
    fi 
    cp ${MYSQLDB_BASE_HOME}/my.cnf /etc/my.cnf
    if(( $? == 0 ))
    then
        echo "/etc/my.cnf created  sucessfully!"   
    else
        echo "/etc/my.cnf created failed!"  
    fi
    # add the bin to the path
    echo "add the $MYSQLDB_BASE_HOME/bin to the path!"
    cat >> /etc/profile <<EOF  
export PATH="$PATH:${MYSQLDB_BASE_HOME}/bin"
EOF
    source /etc/profile
}
#==============================
# Function-->start mysql
#==============================
Start_mysql()
{
    # add the service to the system service directory
    echo "Add the service to the system as mysql5.6,you can start the service by the command 'service mysql5.6 start' !"
    cp ${MYSQLDB_BASE_HOME}/support-files/mysql.server /etc/init.d/$MYSQL_START_SCRIPTNAME
    sed -i "s!^basedir=.*!basedir=$MYSQLDB_BASE_HOME!g" /etc/init.d/$MYSQL_START_SCRIPTNAME
    sed -i "s!^datadir=.*!datadir=$MYSQLDB_DATA_HOME!g" /etc/init.d/$MYSQL_START_SCRIPTNAME
    # add to the system service control and it will auto start when the system restart!
    chkconfig --add $MYSQL_START_SCRIPTNAME
    chkconfig $MYSQL_START_SCRIPTNAME on
    service $MYSQL_START_SCRIPTNAME start
}
#==============================
# Function-->create mysql's user and set password
#==============================
Create_user()
{
    # add the symbol link for the mysql.sock
    ln -s ${MYSQLDB_DATA_HOME}/mysql.sock /tmp/mysql.sock
    if(( $? == 0 ))
    then
        MYSQL_CONNECT_PARAMETER="-uroot  -t"   
    else
        MYSQL_CONNECT_PARAMETER="-uroot  -t -S ${MYSQLDB_DATA_HOME}/mysql.sock"  
    fi
    # create mysql's user and set root's password
    read -p "Input Default Mysql user root's password: " MYSQL_PASSWORD
    HOST_NAME=`hostname`
    ${MYSQLDB_BASE_HOME}/bin/mysql $MYSQL_CONNECT_PARAMETER  <<EOF 
    select Host,User,Password from mysql.user;
    CREATE USER 'roottest1'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
    GRANT ALL PRIVILEGES ON *.* TO'root'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' WITH GRANT OPTION;
    update mysql.user set password=password('$MYSQL_PASSWORD') where User="root" and Host="localhost";
    update mysql.user set password=password('$MYSQL_PASSWORD') where User="root" and Host="127.0.0.1";
    update mysql.user set password=password('$MYSQL_PASSWORD') where User="root" and Host="::1";
    update mysql.user set password=password('$MYSQL_PASSWORD') where User="root" and Host="$HOST_NAME";
    flush privileges;
    select Host,User,Password from mysql.user;
EOF
}

#==============================
# Function-->main function,the entrance of the script
#==============================
Main()
{   
    Echo_motd;
    Add_user;
    Down_mysql;
    Add_dir;
    Install_mysql;
    Start_mysql;
    Create_user;
}

Main;
