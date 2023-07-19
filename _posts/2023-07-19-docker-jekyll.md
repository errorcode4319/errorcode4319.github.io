---
title: '[Docker] 컨테이너 환경에서 Jekyll 서버 올리기'
date: 2023-07-19 23:30:00 +/0900
categories: [DevOps, Linux]
tags: [DevOps, docker, ruby, jekyll, linux]
author: sdk
toc: true
comments: false 
math: true 
mermaid: true 
img_path: /gh/errorcode4319/cdn/images
---

최근 작업 환경을 새로 세팅했다.    

간만에 블로그 포스팅도 올릴겸 루비랑 Jekyll을 다시 설치하려고 했는데, 블로그 하나때문에 로컬 환경에 루비랑 이것저것 설치하는게 좀 불만스러워 졌다. (개인적으로 루비를 아예 안쓴다.)   

그래서 이참에 컨테이너 기반으로 올려볼까 한다. 어차피 블로그 쓰는 용도로만 사용할 환경이니 크게 부담은 없었다.

## Dockerfile
Dockerfile은 다음과 같다. 
```Dockerfile
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Seoul

ENV GEM_HOME=/gems 
ENV PATH=/gems/bin:$PATH

RUN apt update && apt -y install tzdata git ruby-full build-essential zlib1g-dev

RUN gem install jekyll bundler

WORKDIR workspace
CMD     bundle install; bundle exec jekyll serve --livereload --host 0.0.0.0
```
이때 `/workspace`는 실제 작업 디렉토리 볼륨을 바인딩할 경로이며.
그 외엔 Jekyll 공식 매뉴얼대로 필요한 패키지들을 설치해 준다.   
> `--livereload`, `--host` 같은 옵션들은 `_config.yml`을 통해서도 설정 가능하다
{:.prompt-tip}

## docker-compose.yml
docker-compose.yml 파일은 다음과 같이 작성했다.
``` yml
version: "3"

services:
  jekyll:
    container_name: jekyll
    image: jekyll:0.1
    #build:
    #  context: .
    #  dockerfile: Dockerfile 
    ports:
      - 4000:4000 
    volumes:
      - ./:/workspace
```

본문에선 `jekyll:0.1`이라는 이름으로 이미지를 별도로 빌드해서 사용했지만, docker compose 자체적으로 이미지를 빌드해서 사용해도 상관 없다. 
> 작업 디렉토리는 jekyll 정적 웹 사이트가 구성된 저장소 경로이다. 
{:.prompt-tip}


## 실행
이제 메인 작업 디렉토리로 가서 (저장소) docker compose를 실행시켜 준다
```sh
dokcer compose up -d 
```
이후 웹 브라우저를 통해 jekyll 정적 웹 페이지를 확인할 수 있다.    
혹시 최신 포스팅이 뜨지 않는다면, 컨테이너 내부 타임존 설정이 제대로 되어있는지 확인해볼 필요가 있다. 