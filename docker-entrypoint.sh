#!/bin/bash

dir_shell=/ql/shell
. $dir_shell/share.sh
. $dir_shell/env.sh

echo -e "======================1. 检测配置文件========================\n"
import_config "$@"
make_dir /etc/nginx/conf.d
make_dir /run/nginx
init_nginx
fix_config

pm2 l &>/dev/null

/sync_data.sh &
sleep 15

echo -e "======================2. 安装依赖========================\n"
patch_version

echo -e "======================3. 启动nginx========================\n"
nginx -s reload 2>/dev/null || nginx -c /nginx.conf
echo -e "nginx启动成功...\n"

echo -e "======================4. 启动pm2服务========================\n"
reload_update
reload_pm2

if [[ $AutoStartBot == true ]]; then
  echo -e "======================5. 启动bot========================\n"
  nohup ql bot >$dir_log/bot.log 2>&1 &
  echo -e "bot后台启动中...\n"
fi

if [[ $EnableExtraShell == true ]]; then
  echo -e "====================6. 执行自定义脚本========================\n"
  nohup ql extra >$dir_log/extra.log 2>&1 &
  echo -e "自定义脚本后台执行中...\n"
fi

echo -e "======================7. 启动数据同步服务========================\n"


echo -e "############################################################\n"
echo -e "容器启动成功..."
echo -e "############################################################\n"

echo -e "##########写入登陆信息############"
echo "{ \"username\": \"$ADMIN_USERNAME\", \"password\": \"$ADMIN_PASSWORD\" }" > /ql/data/config/auth.json

tail -f /dev/null

exec "$@"
