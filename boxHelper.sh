#!/bin/bash

#=================================================
#	Description: BoxHelper
#	Version: 0.0.1
#	Author: SpereShelde
#=================================================

#获取PID
check_pid(){
	PID=`ps -ef| grep "BoxHelper"| grep -v grep| grep -v ".sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}'`
}
install_boxhelper(){
    echo -e "开始下载 BoxHelper ..."
    rm -rf BoxHelper
    mkdir BoxHelper
    wget --no-check-certificate -qO BoxHelper.jar https://raw.githubusercontent.com/SpereShelde/BoxHelper/master/BoxHelper.jar
    mv BoxHelper.jar BoxHelper
    touch BoxHelper/config.json
    mkdir BoxHelper/cookies
    jdk_status=$(java -version 2>&1)
    if [[ ${jdk_status/"1.8"//} == $jdk_status ]]
    then
        echo "没有安装 JDK 1.8, 开始安装 ..."
        wget --no-check-certificate -qO java.sh https://raw.githubusercontent.com/SpereShelde/Scripts/master/java.sh
        chomod +x java.sh
        mv java.sh BoxHelper
        bash BoxHelper/java.sh
    fi
    echo -e "开始编辑 BoxHelper 配置文件 ..."
    add_config
    start_boxhelper
}
add_config(){
    echo
    echo -e "为了简化操作，请提前查看Wiki: https://github.com/SpereShelde/BoxHelper/wiki"
    echo
    echo -e " 输入 Deluge 的 WebUI 地址："
    read -e -p " (默认: 不设置 Deluge):" de_url

    if  [ ! -n "$de_url" ] ;then
        echo "不设置 Deluge ..."
    else
        echo -e " 输入 Deluge WebUI 的登录密码："
        read -e -p " (默认: 取消):" de_passwd
        if  [ ! -n "$de_passwd" ] ;then
            echo "已取消..." && exit 1
        else
            echo -e " 输入 Deluge 管辖的种子体积和的上限，GB："
            read -e -p " (默认: 取消):" de_total
            if  [ ! -n "$de_total" ] ;then
                echo "已取消..." && exit 1
            else
                echo -e " 输入超出上述上限后的删种策略，slow，add，small，large，ratio："
                read -e -p " (默认: large):" de_action
                [[ -z "$de_action" ]] && de_action="large"
                echo -e " 请输入 BoxHelper 按照上述策略删除的种子个数:"
                read -e -p " (默认: 2):" de_num
                [[ -z "$de_num" ]] && de_num=2
            fi
        fi
    fi

    echo
    echo -e " 输入 qBittorrent 的 WebUI 地址："
    read -e -p " (默认: 不设置 qBittorrent):" qb_url

    if  [ ! -n "$qb_url" ] ;then
    echo "不设置 qBittorrent ..."
    else
    echo -e " 输入 qBittorrent WebUI 的账号和密码，以-分隔，如admin-admin："
    read -e -p " (默认: 取消):" qb_sid
    if  [ ! -n "$qb_sid" ] ;then
    echo "已取消..." && exit 1
    else
    echo -e " 输入 qBittorrent 中 BoxHelper 下载的种子体积和的上限，GB："
    read -e -p " (默认: 取消):" qb_total
    if  [ ! -n "$qb_total" ] ;then
    echo "已取消..." && exit 1
    else
    echo -e " 输入超出上述上限后的删种策略，slow，add，complete，active，small，large，ratio："
    read -e -p " (默认: large):" qb_action
    [[ -z "$qb_action" ]] && qb_action="large"
    echo -e " 请输入 BoxHelper 按照上述策略删除的种子个数:"
    read -e -p " (默认: 2):" qb_num
    [[ -z "$qb_num" ]] && qb_num=2
    fi
    fi
    fi

    echo -e " 请输入 BoxHelper 监听周期, 单位为秒:"
    read -e -p " (默认: 20):" cycle
    [[ -z "$cycle" ]] && cycle=20

    add_urls

    page_len=${#page[*]}

    let page_len--
    i=0
    while [ $i -lt $page_len ]
        do
        if [ $i == 0 ]
        then
           urls="[\"${page[$i]}\", ${lower[$i]}, ${higher[$i]}, \"${cli[$i]}\", ${download[$i]}, ${upload[$i]}, ${load[$i]}]"
        else
           urls=$urls", [\"${page[$i]}\", ${lower[$i]}, ${higher[$i]}, \"${cli[$i]}\", ${download[$i]}, ${upload[$i]}, ${load[$i]}]"
        fi
        let i++
    done

    echo "{">BoxHelper/config.json
    if  [ -n "$de_url" ] ;then
        echo "\"de_config\":[\"$de_url\", \"$de_passwd\", $de_total, \"$de_action\", $de_num],">>BoxHelper/config.json
    fi
    if  [ -n "$qb_url" ] ;then
        echo "\"qb_config\":[\"$qb_url\", \"$qb_sid\", $qb_total, \"$qb_action\", $qb_num],">>BoxHelper/config.json
    fi
    echo "\"url_size_speed_cli\":[">>BoxHelper/config.json
    echo $urls
    echo "  $urls">>BoxHelper/config.json
    echo "],">>BoxHelper/config.json
    echo "\"cycle\":$cycle">>BoxHelper/config.json
    echo "}">>BoxHelper/config.json

}
add_urls(){
    n=0
    while true
    do
    echo -e " 请输入要监听的种子页面:"
    if [ $n == 0 ]
    then
    read -e -p " (默认: 取消):" page[$n]
    [[ -z "${page[$n]}" ]] && echo -e "取消..." && exit 1
    else
    read -e -p " (默认: 停止添加):" page[$n]
    [[ -z "${page[$n]}" ]] && echo -e "停止添加监控页面..." && break
    fi
domain[$n]=$(echo ${page[$n]} | awk -F'[/:]' '{print $4}')
if [ -e BoxHelper/cookies/${domain[$n]}.json ]; then
echo " 存有此站点的Cookie, 是否修改原Cookie？[y/n]:"
read -e edit
if [[ "${edit}" == [Yy] ]]
then
echo " 请以Json格式输入此站点的Cookie:"
read -e -d "]" -p  " (默认: 取消):"  cookie
echo "${cookie}]">BoxHelper/cookies/${domain[$n]}.json
fi
else
echo " 请以Json格式输入此站点的Cookie:"
read -e -d "]" -p  " (默认: 取消):"  cookie
[[ -z "${cookie}]" ]] && echo -e "已取消..." && exit 1
echo "$cookie]">BoxHelper/cookies/${domain[$n]}.json
fi
echo -e " 请输入此页面筛选的种子最小体积, 单位为GB, -1 为不限制:"
read -e -p " (默认: -1):" lower[$n]
[[ -z "${lower[$n]}" ]] && lower[$n]=-1
echo -e " 请输入此页面筛选的种子最大体积, 单位为GB, -1 为不限制:"
read -e -p " (默认: -1):" higher[$n]
[[ -z "${higher[$n]}" ]] && higher[$n]=-1
echo -e " 请输入下载此页面种子使用的客户端，qb，de:"
read -e -p " (默认: qb):" cli[$n]
[[ -z "${cli[$n]}" ]] && cli[$n]="qb"
echo -e " 请输入此页面下载的种子下载限速, 单位为MB/s, -1 为不限制:"
read -e -p " (默认: -1):" download[$n]
[[ -z "${download[$n]}" ]] && download[$n]=-1
echo -e " 请输入此页面下载的种子上传限速, 单位为MB/s, -1 为不限制:"
read -e -p " (默认: -1):" upload[$n]
[[ -z "${upload[$n]}" ]] && upload[$n]=-1
echo -e " 请输入是否加载此页面已存在的 Free 种[y/n]:"
read -e -p " (默认: n):" load[$n]
if [[ "${load[$n]}" == [Yy] ]]; then load[$n]=true
else
load[$n]=false
fi
    let n++
    done
    let n--
}
get_config(){
    has_de=$(cat BoxHelper/config.json | jq 'has("de_config")')
    has_qb=$(cat BoxHelper/config.json | jq 'has("qb_config")')
    if [ $has_de == true ]; then
        de_config=$(cat BoxHelper/config.json | jq '.de_config[]')
        de_cfg_url=$(echo ${de_config} | awk -F' ' '{print $1}')
        de_cfg_passwd=$(echo ${de_config} | awk -F' ' '{print $2}')
        de_cfg_total=$(echo ${de_config} | awk -F' ' '{print $3}')
        de_cfg_action=$(echo ${de_config} | awk -F' ' '{print $4}')
        de_cfg_num=$(echo ${de_config} | awk -F' ' '{print $5}')
    fi
    if [ $has_qb == true ]; then
        qb_config=$(cat BoxHelper/config.json | jq '.qb_config[]')
        qb_cfg_url=$(echo ${qb_config} | awk -F' ' '{print $1}')
        qb_cfg_passwd=$(echo ${qb_config} | awk -F' ' '{print $2}')
        qb_cfg_total=$(echo ${qb_config} | awk -F' ' '{print $3}')
        qb_cfg_action=$(echo ${qb_config} | awk -F' ' '{print $4}')
        qb_cfg_num=$(echo ${qb_config} | awk -F' ' '{print $5}')
    fi
    urls=$(cat BoxHelper/config.json | jq '.url_size_speed_cli[][]')
    cycle=$(cat BoxHelper/config.json | jq '.cycle')
    array=(${urls//'" "'/ })
    config_page_num=`echo $urls | grep -o '" "' |wc -l`
    let config_page_num++
    let config_page_num/=7
}
edit_boxhelper(){
    jq_status=$(jq --help)
    if [[ -z ${jq_status} ]]; then
        echo "准备中 ..."
        wget 'https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64'
        mv jq-linux64 jq
        chmod +x jq
        mv jq /bin/
    fi
    get_config
    echo " 当前配置:"
    if [ $has_de == true ]; then
    echo "  Deluge WebUI 地址             : $de_cfg_url"
    echo "  Deluge WebUI 登录密码          : $de_cfg_passwd"
    echo "  Deluge 磁盘使用上限             : $de_cfg_total GB"
    echo "  Deluge 删种策略                : $de_cfg_action"
    #--!--#
    echo "  Deluge 删种个数                : $de_cfg_num 个"
    fi
    if [ $has_qb == true ]; then
    echo "  qBittorrent WebUI 地址        : $de_cfg_url"
    echo "  qBittorrent WebUI 账号密码     : $de_cfg_passwd"
    echo "  qBittorrent 磁盘使用上限        : $de_cfg_total GB"
    echo "  qBittorrent 删种策略           : $de_cfg_action"
    #--!--#
    echo "  qBittorrent 删种个数           : $de_cfg_num 个"
    fi
    echo "  BoxHelper 的监听周期           : $cycle 秒"
    i=0
    len=${#array[*]}
    while [ $i -lt $len ]
        do
           echo "  BoxHelper 监听页面 $[i/7+1]  : 监听 ${array[$i]} 内 大于 ${array[$[i+1]]} GB 且小于 ${array[$[i+2]]} GB 的种子， 使用 ${array[$[i+3]]} 客户端下载，限制下载速度为 ${array[$[i+4]]} MB/s 上传速度为 ${array[$[i+5]]} MB/s， 是否加载之前的 Free 种：${array[$[i+6]]}"
           let i+=7
    done
    echo -e "
 ${Green_font_prefix} 1.${Font_color_suffix} 修改 BoxHelper 使用的客户端
 ${Green_font_prefix} 2.${Font_color_suffix} 修改 BoxHelper 的监听周期
 ${Green_font_prefix} 3.${Font_color_suffix} 修改 BoxHelper 的监听页面及相关限制" && echo
    read -e -p " 请输入数字 [1-3]:" num
    case "$num" in
    	1)
    	edit_cli
    	;;
    	2)
    	edit_cycle
    	;;
    	3)
    	edit_urls
        ;;
    	*)
    	echo " 请输入正确数字 [1-3]"
    	;;
    esac
    echo
    echo -e " 是否重启 BoxHelper 来加载配置 [y/n]:"
    read -e -p " (默认: y):" reboot
    if [[ "${reboot}" == [Yy] ]]; then restart_boxhelper
        else
            exit 1
    fi

}
edit_cli(){

    get_config
    echo " 当前配置:"
    if [ $has_de == true ]; then
    echo "  Deluge WebUI 地址             : $de_cfg_url"
    echo "  Deluge WebUI 登录密码          : $de_cfg_passwd"
    echo "  Deluge 磁盘使用上限             : $de_cfg_total GB"
    echo "  Deluge 删种策略                : $de_cfg_action"
    #--!--#
    echo "  Deluge 删种个数                : $de_cfg_num 个"
    fi
    if [ $has_qb == true ]; then
    echo "  qBittorrent WebUI 地址        : $de_cfg_url"
    echo "  qBittorrent WebUI 账号密码     : $de_cfg_passwd"
    echo "  qBittorrent 磁盘使用上限        : $de_cfg_total GB"
    echo "  qBittorrent 删种策略           : $de_cfg_action"
    #--!--#
    echo "  qBittorrent 删种个数           : $de_cfg_num 个"
    fi

    echo
    if [ $has_de == true ]; then
        echo -e " ${Green_font_prefix} 1.${Font_color_suffix} 修改 Deluge 相关配置"
    fi
    if [ $has_qb == true ]; then
        echo -e " ${Green_font_prefix} 2.${Font_color_suffix} 修改 qBittorrent 相关配置"
    fi
    read -e -p " 请输入数字 [1-2]:" num
    case "$num" in
    1)
    edit_de
    ;;
    2)
    edit_qb
    ;;
    *)
    echo " 请输入正确数字 [1-2]"
    ;;
    esac
}
edit_de(){
echo
echo -e " 输入 Deluge 的 WebUI 地址："
read -e -p " (默认: 取消):" de_url
if  [ ! -n "$de_url" ] ;then
echo "已取消..." && exit 1
else
echo -e " 输入 Deluge WebUI 的登录密码："
read -e -p " (默认: 取消):" de_passwd
if  [ ! -n "$de_passwd" ] ;then
echo "已取消..." && exit 1
else
echo -e " 输入 Deluge 管辖的种子体积和的上限，GB："
read -e -p " (默认: 取消):" de_total
if  [ ! -n "$de_total" ] ;then
echo "已取消..." && exit 1
else
echo -e " 输入超出上述上限后的删种策略，slow，add，small，large，ratio："
read -e -p " (默认: large):" de_action
[[ -z "$de_action" ]] && de_action="large"
echo -e " 请输入 BoxHelper 按照上述策略删除的种子个数:"
read -e -p " (默认: 2):" de_num
[[ -z "$de_num" ]] && de_num=2
fi
fi
fi
sed -i 's/\("de_config":\["\).*/\1'"$de_url"\","\"$de_passwd"\","$de_total","\"$de_action"\","$de_num"\],'/g'   BoxHelper/config.json
}
edit_qb(){
echo
echo -e " 输入 qBittorrent 的 WebUI 地址："
read -e -p " (默认: 取消):" qb_url
if  [ ! -n "$qb_url" ] ;then
echo "已取消..." && exit 1
else
echo -e " 输入 qBittorrent WebUI 的账号密码，以-分隔，如admin-admin："
read -e -p " (默认: 取消):" qb_sid
if  [ ! -n "$qb_sid" ] ;then
echo "已取消..." && exit 1
else
echo -e " 输入 qBittorrent 中 BoxHelper 下载的种子体积和的上限，GB："
read -e -p " (默认: 取消):" qb_total
if  [ ! -n "$qb_total" ] ;then
echo "已取消..." && exit 1
else
echo -e " 输入超出上述上限后的删种策略，slow，add，complete，active，small，large，ratio："
read -e -p " (默认: large):" qb_action
[[ -z "$qb_action" ]] && qb_action="large"
echo -e " 请输入 BoxHelper 按照上述策略删除的种子个数:"
read -e -p " (默认: 2):" qb_num
[[ -z "$qb_num" ]] && qb_num=2
fi
fi
fi
sed -i 's/\("qb_config":\["\).*/\1'"$qb_url"\","\"$qb_sid"\","$qb_total","\"$qb_action"\","$qb_num"\],'/g'   BoxHelper/config.json
}
edit_cycle(){
    echo
    echo -e " 修改 BoxHelper 的监听周期, 单位是 秒:"
    read -e -p " (默认: 取消):" cycle
    [[ -z "$cycle" ]] && echo "已取消..." && exit 1
    sed -i  's/\("cycle":\).*/\1'"$cycle"'/g'   BoxHelper/config.json

}
edit_urls(){
    get_config
    i=0
    len=${#array[*]}
    while [ $i -lt $len ]
    do
    echo "  BoxHelper 监听页面 $[i/7+1]  : 监听 ${array[$i]} 内 大于 ${array[$[i+1]]} GB 且小于 ${array[$[i+2]]} GB 的种子， 使用 ${array[$[i+3]]} 客户端下载，限制下载速度为 ${array[$[i+4]]} MB/s 上传速度为 ${array[$[i+5]]} MB/s， 是否加载之前的 Free 种：${array[$[i+6]]}"
    let i+=7
    done
    echo && echo -e "
 ${Green_font_prefix} 1.${Font_color_suffix} 添加 BoxHelper 监控页面
 ${Green_font_prefix} 2.${Font_color_suffix} 删除 BoxHelper 监控页面" && echo
    read -e -p " 请输入数字 [1-2]:" num
    case "$num" in
        1)
        add_url
        ;;
        2)
        remove_url
        ;;
        *)
        echo "请输入正确数字 [1-2]"
        ;;
    esac
}
add_url(){
echo -e " 请输入要监听的种子页面:"
read -e -p " (默认: 取消):" page
[[ -z "${page}" ]] && echo -e "取消..." && exit 1
domain=$(echo ${page} | awk -F'[/:]' '{print $4}')
if [ -e BoxHelper/cookies/${domain}.json ]; then
echo " 存有此站点的Cookie, 是否修改原Cookie？[y/n]:"
read -e edit
if [[ "${edit}" == [Yy] ]]
then
echo " 请以Json格式输入此站点的Cookie:"
read -e -d "]" -p  " (默认: 取消):"  cookie
echo "$cookie]">BoxHelper/cookies/${domain}.json
fi
else
echo " 请以Json格式输入此站点的Cookie:"
read -e -d "]" -p  " (默认: 取消):"  cookie
[[ -z "${cookie}]" ]] && echo -e "已取消..." && exit 1
echo "$cookie]">BoxHelper/cookies/${domain}.json
fi
echo -e " 请输入此页面筛选的种子最小体积, 单位为GB, -1 为不限制:"
read -e -p " (默认: -1):" lower
[[ -z "${lower}" ]] && lower=-1
echo -e " 请输入此页面筛选的种子最大体积, 单位为GB, -1 为不限制:"
read -e -p " (默认: -1):" higher
[[ -z "${higher}" ]] && higher=-1
echo -e " 请输入下载此页面种子使用的客户端，qb，de:"
read -e -p " (默认: qb):" cli
[[ -z "${cli}" ]] && cli="qb"
echo -e " 请输入此页面下载的种子下载限速, 单位为MB/s, -1 为不限制:"
read -e -p " (默认: -1):" download
[[ -z "${download}" ]] && download=-1
echo -e " 请输入此页面下载的种子上传限速, 单位为MB/s, -1 为不限制:"
read -e -p " (默认: -1):" upload
[[ -z "${upload}" ]] && upload=-1
echo -e " 请输入是否加载此页面已存在的 Free 种[y/n]:"
read -e -p " (默认: n):" load
if [[ "${load}" == [Yy] ]]; then load=true
else
load=false
fi

sed -i '/url_size_speed_cli/a\'\\t\[\""$page"\","$lower","$higher","\"$cli"\","$download","$upload","$load"\],'' BoxHelper/config.json
}
remove_url(){
echo -e " 抱歉，暂时不支持脚本操作，请手动删除 BoxHelper/config.json 中的对应行，注意最后一行不要有逗号"
#    echo -e " 请输入要删除的监听页面的 「序号」 :"
#    read -e -p " (默认: 取消):" page_num
#    [[ -z "${page_num}" ]] && echo -e "已取消..." && exit 1
#    if [ $page_num -lt $len ]; then
#        let page_num--
#        domain=$(echo ${page} | awk -F'[/:]' '{print $4}')
#        page=$(echo ${page} | awk -F'[/:]' '{print $5}')
#        sed -i "/$domain\/$page/d" BoxHelper/config.json
#    else
#        echo "不存在这个页面, 取消 ..."  && exit 1
#    fi
}
uninstall_boxhelper(){
    echo "正在关闭 BoxHelper ..."
    [[ -z ${PID} ]] && echo -e " BoxHelper 没有运行"
    kill -9 ${PID}
    echo "正在无残留卸载 BoxHelper ..."
    rm -rf BoxHelper
}

