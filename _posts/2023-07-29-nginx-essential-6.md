---
title: '[NGINX 기본기 다지기] 6. 보안 제어'
date: 2023-07-29 22:00:00 +/0900
categories: [DevOps, NGINX]
tags: [nginx-cookbook-2/e, DevOps, infra, nginx, service, network, system, http, tcp/ip]
author: sdk
toc: true
comments: false 
math: true 
mermaid: true 
img_path: /gh/errorcode4319/cdn/images
---

이번 포스팅에서는 Nginx를 활용한 보안 제어 기능을 다뤄볼까 한다.

## IP 주소 기반 접근 제어
`ngx_http_access_module`을 통해 리소스에 대한 접근을 제어할 수 있다.
``` conf
location /admin/ {
    deny 10.0.0.1;
    allow 10.0.0.0/20;
    allow 2001:0db8::/32;
    deny all;
}
```
위 location블록의 경우 **10.0.0.0/20** 대역(IPv4)과 **2001:0db8::/32** 대역(IPv6)의 접근을 허용한다. 이때 IPv4 주소가 **10.0.0.1**일 경우 접근을 차단하며, 그 외 모든 IP주소에 대한 접근을 차단한다.        

여러개의 정책(`allow|deny`)이 지정될 경우 위에서부터 순차적으로 부합 여부를 판단한다.    

## CORS (cross-origin resource sharing)
CORS 접근을 허용하려면 요청 메서드에 따라 응답 헤더를 변경해야 한다. (해당 포스팅에선 CORS에 대한 설명은 생략한다. 검색하면 많이 나온다)
``` conf
map $request_method $cors_method {
    OPTIONS 11;
    GET     1;
    POST    1;
    default 0;
}

server {
    ...
    location / {
        if ($cors_method ~ '1') {
            add_header 'Access-Control-Allow-Methods' 'GET,POST,OPTIONS';
            add_header 'Access-Control-Allow-Origin' '*.example.com';
            add_header 'Access-Control-Allow-Headers'
                        'DNT,
                        Keep-Alive,
                        User-Agent,
                        X-Requested-With,
                        If-Modified-Since,
                        Cache-Control,
                        Content-Type';
        }
        if ($cors_method = '11') {
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=UTF-8';
            add_hedaer 'Content-Length' 0;
            return 204;
        }
    }
    ...
}
```
위 서버의 경우 GET, POST, OPTIONS 메서드를 허용하며, Access-Control-Allow-Origin 헤더를 통해 example.com 도메인(하위 도메인 포함)에서 서버 리소스에 접근이 가능함을 알려준다.

`map` 구문을 통해 **GET**, **POST** 메서드를 그룹화해 일괄적으로 처리한다.        
**OPTIONS** 메서드는 프리플라이트(preflight) 요청으로 서버가 가진 CORS 정책을 응답한다. 또한 프리플라이트 요청을 매번 보내지 않고 CORS 정책을 참고할 수 있도록 Access-Control-Max-Age 헤더를 통해 정책정보를 캐싱한다. 


## 클라이언트 암호화
`ngx_http_ssl_module` 혹은 `ngx_stream_ssl_module`과 같은 SSL 모듈을 통해 Nginx 서버와 클라이언트간 트래픽을 암호화할 수 있다.
``` conf
http {
    server {
        listen 8443 ssl;
        ssl_certificate /etc/nginx/ssl/example.crt;
        ssl_certificate_key /etc/nginx/ssl/example.key;
    }
}
```
위 서버의 경우 8443 포트로 들어오는 요청에 대해 SSL/TLS를 사용해 트래픽을 암호화시킨다.    

`ssl_certificate` 구문은 인증서와 중간 체인 인증서(intermediate chain certificate)가 저장된 파일 경로를 정의하며, `ssl_certificate_key` 구문은 Nginx 서버에서 클라이언트 요청을 복호화하고 응답을 암호화하는데 필요한 비밀키 파일 경로를 정의한다. (비교적 직관적이다)

