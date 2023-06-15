---
title: '[NGINX] 2. Nginx를 활용한 네트워크 부하분산'
date: 2023-06-16 02:00:00 +/0900
categories: [Infra, NGINX]
tags: [infra, nginx, service, network, system, 부하 분산, http, tcp/ip]
author: sdk
toc: true
comments: false 
math: true 
mermaid: true 
img_path: /gh/errorcode4319/cdn/images
---

이번 시간에는 Nginx를 활용한 네트워크 부하분산에 대해 다뤄보고자 한다. 

## HTTP 부하 분산
HTTP 부하 분산을 위한 Nginx 설정은 다음과 같다. 
``` conf
upstream backend {
    server app1.example.com:80      weights=2;
    server app2.example.com:80      weights=1;
    server app-spare.example.com:80 backup;
}

server {
    location / {
        proxy_pass http://backend;
    }
}
```
위 설정을 통해 HTTP(80포트) 요청에 대한 부하를 두 대의 HTTP 서버로 분산시킨다. 

이때 `weight` 파라미터를 통해 각 서버에 대한 가중치를 설정할 수 있다.
`weight`값을 위와 같이 설정할 경우 첫 번째 서버(`app1.example.com`)가 두 번째 서버(`app2.example.com`)보다 두 배 많은 HTTP 요청을 저리한다.

시스템 운영 중 두 대의 프라이머리 서버 모두 접속 불가능한 상황이 되면 `backup`으로 지정된 스페어 서버(`app-spare.example.com`)를 사용해 HTTP 요청을 처리한다. 

> `weight`파라미터는 기본값이 1로 설정되어 있으며 생략할 수 있다.
{: .prompt-tip}

## TCP 부하 분산 
TCP 부하 분산을 위한 Nginx 설정은 다음과 같다. 
``` conf
stream {
    upstream db_read {
        server db1.example.com:3306     weight=5;
        server db2.example.com:3306;
        server db-spare.example.com:3306     backup;
    }
    server {
        listen 3306;
        proxy_pass db_read;
    }
}
```
위 설정을 통해 3306 포트로 TCP 요청을 받아 읽기 전용 복제본(Read Replica)
두 대로 구성된 DB서버로 부하를 분산한다. `weight` 및 `backup`은 앞서 설명한것과 동일하다.

이때 해당 설덩을 Nginx 기본 설정 파일 경로(`/etc/nginx/conf.d/`) 내에 작성할 경우, 
서비스 구동시 `/etc/nginx/nginx.conf`설정 파일의 `http` 블록에 포함된다. 
> `/etc/nginx/nginx.conf` 파일을 열어보면 해당 `include` 구문을 찾을 수 있다. 
{: .prompt-tip} 

해당 설정이 `http`블록에 포함되지 않도록 `/etc/nginx/nginx.conf`파일에 `stream`블록을 추가한다. 이때 `include`구문을 통해 해당 설정을 별도 파일로 관리할 수 있다.

``` conf
# /etc/nginx/nginx.conf 
...
stream {
    include /etc/nginx/stream.conf.d/*.conf
}
...
```
``` conf
# /etc/nginx/stream.conf.d/db_read.conf
upstream db_read {
    server db1.example.com:3306         weight=5;
    server db2.example.com:3306;
    server db-spare.example.com:3306     backup;
}
server {
    listen 3306;
    proxy_pass db_read;
}
```

`http`모듈은 어플리케이션 계층에서 동작하지만(7-layer) `stream`모듈은 전송 계층(4-layer)에서 동작한다. `stream`모듈을 통해서도 HTTP 프로토콜에 대한 부하분산을 처리할 수 있으나(당연한 얘기지만),`http`모듈은 HTTP 프로토콜에 더욱 특화되어 있다. 

`stream`모듈 사용 시 TCP와 관련된 프록시의 세부 설정을 변경할 수 있다 (SSL/TLS 인증서 제한, 타임아웃 설정 등). 보다 세부적인 설정은 공식 문서를 참고하자. 

## UDP 부하 분산
UDP 부하분산을 위한 Nginx 설정은 다음과 같다. 
``` conf
stream {
    upstream ntp {
        server ntp1.example.com:123 weight=2;
        server ntp2.example.com:123;
    }
    server {
        listen 123 udp;
        proxy_pass ntp;
    }
}
```
위 설정은 UDP 프로토콜을 통해 NTP(Network Time Protocol) 서버 두 대로 부하를 분산시킨다.
UDP의 경우 `listen` 설정에 `udp`파라미터를 추가하면 된다.

부하분산이 적용된 서비스 상에서 클라이언트와 서버 간에 패킷 교환이 많이 이뤄진다면, `reuseport`파라미터를 사용할 것을 권장한다. 
```
stream {
    server {
        listen 1195 udp reuseport;
        proxy_pass 127.0.0.1:1194;
    }
}
```
`reuseport` 파라미터 사용시 워커 프로세스 단위로 개별적인 수신 소켓을 생성한다(`SO_REUSEPORT`). 
해당 기능은 리눅스 커널 3.9 이상 버전에서 사용할 수 있다.
> 참고 자료: [Linux TCP SO_REUSEPORT Usage and Implementation](https://blog.flipkart.tech/linux-tcp-so-reuseport-usage-and-implementation-6bfbf642885a)
{: .prompt-tip}

## 부하분산 알고리즘 
Nginx에서 제공되는 부하분산 알고리즘 목록은 다음과 같다.
- Round Robin: 순차적으로 요청을 분산시킨다. (기본설정)
- Least Connection: 연결이 적은 서버를 우선적으로 사용한다.
    - `least_conn` 구문 사용
- Least Time: 응답 속도가 빠른 서버를 우선적으로 사용한다.
    - `least_time` 구문 사용 
    - Nginx Plus 에서만 사용 가능하다.
- Generic Hash: 특정 문자열 기반 해시를 활용한다.
    - `hash` 구문 사용 
- Random: 무작위로 선정한다.
    - `random` 구문 사용 
- IP Hash: IP 주소 기반 해시를 활용한다.
    - `ip_hash` 구문 사용

위 부하분산 알고리즘들은 HTTP, TCP, UDP 업스트림 풀에 모두 사용할 수 있다.
상황에 맞게 적절한 부하분산 알고리즘을 사용해 보자.

업스트림 풀에 Least Connection 알고리즘을 적용하는 예시는 다음과 같다.

``` conf
upstream backend {
    least_conn;
    server app1.example.com;
    server app2.example.com;
}
```

## 마치며
막상 글을 쓰다 보니, 생각보다 오래걸린것 같다. (처음엔 이럴줄 몰랐는데)   
이정도 내용만 알아도 얼마든지 유용하게 Nginx를 활용할 수 있지 않나 싶다.
물론 Nginx 관련 포스팅은 더 올릴 예정이다.   