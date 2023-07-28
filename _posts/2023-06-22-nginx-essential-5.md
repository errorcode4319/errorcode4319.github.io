---
title: '[NGINX 기본기 다지기] 5. HTTP 인증'
date: 2023-06-22 23:55:00 +/0900
categories: [DevOps, NGINX]
tags: [nginx-cookbook-2/e, DevOps, infra, nginx, service, network, system, http, tcp/ip]
author: sdk
toc: true
comments: false 
math: true 
mermaid: true 
img_path: /gh/errorcode4319/cdn/images
---

이번 시간에는 Nginx를 활용한 HTTP 인증에 대해 다뤄볼까 한다.

## HTTP 기본 인증
기본 인증을 통해 서비스와 리소스를 안전하게 보호할 수 있다. 인증 파일은 다음과 같은 포맷으로 작성한다.
```
<username>:<password>
<username>:<password>:<comment>
```
- `<username>`: 인증할 사용자 이름 (시스템 유저와 무관하다)
- `<password>`: 패스워드
- `<comment>`: 부가 정보 (선택사항)

작성 예시는 다음과 같다.
```
admin:$1$LjYp9Btn$fn.N51gsNCxXaBoQfJTmW0
```
위 예시는 사용자명과 패스워드를 admin/admin으로 설정해둔 상태이다. 

이때 패스워드는 암호화된 형태로 입력이 되어야 하는데 다음과 같이 **openssl**을 통해 암호화된 패스워드를 생성할 수 있다.
```sh
openssl passwd <password>
```
```sh
# Ex
$ openssl passwd admin   
$1$LjYp9Btn$fn.N51gsNCxXaBoQfJTmW0
```
아파치에서 제공하는 **htpasswd**를 통해서도 생성할 수 있다. 
>구글링을 해 보면 **htpasswd**를 사용하는 포스팅이 더 많은것 같다.
{: .prompt-tip}

이후 해당 인증 파일을 다음과 같이 `location` 블록에서 사용할 수 있다.
```conf
location / {
    auth_basic              "Private Contents";
    auth_basic_user_file    conf.d/htpasswd;
}
```
- `auth_basic`: 인증 팝업창에 보여지는 내용이다.
- `auth_basic_user_file`: 위에서 작성한 인증 파일 경로를 입력한다.
    - **절대로 정적 리소스 경로에 포함하지 말자**

이후 브라우저를 통해 접속하면 다음과 같은 인증창이 뜨는것을 볼 수 있다.
![http auth basic](screenshot/auth_basic.png)


CLI 환경에서 **curl**을 통해 테스트 할 경우 다음과 같이 사용 가능하다
```sh
curl --user username:password https://localhost
```

> 패스워드는 기업에서 사용하는 LDAP나 Salted SHA-1과 같은 형식으로도 만들 수 있다.
Nginx는 여러 포맷과 해싱 알고리즘을 제공하지만, 대부분 보안이 취약하며 브루트포스로 탈취당할 여지가 있다.
{: .prompt-tip}

## 하위 요청을 통한 인증
`http_auth_request_module`을 사용해 별도의 인증 서비스로 요청을 보내고 요청자의 ID를 확인할 수 있다.
> 링크: [Module ngx_http_auth_request_module](http://nginx.org/en/docs/http/ngx_http_auth_request_module.html)
{: .prompt-tip}

```conf
location /private/ {
    auth_request        /auth;
    auth_request_set    $auth_status $upstream_status;
}

location = /auth {
    internal;
    proxy_pass      http://auth-server;
    proxy_pass_request_body     off;
    proxy_set_header Content-Length "";
    proxy_set_header X-Original-URI $request_uri;
}
```

- `auth_request`: 내부 인증 시스템의 URI를 지정한다
- `auth_request_set`: 인증을 위한 하위 요청의 응답으로 받은 값을 변수에 저장한다

`http_auth_request_module`은 Nginx 서버가 처리하는 모든 요청에 대한 인증을 제공한다. 사용자 요청에 대한 인증을 위해 하위 요청을 보내소, 인증 시스템으로부터 인증을 받는다.

`/auth` 경로에 구성된 `location` 블록은 원본 요청(헤더, 바디 포함)을 인증 서버로 전송한다. 하위 요청에 대한 응답 Status Code는 사용자 접근 허가 여부를 제공한다. 
- 200  -> 인증 성공
- 401 or 403 -> 인증 실패
인증 시스템에 request body가 필요하지 않다면, `proxy_pass_request_body` 옵션을 통해 비활성화 시킬 수 있다 (body 포함 여부를 비활성화 시키면 `Content-Length` 헤더 또한 빈 값이 필요) 

만일 인증 서비스가 요청 URI 혹은 부가적인 정보를 알아야 한다면, 요청 헤더를 커스터마이징해 해당 인증 서비스에 맞게 **유도리 있게 대처하자**.

이후 인증 서비스를 거치고 난 후 `auth_request_set`구문을 통해 응답 결과를 새로운 변수를 통해 저장한다.

## 마치며
서비스가 외부로 공개되는 순간, 어떤 인증 절차를 추가해도 **100% 완벽한 보안**은 힘들다. 결국에는 상황에 맞게 유도리 있께 대처하는 것이 가장 중요한 덕목중 하나라고 본다. 

추후 보안 관련된 내용도 포스팅할 생각이다.