#!/bin/bash

#v2ray-plugin版本
VER="latest"
PASSWORD="8c4e75bc-4151-11eb-b378-0242ac130002"
ENCRYPT="chacha20-ietf-poly1305"
V2_Path="/v2"
QR_Path="/qr"
V_VER=`wget -qO- "https://api.github.com/repos/shadowsocks/v2ray-plugin/releases/latest" | sed -n -r -e 's/.*"tag_name".+?"([vV0-9\.]+?)".*/\1/p'`
[[ -z "${V_VER}" ]] && V_VER="v1.3.0"
mkdir /wwwroot

mkdir /v2raybin
cd /v2raybin
V2RAY_URL="https://github.com/shadowsocks/v2ray-plugin/releases/download/${V_VER}/v2ray-plugin-linux-amd64-${V_VER}.tar.gz"
wget -q --no-check-certificate ${V2RAY_URL}
tar -zxvf v2ray-plugin-linux-amd64-$V_VER.tar.gz
rm -rf v2ray-plugin-linux-amd64-$V_VER.tar.gz
mv v2ray-plugin_linux_amd64 /usr/bin/v2ray-plugin
rm -rf /v2raybin

if [ ! -d /etc/shadowsocks-libev ]; then  
  mkdir /etc/shadowsocks-libev
fi

# TODO: bug when PASSWORD contain '/'
sed -e "/^#/d"\
    -e "s/\${PASSWORD}/${PASSWORD}/g"\
    -e "s/\${ENCRYPT}/${ENCRYPT}/g"\
    -e "s|\${V2_Path}|${V2_Path}|g"\
    /conf/shadowsocks-libev_config.json >  /etc/shadowsocks-libev/config.json
echo /etc/shadowsocks-libev/config.json
cat /etc/shadowsocks-libev/config.json

sed -e "/^#/d"\
    -e "s/\${PORT}/${PORT}/g"\
    -e "s|\${V2_Path}|${V2_Path}|g"\
    -e "s|\${QR_Path}|${QR_Path}|g"\
    -e "$s"\
    /conf/nginx_ss.conf > /etc/nginx/conf.d/ss.conf

if [ "$AppName" = "no" ]; then
  echo "Aditya's VPN"
else
  mkdir /wwwroot${QR_Path}
  touch /wwwroot${QR_PATH}/index.html
  plugin=$(echo -n "v2ray;path=${V2_Path};host=${AppName}.herokuapp.com;tls" | sed -e 's/\//%2F/g' -e 's/=/%3D/g' -e 's/;/%3B/g')
  ss="ss://$(echo -n ${ENCRYPT}:${PASSWORD} | base64 -w 0)@${AppName}.herokuapp.com:443?plugin=${plugin}" 
  echo "${ss}" | tr -d '\n' > /wwwroot${QR_Path}/index.html
  echo -n "${ss}" | qrencode -s 6 -o /wwwroot${QR_Path}/vpn.png
fi

ss-server -c /etc/shadowsocks-libev/config.json &
rm -rf /etc/nginx/sites-enabled/default
nginx -g 'daemon off;'