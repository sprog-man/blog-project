#!/bin/bash
#安装nginx并部署页面
echo "===nginx部署脚本==="

#记录当前目录
SCRIPT_DIR=$(pwd)
PROJECT_DIR="/root/blog-project"

#确保用户在/root/blog-project目录下运行
if [ ! -d "$PROJECT_DIR" ]; then
  echo "错误: $PROJECT_DIR 目录不存在"
  exit 1
else
  cd "$PROJECT_DIR"
fi

#检测该linux系统是否安装过nginx
if pgrep nginx >/dev/null; then
  echo "nginx已运行"
else
  echo "nginx未安装，开始安装..."
  
  #检查nginx源码是否已下载
  if [ ! -d "nginx-1.29.4" ]; then
    #源码进行安装nginx
    wget https://github.com/nginx/nginx/releases/download/release-1.29.4/nginx-1.29.4.tar.gz
    tar -zxvf nginx-1.29.4.tar.gz
  fi
  
  # 保存当前目录，编译nginx
  cd nginx-1.29.4
  #安装特定依赖
  yum install -y curl git gcc gcc-c++ pcre pcre-devel zlib zlib-devel openssl openssl-devel
  #指定安装位置：/usr/local/nginx
  ./configure --prefix=/usr/local/nginx
  make
  make install
  
  # 编译完成后返回项目目录
  cd "$PROJECT_DIR"
  
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

#检查blog-content目录是否存在
if [ ! -d "$PROJECT_DIR/blog-content" ]; then
  echo "错误: $PROJECT_DIR/blog-content 目录不存在"
  echo "当前目录内容:"
  ls -la "$PROJECT_DIR"
  exit 1
fi

#部署页面
echo "部署页面文件到nginx..."
cp -r $PROJECT_DIR/blog-content/* /usr/local/nginx/html/

# 设置正确的权限
chmod -R 755 /usr/local/nginx/html/

# 验证nginx是否正常运行
if systemctl is-active --quiet nginx; then
  echo "Nginx部署成功! 访问 http://你的服务器IP 查看页面"
else
  echo "Nginx启动失败，请检查配置"
fi

# 确保返回原始目录
cd "$SCRIPT_DIR"