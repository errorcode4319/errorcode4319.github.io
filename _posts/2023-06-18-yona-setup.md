---
title: 'Yona 이슈 트래커 설치'
date: 2023-06-18 22:00:00 +/0900
categories: [DevOps, Etc]
tags: [DevOps, network, system, issue tracker]
author: sdk
toc: true
comments: false 
math: true 
mermaid: true 
img_path: /gh/errorcode4319/cdn/images
---

Yona 라는 이슈트래커를 개인용 서버에 설치해볼까 한다. (공식 페이지: [Yona](https://yona.io/))

## 환경 구성
작업 환경은 다음과 같다.
- Ubuntu 22.04 
- docker, docker-compose
사실 컨테이너만 구동되면 OS는 뭘 사요하든 무관하다.

## 설치 시도
공식 깃헙 저장소(([yona-projects/yona](https://github.com/yona-projects/yona)))의 Readme를 읽어 보면 **Docker를 이용한 설치** 항목이 다음과 같이 설명되어 있다.   
`Docker를 이용해 설치하실분은 pokev25 님의 https://github.com/pokev25/docker-yona 를 이용해주세요.`

바로 해당 저장소로 들어가 보면 [docker-yona](https://github.com/pokev25/docker-yona) 
docker compose를 를 통해 바로 Yona 서비스를 올릴 수 있도록 이미 환경이 다 세팅되어 있다.

해당 저장소를 내려받은 후 `docker compose up`을 사용해 Yona를 컨테이너 형태로 바로 올릴 수 있다. 

이때 계속 구동에 실패하길래 로그를 보니 다음과 같은 내용을 볼 수 있었다.

`docker-yona-yona-1     | Caused by: java.sql.SQLNonTransientConnectionException: Could not connect to address=(host=127.0.0.1)(port=3306)(type=master) : Connection refused (Connection refused)`

![Pepe WHY?](/pepe/pepe-why-pepe.gif)

공식 문서를 다시 보니 DB를 먼저 설치해야 한다고 한다. 하지만 DB를 또 설치하기 번거로운 관계로 `docker-compose.yml` 파일을 수정해 DB도 같이 올려볼까 한다.

## docker-compose.yml 수정
다음과 같이 `yona-db` 서비스를 추가했다. (도커 허브: [mariadb](https://hub.docker.com/_/mariadb))
``` yaml
version: '3'

services:
  yona:
    build: .
    image: pokev25/yona:1.15.0
    restart: always
    environment:
      - BEFORE_SCRIPT=before.sh
      - JAVA_OPTS=-Xmx2048m -Xms1024m
    volumes:
      - ./data:/yona/data
    ports:
      - "9000:9000"
  yona-db:
    image: mariadb:10.3
    restart: always
    environment:
      - MARIADB_ROOT_PASSWORD=root1234
      - MARIADB_USER=yona
      - MARIADB_PASSWORD=pass1234
      - MARIADB_DATABASE=yona       
      - TZ=Asia/Seoul
    volumes:
      - ./yona-db:/var/lib/mysql    # DB 데이터 백업 경로 
```
이상태로 최초 구동 시엔 여전히 DB접속에 실패한다. 이때 `data/` 경로가 같이 생기는데(최초구동시) 이후 해당 경로 내에 설정 파일을 수정해야 한다.
`data/conf/application.conf` 파일을 열어 `# MariaDB` 항목을 찾아 접속 정보를 수정한다.
```
# MariaDB
db.default.driver=org.mariadb.jdbc.Driver
db.default.url="jdbc:mariadb://yona-db:3306/yona?useServerPrepStmts=true"
db.default.user=yona
db.default.password=pass1234
```

이후 웹 브라우저를 통해 9000번 포트로 접속해 보면(http://localhost:9000) 다음과 같이 Yona 초기 설정 페이지를 볼 수 있다.
![Yona First Setup](/screenshot/20230618-yona-setup.png)


## 마치며
금전적인 부담을 덜기 위해 Yona를 설치했지만, 개인적으로는 Jira가 좀 더 편한것 같다. 때론 남이 대신 관리해주는걸 사용하는게 가장 속편하다. 하지만 뭐든지 직접 세팅하는게 가장 재밌다(믿을만한지는 모르겠다).

일단 더 써 봐야 알 것 같다. 다음에는 깃랩도 개인 서버에 올려봐야겠다.