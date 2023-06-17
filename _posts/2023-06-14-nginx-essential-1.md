---
title: '[NGINX] 1. Nginx 기본 구성 요소 및 주요 명령어'
date: 2023-06-14 23:27:00 +/0900
categories: [DevOps, NGINX]
tags: [infra, nginx, service, network, system]
author: sdk
toc: true
comments: false 
math: true 
mermaid: true 
img_path: /gh/errorcode4319/cdn/images
---

Nginx 관련 첫 포스팅이다. 이번 포스팅에서는 Nginx의 기본적인 설정 파일과 디렉토리 구성, 명령어를 정리하고자 한다. (Nginx 설치방법 까지는 정리하지 않는다)

## Nginx 주요 파일 및 디렉토리

### /etc/nginx/
기본 설정 파일이 저장된 루트 디렉토리다.    
여담이지만 `/etc` 디렉토리는 알아두면 여러모로 편하다. (참고 링크: [/etc 디렉토리](http://doc.kldp.org/Translations/html/SysAdminGuide-KLDP/x384.html)) 

### /etc/nginx/nginx.conf 
Nginx의 기본 설정 파일이며, 모든 설정에 대한 진입점 역할을 한다.   

### /etc/nginx/conf.d/
기본 http 서버 설정 파일이 포함되어 있다. 또한 디렉토리 내 `.conf`확장자를 가진 설정파일은 앞서 설명한 `/etc/nginx/nginx.conf`파일의 최상위 `http` 블록에 포함된다.

### /var/log/nginx/
Nginx의 로그가 저장된다. 서비스 구동 시 기본적으로 생성되는 로그 파일은 다음과 같다.
- **access.log**: 서버가 수신한 개별 요청에 대한 로그 기록 
- **error.log**: 오류 발생 시 이벤트 내용 기록

## Nginx 기본 명령어 

### -h
- `nginx -h`: 도움말(help)을 출력한다.

### -v, -V
- `nginx -v`: 버전 정보를 출력한다.
- `nginx -V`: 버전 정보를 비롯한 빌드 정보와 각종 세부 정보를 출력한다.

### -t, -T
- `nginx -t`: 설정을 테스트한다.
- `nginx -T`: 설정을 테스트 하고 보다 세부적인 설정 정보를 출력한다.

### -s signal
- `nginx -s <signal>`: 구동중인 마스터 프로세스로 특정 시그널을 전송한다.
    - `<signal>: stop`: 즉시 프로세스를 종료한다. 
    - `<signal>: quit`: 현재 진행중인 요청을 모두 처리한 뒤 프로세스를 종료한다.
    - `<signal>: reload`: 설정을 다시 로드한다.   

Nginx 프로세스 제어와 관련된, 보다 자세한 내용은 공식 문서를 참고해 보자.



## 서비스 구성 예시
다음 예시는 정적 컨텐츠 제공을 위한 서비스를 구성하는 가장 간단한 설정이다.
`/etc/nginx/conf.d/default.conf`의 파일 내용을 다음과 같이 수정한다. 
```conf
server {
    listen 80 default_server;
    server_name www.example.com;

    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
    }
}
```
- `server{ ... }`
    - Nginx가 처리할 새로운 컨텍스트를 정의한다.
- `listen 80 default_server;`
    - 80 포트로 요청을 받는다.
    - 해당 블록이 80포트에 대한 기본 컨텍스트가 되도록 `default_server` 파라미터를 추가한다.
    - `listen`을 통한 포트 설정 시 단일 포트가 아닌 범위 기반으로 지정할 수도 있다.  
- `server_name www.example.com;`
    - 서버가 처리할 호스트명(혹은 도메인명)을 지정한다.
    - 기본 컨텍스트가 아니라면(`default_server` 참고) 해당 호스트에 대한 요청만 처리한다.
    - 기본 컨텍스트에서는 해당 구문을 생략할 수 있다.
- `location / { ... }`
    - 해당 URI(`/`)로 들어오는 요청을 처리할 `location` 블록을 생성한다.
- `root /usr/share/nginx/html;`
    - 해당 컨텍스트에서 컨텐츠를 제공할 루트 경로를 지정한다. 
        - 파일 경로 = `root` + `location`
    - 참고 자료: [static file serving confusion with root & alias](https://stackoverflow.com/questions/10631933/nginx-static-file-serving-confusion-with-root-alias)
- `index index.html index.htm;`
    - `index`지시자는 해당 URI에 대한 기본 파일을 지정한다.
        - `http://localhost/` -> `http://localhost/index.html`

## 마치며
본 문서상에 설명된 내용은 [NGINX cookbook 2/e](https://www.nginx.com/resources/library/complete-nginx-cookbook/) 을 기반으로 작성된 내용이며, 
앞으로 NGINX 관련 내용을 주기적으로 포스팅 할 생각이다.