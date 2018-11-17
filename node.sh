#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
clear
echo
echo "############################"
echo "# Author: SpereSheldd      #"
echo "############################"
echo
read -p "请输入此节点的ID: " nodeid
read -p "请输入面板域名: " host
read -p "请输入验证密钥: " pass
read -p "请输入混淆后缀: " suffix
read -p "请输入混淆参数: " prefix
if [ -z "${pass}" ];then  
    pass=mupass
fi
if [ -z "${suffix}" ];then  
    suffix=jd.hk
fi
if [ -z "${prefix}" ];then  
    prefix=%4m-dje%id.%suffix
fi
echo "开始部署"
sleep 2s
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
cd /root
apt-get update
apt-get -y install build-essential wget python-dev libffi-dev openssl python-pip libssl-dev zip unzip git
wget https://github.com/jedisct1/libsodium/releases/download/1.0.10/libsodium-1.0.10.tar.gz
tar xf libsodium-1.0.10.tar.gz && cd libsodium-1.0.10
./configure && make -j2 && make install
ldconfig
cd .. && rm -f libsodium-1.0.10.tar.gz && rm -rf libsodium-1.0.10
git clone -b manyuser https://github.com/SpereShelde/shadowsocks.git
cd shadowsocks
pip install --upgrade setuptools
pip install -r requirements.txt
cp apiconfig.py userapiconfig.py
cp config.json user-config.json
chmod +x *.sh
echo "# Config
NODE_ID = ${nodeid}
# hour,set 0 to disable
SPEEDTEST = 0
CLOUDSAFE = 1
ANTISSATTACK = 0
AUTOEXEC = 0
MU_SUFFIX = ${suffix}
MU_REGEX = ${prefix}
SERVER_PUB_ADDR = '127.0.0.1'  # mujson_mgr need this to generate ssr link
API_INTERFACE = 'modwebapi'  # glzjinmod, modwebapi
WEBAPI_URL = '${host}'
WEBAPI_TOKEN = '${pass}'
# mudb
MUDB_FILE = 'mudb.json'
# Mysql
MYSQL_HOST = ''
MYSQL_PORT = 3306
MYSQL_USER = ''
MYSQL_PASS = ''
MYSQL_DB = ''
MYSQL_SSL_ENABLE = 0
MYSQL_SSL_CA = ''
MYSQL_SSL_CERT = ''
MYSQL_SSL_KEY = ''
# API
API_HOST = '127.0.0.1'
API_PORT = 80
API_PATH = '/mu/v2/'
API_TOKEN = 'abcdef'
API_UPDATE_TIME = 60
# Manager (ignore this)
MANAGE_PASS = 'ss233333333'
# if you want manage in other server you should set this value to global ip
MANAGE_BIND_IP = '127.0.0.1'
# make sure this port is idle
MANAGE_PORT = 23333
# Safety
IP_MD5_SALT = 'randomforsafety'" > /root/shadowsocks/userapiconfig.py
apt-get install supervisor -y
echo "[program:ssr]
command=python /root/shadowsocks/server.py 
autorestart=true
autostart=true
user=root" > /etc/supervisor/conf.d/ssr.conf
echo "ulimit -n 1024000" >> /etc/default/supervisor
/etc/init.d/supervisor restart
echo -e "8.8.8.8 53
8.8.4.4 53" > /root/shadowsocks/dns.conf
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
supervisorctl restart ssr


echo "对接完成!"
echo "查看日志:supervisorctl tail -f ssr stderr"
