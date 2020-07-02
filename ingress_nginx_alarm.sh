#!/bin/bash
token='https://oapi.dingtalk.com/robot/send?access_token=6e6d69774d024a60ea63315176a3d3h562st42da108d1b7487e68a3f8b224e8'
sendto="'13612345678','13712345678'"
msg="'test message'"

ding_msg () {
    #echo "token=$1 sendto=$2 msg=$3"
    json_msg="{'msgtype': 'text', 'text': {'content': $3},'at': {'isAtAll': false, 'atMobiles': [$2]}}"
    curl $1 -H 'Content-Type: application/json' -d "${json_msg}"
}

main () {
while true;
    do
    for ingress_pod in $(kubectl -n ingress-nginx get pod | grep nginx-ingress|awk '{print $1}')
        do
        oldnum=$(kubectl -n ingress-nginx exec $ingress_pod -- ls -lt /tmp |grep nginx-cfg|wc -l)
        if [ $? == 1 ];then
            echo "$(date +'%Y-%m-%d %H:%M:%S') 线下 rancher 发现异常的 ingress-nginx pod $ingress_pod" >>/var/log/check_ingress.log
            ding_msg ${token} ${sendto} "'发现异常的 ingress-nginx pod $ingress_pod'"
            continue
        fi
        for ((i=1;i<9;i++));
            do
            newnum=$(kubectl -n ingress-nginx exec $ingress_pod -- ls -lt /tmp |grep nginx-cfg|wc -l)
            [ $? == 1 ] && break
            echo "$(date +'%Y-%m-%d %H:%M:%S') ingress_pod=$ingress_pod  oldnum=$oldnum  newnum=$newnum" >>/var/log/check_ingress.log
            if [ $newnum -gt $oldnum ];then
                ding_msg ${token} ${sendto} "'发现错误的 ingress-nginx 配置文件, 睡眠60秒再次检测'"
                oldnum=$newnum
                sleep 55
            fi
            sleep 5
        done
    done
done
}

main &
