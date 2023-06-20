---
title: 'code-server, VSCode를 웹 브라우저로 접속하기'
date: 2023-06-20 23:35:00 +/0900
categories: [Programming, ETC]
tags: [vscode, editor, web, system, http]
author: sdk
toc: true
comments: false 
math: true 
mermaid: true 
img_path: /gh/errorcode4319/cdn/images
---



## code-server
>공식 깃 페이지: [GitHub - coder/code-server: VS Code in the browser](https://github.com/coder/code-server)
{: .prompt-tip}
visual studio code를 웹 브라우저에서 구동시켜주는 서버 타입의 vscode이다. 기본적인 VSCode와 동일하게 동작한다. 웹 브라우저를 통해  원격지에 대한 코드 편집, 터미널 사용, 파일 전송을 사용할 수 있다. 물론 모바일 환경에서도 접속 가능하다.

## 설치
``` sh
wget https://github.com/coder/code-server/releases/download/v4.14.0/code-server_4.14.0_amd64.deb
sudo dpkg -i code-server_4.14.0_amd64.deb
sudo systemctl enable --now code-server@<username>  # 중요!!
```
>Releases 페이지에서 타 플랫폼에 대한 패키지 파일을 설치할 수 있다. (본 문서는 Ubuntu 22.04 기준으로 작성됨)
{: .prompt-tip}


설정 파일을 통해 패스워드와 바인딩 주소를 변경한다. (설정 가능한 세부 옵션은 공식문서 참고)
``` sh
vi ~/.config/code-server/config.yaml
```
```
bind-addr: <ip>:<port>
auth: password
password: <password>
cert: false
```
>평문 패스워드가 아닌 해싱된 패스워드 값(hashed password)으로 사용할 수도 있다. (필요하면 구글링)
{: .prompt-tip}

이후 다음 명령을 통해 code-server 서비스를 재구동한다.
``` sh
sudo systemctl restart code-server@<username>
```

이후 해당 `bind-addr`의 내용에 따라 웹 브라우저를 통해 해당 포트번호로 접속하면 웹 브라우저로 vscode를 사용할 수 있다.

## 마치며
이 좋은걸 이제 알았다니, 앞으로 요긴하게 써먹어 봐야할것 같다.