start_boxhelper(){
    cd BoxHelper
    echo "正在从后台启动 BoxHelper, 日志文件为 BoxHelper/bh.log ..."
    java -jar BoxHelper.jar
}

stop_boxhelper(){
    echo "正在关闭 BoxHelper ..."
    [[ -z ${PID} ]] && echo -e " BoxHelper 没有运行" && exit 1
    kill -9 ${PID}
}
restart_boxhelper(){
    start_boxhelper
    stop_boxhelper
}

#菜单
menu(){
echo
echo " #############################################"
echo " # BoxHelper                                 #"
echo " # Github: https://github.com/SpereShelde    #"
echo " # Author: SpereShelde                       #"
echo " #############################################"

echo -e "
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 BoxHelper
 ${Green_font_prefix} 2.${Font_color_suffix} 编辑 BoxHelper
 ${Green_font_prefix} 3.${Font_color_suffix} 卸载 BoxHelper
 ————————————————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 启动 BoxHelper
 ${Green_font_prefix} 5.${Font_color_suffix} 停止 BoxHelper
 ${Green_font_prefix} 6.${Font_color_suffix} 重启 BoxHelper"

check_pid
if [[ ! -z "${PID}" ]]; then
	echo -e " 当前状态: BoxHelper ${Green_font_prefix}已启动${Font_color_suffix}"
else
	echo -e " 当前状态: BoxHelper ${Red_font_prefix}未启动${Font_color_suffix}"
fi
echo
read -e -p " 请输入数字 [1-6]:" num
case "$num" in
	1)
	install_boxhelper
	;;
	2)
	edit_boxhelper
	;;
	3)
	uninstall_boxhelper
	;;
	4)
	start_boxhelper
	;;
	5)
	stop_boxhelper
	;;
	6)
	restart_boxhelper
	;;
	*)
	echo "请输入正确数字 [0-6]"
	;;
esac
}

menu

