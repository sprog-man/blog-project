#!/bin/bash
#安装nginx并部署页面
echo "===nginx部署脚本==="
#确保用户在/root/blog-project目录下运行
if [ ! -d "/root/blog-project" ]; then
  echo "请确保在/root/blog-project目录下运行"
  exit 1
fi
#确保是在/root/blog-project目录下接着才允许运行下面的代码
cd /root/blog-project
#检测该linxu系统是否安装过nginx
if pgrep nginx >/dev/null; then
  echo "nginx已安装"
else
  echo "nginx未安装"
  #源码进行安装nginx
  wget https://github.com/nginx/nginx/releases/download/release-1.29.4/nginx-1.29.4.tar.gz
  tar -zxvf nginx-1.29.4.tar.gz
  cd nginx-1.29.4
  #安装特定依赖
  yum install -y curl git gcc gcc-c++ pcre pcre-devel zlib zlib-devel openssl openssl-devel
  #指定安装位置：/usr/local/nginx
  ./configure --prefix=/usr/local/nginx
  make
  make install
  #安装成系统服务
  cat > /usr/lib/systemd/system/nginx.service <<EOF
[Unit]
Description=nginx
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/usr/local/nginx/logs/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t -c /usr/local/nginx/conf/nginx.conf
ExecStart=/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s stop
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    #重新加载服务
    systemctl daemon-reload
  #启动nginx
    systemctl start nginx
  #设置开机启动
    systemctl enable nginx
fi
#部署页面
#将git仓库中的blog-content目录下的所有文件复制到nginx的默认网站根目录下
cp -r /root/blog-project/blog-content/* /usr/local/nginx/html/