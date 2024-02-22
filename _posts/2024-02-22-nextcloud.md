---
title: 'Nextcloud, 사설 클라우드 환경 구축'
date: 2024-02-22 23:00:00 +/0900
categories: [linux]
tags: [linux]
author: sdk
toc: true
comments: false 
math: true 
mermaid: true 
img_path: /gh/errorcode4319/cdn/images
---


최근 친구들과 공용 클라우드를 구축하기 위해 이런저런 소프트웨어들을 알아보고 있던 와중 nextcloud라는 녀석을 발견했다.

[Nextcloud - Open source content collaboration platform](https://nextcloud.com/)


## Setup

docker-compose.yml 파일은 다음과 같이 구성했다.  ([Dockerhub - nextcloud](https://hub.docker.com/_/nextcloud))

```yaml
version: '3'

services:
  app:
    image: nextcloud:28.0.2
    restart: always
    ports:
      - 80:80
    links:
      - db
    volumes:
      - ./volumes/nextcloud:/var/www/html
      #apps, config, data 도 개별적으로 마운트 시켰다
      - ./volumes/apps:/var/www/html/custom_apps    
      - ./volumes/config:/var/www/html/config
      - ./volumes/data:/var/www/html/data 
    environment: 
      - MYSQL_PASSWORD=pass1234
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_HOST=db
    deploy:
      resources:
        limits:
        # 소규모로 사용할 예정이라, CPU랑 메모리는 최대한 타이트하게 잡았다
          cpus: '0.5'
          memory: '500M'
  db:
    image: mariadb:10.6
    command: --transaction-isolation=READ-COMMITTED --log-bin=binlog --binlog-format=ROW
    restart: always
    volumes:
      - ./volumes/mariadb:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=pass1234
      - MYSQL_PASSWORD=pass1234
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
```

참고로 Nextcloud는 sqlite가 기본 내장되어 있으며, 외부 데이터 베이스를 연동시킬 수도 있다. 나는 docker-compose.yml에 mariadb 컨테이너를 하나 올려서 연동 시켰다.     

이 상태로 compose up 시킨 후 80 포트 접속시 admin계정을 비롯한 초기 세팅을 할 수 있는 페이지가 나온다.

<img src="/nextcloud/first-setup.png" alt="drawing" width="100%"/>

일단 UI구성도 깔끔하고 여러모로 맘에 든다.   

이제 nginx로 프록시 올려서 SSL인증서만 먹이면 될 것 같다. 