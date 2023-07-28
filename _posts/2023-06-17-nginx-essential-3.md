---
title: '[NGINX 기본기 다지기] 3. 네트워크 트래픽 제어'
date: 2023-06-17 01:00:00 +/0900
categories: [DevOps, NGINX]
tags: [nginx-cookbook-2/e, DevOps, infra, nginx, service, network, system, http, tcp/ip]
author: sdk
toc: true
comments: false 
math: true 
mermaid: true 
img_path: /gh/errorcode4319/cdn/images
---

이번 시간에는 Nginx를 활용한 트래픽 제어를 다룰 예정이다.

## 전송 대역폭 제한
``` conf
location /download/ {
    limit_rate_after 10m;
    limit_rate 1m;
    ...
}
```
위 설정은 서버 리소스의 부하를 막기 위해, 사용자당 다운로드 대역폭을 제한하는 상황에 대한 예시이다. `/download/` 하위 uri에 대해, 누적 전송량이 10메가바이트를 초과할 경우, 초당 1mb로 대역폭을 제한한다. 

## 연결 제한
``` conf
http {
    limit_conn_zone $binary_remote_addr zone=limit_by_addr:10m;
    limit_conn_status 429;

    # ...
    server {
        # ...
        limit_conn limit_by_addr 40;
        # ...
    }
}
```
위 설정은 사용자 IP 주소를 통해 연결 수를 제한하는 예시이다.
`limit_conn_zone` 구문을 통해 `limit_by_addr`라는 공유 메모리 영역을 생성하며 (10mb 용량), 바이너리 형태의 사용자 IP 주소(`$binary_remote_addr`)를 사전 정의된 키로 사용한다. 

`limit_conn` 구문은 `limit_conn_zone`으로 선언한 공유 메모리 영역과 허용 연결 수를 파라미터로 받는다. 해당 구문을 통해 지정된 연결 수를 초과할 경우, `limit_conn_status`를 통해 설정한 HTTP Status Code를 제공한다. 

`limit_conn`, `limit_conn_status` 구문은 `http`, `server`, `location` 에서 사용할 수 있다. 

## 요청 빈도 제한 
``` conf
http {
    limit_req_zone $binary_remote_addr zone=limit_by_addr:10m rate=3r/s;
    limit_req_status 429;

    # ...
    server {
        # ...
        limit_req zone=limit_by_addr;
        # ...
    }
}
```
`limit_req_zone`은 앞서 설명한것과 동일하게 공유 메모리 영역을 생성한다. 이때 `rate` 파라미터를 통해 요청 빈도를 제한할 수 있으며, 위 설정의 경우 동일한 IP에 대해서 초당 요청 수를 3개로 제한한다(`rate=3r/s`).    
`limit_req`구문은 `zone` 파라미터를 통해 어떤 공유 메모리 영역을 참고해 요청 빈도를 제한할지 결정한다. 

### 추가적인 빈도 제한
`limit_req` 구문은 `zone`과 별개로, 추가적인 파라미터를 통해 요청 빈도를 제한할 수 있다.
``` conf
server {
    location / {
        limit_req zone=limit_by_addr burst=12 delay=9;
    }
}
```
간혹 한번에 많은 요청을 전송할 수 일정 시간 동안 요청 빈도를 줄이는 경우가 있다(한번에 몰아서 요청을 보내는 케이스). 

`burst` 파라미터를 통해 빈도가 지정된 값보다 낮으면 허용하도록 설정할 수 있다. 단 `delay` 값을 초과한 요청에 대해서는 지정된 `rate`에 맞춰 지연 처리를 수행한다.


## 클라이언트 분기 (A/B 테스트)
보통 다양한 버전에 대한 사용자의 반응을 모니터링 하기 위해, 두 개 이상의 파일이나 서비스로 사용자를 분기하는 경우가 있다. 

``` conf 
split_clients "${remote_addr}" $variant {
    20.0%   "backend_v2";
    *       "backend_v1";
}
location / {
    proxy_pass http://$variant;
}
```
위 설정은 `split_clients` 모듈을 통해 비율에 따라 서로 다른 접속 정보(업스트림 풀)를 제공한다.
위 요청의 경우 `$variant` 변수는 20%의 사용자에게만 `backend_v2`가 할당되고, 나머지 사용자에게는 `backend_v1`가 할당된다.

다음 설정을 통해 두 가지 버전의 정적 웹사이트로 사용자 요청을 분기시킬 수 있다.
``` conf
http {
    split_clients "${remote_addr}" $site_root_dir {
        33.3%       "/var/www/site_v2/";
        *           "/var/www/site_v1/";
    }

    server {
        listen 80 default_server;
        root $site_root_dir;
        location / {
            index index.html;
        }
    }
}
```

## 마치며
본 포스팅에 설명된 내용 외에도 트래픽 제어와 관련된 다양한 기능이 존재한다. 
또한 연결 및 요청 빈도에 대한 제한 설정 시 Dry run 기능을 통해 모의 테스트를 진행할 수 있다.

최대한 다양한 기능을 활용하여, 더 나은 서비스 제공을 위한 고민과 다양한 시도를 해보는것이 좋을듯 하다. 