Nginx 버전에 따라 다양한 SSL/TLS 협상(Negotiation) 설정 기본값을 제공한다.
> ssl 모듈은 상당히 많은 기능을 제공한다. 시간날때 읽어보자 [Module ngx_http_ssl_module](http://nginx.org/en/docs/http/ngx_http_ssl_module.html)
{:.prompt-tip}

## 업스트림 암호화
Nginx와 업스트림 서비스 간 트래픽을 암호화하고, 협상 규칙을 지정하기 위해서는 `ngx_http_proxy_module`의 SSL 관련 구문을 사용한다.
```conf
location / {
    proxy_pass https://upstream.example.com;
    proxy_ssl_verify on;
    proxy_ssl_verify_depth 2;
    proxy_ssl_protocols TLSv1.2;
}
``` 
위 설정에서 proxy 관련 구문들은 Nginx 서버가 준수해야 하는 SSL 규칙을 정의한다.    
위 서버는 업스트림 서비스의 서버 인증서와 인증서 체인이 두 단계까지 유효한지 확인하며, TLS 1.2 버전만 SSL 연결 설정에 사용하도록 정의되어 있다.   

이때 `proxy_ssl_verify`옵션을 통해 업스트림 트래픽 암호화 여부를 활성화 시켜야 한다.
> [Module ngx_http_proxy_module](http://nginx.org/en/docs/http/ngx_http_proxy_module.html)
{:.prompt-tip}

## location 블록 보호
`ngx_http_secure_link_module`을 활용하면 특정 비밀값을 통해 location블록에 대한 접근을 보호할 수 있다.
```conf
location /resources {
    secure_link_secret MySecret;
    if ($secure_link = "") { 
        return 403; 
    }

    rewrite ^ /secured/$secure_link;
}

location /secures/ {
    internal;
    root /var/www;
}
```
위 설정은 공개된 location블록과 내부에서만 접근 가능한 location블록을 별도로 만든다. 

`/resources` location 블록은 요청 URI가 `secure_link_secret` 구문에 지정된 비밀값으로 검증 가능한 md5 해시값을 갖고 있지 않을 경우 '403 Forbidden'을 응답한다. `$secure_link` 변수는 URI에 포함된 해시값이 검증되기 전까지는 아무런 값을 갖지 않는다.

### 보안 링크 생성하기
앞서 살펴본 보안 링크 모듈은 URI 경로와 비밀값을 연결한 문자열로 생성한 md5 해시의 16진수 다이제스트를 인식한다. 

위 서버에서 `/var/www/secured/index.html` 파일을 보호하기 위한 보안 링크를 만드는 예시는 다음과 같다.
```sh
# 리소스명 + 비밀값
echo -n 'index.htmlMySecret' | openssl md5 -hex
MD5(stdin)= c1b7561f30ebd48880ed436ae08bc39f
```
해당 다이제스트값을 URL에 추가하면 `/resource` 블록에 접근하기 위한 보안 링크가 생성된다.
```
www.example.com/resources/c1b7561f30ebd48880ed436ae08bc39f/index.html
```

### 기간 제한 링크
만료 일자가 지정된 기간 제한 링크를 통해 location 블록을 보호할 수 있다.
```conf
location /resource {
    root /var/www;
    secure_link $arg_md5,$arg_expires;
    secure_link_md5 "$secure_link_expires$uri$remote_addrmySecret";
    if ($secure_link = "") { 
        return 403; 
    }
    if ($secure_link = "0") {
        return 410;
    }
}
```
`secure_link` 구문은 두 개의 매개변수를 사용한다. 첫 번째 매개변수는 md5 해시값을 담는 변수이며, 두 번째 배개면수는 링크 만료 시간을 담는 변수이다.      
`secure_link_md5` 구문은 md5 해시를 생성할 때 사용한 문자열의 형식을 선언한다.

/resources/index.html에 접근하는 기간 제한 링크를 생성하는 방법은 다음과 같다.
```sh
date -d "2030-12-31 00:00" +%s --utc
1924905600 # 만료 시간 타임스탬프를 생성한다.

echo -n '1924905600/resource/index.html127.0.0.1MySecret' \
    | openssl md5 -binary \
    | openssl base64 \
    | tr +/ -_ \
    | tr -d =
2pt0qVZbDJPTtiSZDHc3nA # 해시 생성
```
해시 생성의 경우 해당 서버의 링크 형식에 맞게("$secure_link_expires$uri$remote_addrmySecret") 구성해 준다. 또한 `secure_link_md5`는 앞서 본 md5 해시의 16진수 다이제스트값과는 다르다. 이번에는 바이너리 형식으로 표기된 md5 해시이며 base64로 인코딩한 후 '+'는 '-', '/'는 '_'로 바꾸고 '='는 제거한다.

이후 계산된 해시값을 바탕으로 다음과 같이 링크를 생성할 수 있다.
```
/resources/index.html?md5=2pt0qVZbDJPTtiSZDHc3nA&expires=1924905600
```

## HTTPS 리다이렉션
모든 HTTP 요청을 HTTPS로 전달하려면 URL을 재작성해야 한다.
```conf
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
}
```

혹여나 Nginx 앞단에서 SSL 오프로딩(SSL offloading)을 수행하는 상황에서 모든 요청을 HTTPS로 리다이렉션 해야 한다면 **X-Forwarded-Proto** 헤더를 통해 프로토콜을 확인 후 해당 값을 통해 요청을 리다이렉션 시킨다. 
```conf
server{
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    if ($http_x_forwarded_proto = 'http') {
        return 301 https://$host$request_uri;
    }
}
```

혹여나 HTTP로 요청을 보내지 않도록 강제하고 싶을 경우 **Strict-Transport-Security** 헤더를 통해 HSTS(HTTP Strict Transport Security) 확장을 활성화 시킨다.
```
add_header Strict-TransportSecurity max-age=31536000;
```
> [Strict-Transport-Security](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security)
{:.prompt-tip}

## 마치며
보안 제어만큼 중요한 부분이 있을까 싶다. (물론 알아야 할 것도 많아서 여러모로 골치아프다...) 

그래도 이제 얼추 기본적인 내용들은 거의 다 다룬듯 하다.. 