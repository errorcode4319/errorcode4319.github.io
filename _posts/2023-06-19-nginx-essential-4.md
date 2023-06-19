---
title: '[NGINX] 4. Nginx를 활용한 콘텐츠 캐싱'
date: 2023-06-19 23:15:00 +/0900
categories: [DevOps, NGINX]
tags: [DevOps, infra, nginx, service, network, system, http, tcp/ip]
author: sdk
toc: true
comments: false 
math: true 
mermaid: true 
img_path: /gh/errorcode4319/cdn/images
---

이번 시간에는 Nginx를 활용한 콘텐츠 캐싱을 다뤄볼 예정이다. 콘텐츠 캐싱은 업스트림 서버가 동일한 요청에 대해 쿼리를 다시 수행하지 않도록 전체 응답을 저장함으로써 업스트림 서버의 부하를 낮춘다. 

Nginx를 사용하면 서버가 배치된 모든 곳에 콘텐츠를 캐시할 수 있어 효과적으로 자신만의 CDN을 만들 수 있다.

## 캐시 영역
`proxy_cache_path` 구문을 통해 공유 메모리 캐시 영역을 정의할 수 있다.
``` conf
proxy_cache_path /var/nginx/cache
                keyws_zone=CACHE:60m
                levels=1:2
                inactive=3h
                max_size=20g;
proxy_cache CACHE;
```
위 예시는 캐시 응답을 저장하기 위해 `/var/nginx/cache` 디렉토리를 생성한다. `proxy_cache_path` 구문의 파라미터 목록은 다음과 같다.
- `keyws_zone=CACHE:60m`: 메모리에 `CACHE`라는 공유 메모리 영역을 60mb 사이즈로 생성한다.
- `levels=1:2`: 디렉토리 구조의 레벨을 지정한다.
- `inactive=3h`: 3시간동안 해당 응답에 대한 요청이 없으면, 캐시를 비활성화한다.
- `max_size=20g`: 캐시 영역의 최대 크기를 20gb로 제한한다. 

이후 `proxy_cache` 구문을 통해 해당 컨텍스트에서 사용할 캐시 영역을 지정한다.
>`proxy_cache` 지시자는 `http`, `server`, `location` 컨텍스트에서만 사용 가능하다.
{: .prompt-tip}

## 캐시 락
캐시 락은 동일한 리소스에 대한 요청이 다수 들어오면, 한 번에 하나의 요청을 통해서만 캐시가 생성되도록 제한한다.
``` conf
proxy_cache_lock on;
proxy_cache_lock_age 10s;
proxy_cache_lock_timeout 3s;
```
- `proxy_cache_lock on`: 캐시 락을 활성화 한다.
    - 동일한 요청이 다수 들어오면, 최초 요청에 대한 캐시가 생성되는 것을 대기한다.
- `proxy_cache_lock_age 10s`: 캐시 생성 시간이 10초를 초과하면, 대기중인 요청을 업스트림 서버로 보내 다시 캐싱을 시도한다.
- `proxy_cache_lock_timeout 3s`: 캐시 생성 시간이 3초를 초과하면, 대기중인 요청을 업스트림 서버로 보내지만 캐시는 생성하지 못하게 한다.

## 해시 키 값 캐시
``` conf
proxy_cache_key "$host$request_uri $cookie_user";
```
위 예시를 통해 요청된 페이지를 캐시로 저장할때 호스트명, 요청 URI, 쿠키값으로 사용자마다 서로 다른 해시를 생성해 캐시 키로 사용한다. 이를 통해 동적인 페이지를 캐시하더라도 다른 사용자의 콘텐츠가 잘못 전달되지 않도록 할 수 있다.

## 캐시 우회
캐시를 사용하지 않고 우회하는 방법은 다음과 같다.
``` conf
proxy_cache_bypass $http_cache_bypass;
```
`proxy_cache_bypass` 구문을 비어 있지 않은 값이나 0이 아닌 값으로 지정해 캐시를 우회한다. 위 예시는 `cache-bypass` 라는 HTTP 요청 헤더값이 0이 아닐 때 Nginx가 캐시를 우회하도록 한다.

## 캐시 성능 향상
사용자 환경에 콘텐츠를 캐싱해 캐시 성능을 높일 수 있다.
``` conf
location ~* \.(css|js)$ {
    expires 1y;
    add_header Cache-Control "public";
}
```
- `location` 블록은 사용자가 CSS, JS 파일을 캐시하도록 명시한다.
- `expires 1y;`: 사용자 환경에 캐시된 콘텐츠의 유효기간을 1년으로 지정한다.
- `add_header Cache-Control "public";`: HTTP 응답에 `Cache-Control`헤더를 추가한다.
    - `publich` 사용 시 중간에 위치한 어떤 캐시 서버라도 리소스를 캐시할 수 있도록 한다.
    - `private`으로 지정하면 실제 사용자 환경에만 리소스를 캐시한다.

## 캐시 파일 분할
용량이 큰 파일을 작은 조각으로 나눠 캐시 효율을 높일 수 있다.
``` conf
proxy_cache_path /tmp/mycache keys_zone= mycache:10m;

server {

    # ...
    proxy_cache mycache;
    slice 1m;
    proxy_cache_key $host$uri$is_args$args$slice_range;
    proxy_set_header Range $slice_range;
    proxy_http_version 1.1;
    proxy_cache_valid 200 206 1h;

    location / {
        proxy_pass http://origin:80;
    }
}
```
위 예시는 앞서 설명한 내용을 토대로 캐시 영역을 정의하고 활성화 시킨다. 이때 `slice` 구문을 통해 업스트림 서버의 응답을 1mb 크기의 파일 조각으로 나눈다. 이후 나눠진 파일들은 `proxy_cache_key` 지시자에 지정된 규칙에 따라 저장된다. 

`proxy_set_header` 지시자를 사용해 원본 서버(업스트림)로 요청을 보낼 때 `Range` 헤더를 추가하고 헤더값으로 `slice_range` 변숫값을 사용하도록 지정한다. 해당 헤더를 통해 HTTP의 바이트 레인지(byte range) 요청을 사용할 수 있다. 해당 기능은 HTTP 1.1버전부터 지원되는 기능이므로 `proxy_http_version` 구문을 통해 프로토콜 버전을 업그레이드해야 한다. 

`proxy_cache_valid` 구문을 통해, 캐시가 200과 206 응답에 한해 1시간 동안 유효하도록 설정한다.

## 마치며
아직 Nginx 관련해서 다뤄야 할 내용들이 너무 많이 남았다.... 언제 다하지 