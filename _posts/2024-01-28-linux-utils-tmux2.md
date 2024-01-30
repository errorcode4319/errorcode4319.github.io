---
title: '[Linux] tmux #2. 더 유용한 기능들'
date: 2024-01-28 21:00:00 +/0900
categories: [linux]
tags: [linux]
author: sdk
toc: true
comments: false 
math: true 
mermaid: true 
img_path: /gh/errorcode4319/cdn/images
---


지난 포스팅에 이어서 tmux에 대해 못다룬 내용들을 마저 정리해보려고 한다.    

## 트리 모드

Tmux에서 트리 모드를 사용하면 현재 구동중인 모든 세션과 윈도우의 목록을 볼 수 있다.
![img](/tmux/tmux_tree_mode_session.png)
![img](/tmux/tmux_tree_mode_window.png)   

- `C-b s`: 세션 단위로 목록 조회 실행
- `C-b w`: 윈도우 단위로 목록 조회 실행

트리 모드 사용시 방향키와 엔터를 통해 접속할 윈도우를 선택할 수 있고, 파일탐색기처럼 세선내 윈도우 목록도 열고 닫을 수 있다.

트리모드에서 사용가능한 기능이 상당히 많은데
- `Enter`: attach 시킬 Session, Window, Pane 선택
- 방향키: 이동
- `x`: 선택 항목 제거
- `X`: 태깅된 항목 제거
- `<`: 프리뷰 스크롤 (좌측)
- `>`: 프리뷰 스크롤 (우측)
- `C-s`: 검색
- `n`: 마지막 검색 반복
- `t`: 태깅 상태 토글
- `C-t`: 전체 항목 태깅
- `T`: 전체 항목 태깅 제거
- `:`: 선택 항목 혹은 태깅 항목에 대한 커맨드 프롬프트 실행
- `O`: 재정렬
- `r`: 재정렬 (정렬 순서 반대로)
- `v`: 프리뷰 토글
- `q`: 트리 모드 종료


## 다른 클라이언트 접속 해제

`C-b D`를 누르면 현재 접속중인 클라이언트의 목록을 볼 수 있다.

이동, 태그 키는 트리 모드와 동일하고 접속 해제(Detach)를 위한 키가 별도로 존재한다.
- `Enter`: 현재 선택된 클라이언트 Detach
- `d`: `Enter`키와 동일
- `D`: 태깅된 클라이언트 제거
- `x`: 현재 선택된 클라이언트를 detach 시키고, 구동중인 쉘을 종료
- `X`: 태깅된 클라이언트를 detach 시키고, 구동중인 쉘을 종료

## Session, Window, Pane 제거
 
다음 키 바인딩을 통해 윈도우와 Pane을 제거할 수 있다.

- `C-b &`: 현재 윈도우 제거 (`kill-window` 커맨드에 바인딩)
- `C-b x`: 현재 pane 제거 (`kill-pane` 커맨드에 바인딩)

세션의 경우 `kill-session` 커맨드를 통해 제거할 수 있으며, 별도의 키 바인딩이 존재하진 않는다.

## Rename
다음 키 바인딩을 통해 현재 접속중인 session과 window의 이름을 변경할 수 있다. 
- `C-b $`: 세션 이름 변경 (`rename-session` 커맨드에 바인딩)
- `C-b ,`: 윈도우 이름 변경 (`rename-window` 커맨드에 바인딩)

## Swapping

`swap-window`, `swap-pane` 커맨드를 통해 현재 활성화된 window 혹은 pane을 다른것과 스왑할 수 있다.

스왑을 위해서는 먼저 마킹된 pane이 필요하다.
- `C-b m`: pane 마킹
- `C-b M`: pane 마킹 해제

마킹된 pane의 경우 아래 이미지와 같이 모서리 부분이 하이라이트 처리된다

![img](/tmux/tmux_pane_marking.png)   

이제 다른 pane선택 후 커맨드 프롬프트를 통해 `swap-pane`을 입력하면 기존에 마킹된 pane과 현재 pane이 스왑된다. pane 스왑은 다른 윈도우에서도 사용 가능하다.
마찬가지로 `swap-window` 커맨드를 입력하면 마킹된 pane이 존재하는 윈도우와 현재 윈도우가 스왑된다.

단일 윈도우 내에서 이전 혹은 다음 순서의 pane과 스왑시키기 위해서는 각각 `C-b {`, `C-b }` 키 바인딩을 사용할 수 있다.

## Moving
윈도우의 인덱스 번호를 변경하기 위해서는 `move-window` 혹은 `C-b .`를 통해 수행할 수 있다. 

```
:move-window -t999  # 현재 윈도우의 인덱스 번호를 999로 변경
# or
:movew -t999    # move-window와 동일
```

기존에 존재하는 윈도우 인덱스일 경우 옮길수 없으며, `-k` 플래그를 사용하면 강제로 인덱스를 덮어쓸 수 있다.
```
:move-window -kt999
```   
인덱스 목록에 빈 번호가 존재할 경우 (예: 0, 1, 3, 9 ...) `-r` 플래그를 통해 순차적으로 정렬 시킬 수 있다. 
```
:movew -r
```

## Pane 크기 조정
`C-b C-<방향키>` 조합의 키 바인딩을 통해 현재 pane의 크기를 조절할 수 있다. 
- `C-b C-Left`
- `C-b C-Right`
- `C-b C-Up`
- `C-b C-Down`

좀 더 큰 단위로 pane 사이즈를 조절하고자 할 경우 컨트롤키 대신 메타(Alt) 키를 통해 조절 가능하다
- `C-b M-Left`
- `C-b M-Right`
- `C-b M-Up`
- `C-b M-Down`

위 키 바인딩은 모두 `resize-pane` 커맨드를 사용한다. 

또한 `C-b z` 키 바인딩을 통해 단일 Pane을 전체 화면으로 키울 수 있다. (전체화면 해제시에도 동일)

## 윈도우 레이아웃
현재 pane을 사전 정의된 레이아웃으로 재배치시켜주는 기능을 제공한다

`C-b Space` 키를 통해 레이아웃을 변경할 수 있으며 다음 키 바인딩을 통해 특정 레이아웃을 선택할 수 있다.
- `C-b M-1`: 수평 정렬
- `C-b M-2`: 수직 정렬
- `C-b M-3`: 상단에 메인 창 하나, 나머지는 하단에 수평 정렬
- `C-b M-4`: 좌측에 메인 창 하나, 나머지는 우측에 수직 정렬
- `C-b M-5`: 열과 동일한 수의 행으로 타일링

> 이건 직접 해 보자. 텍스트로 설명하기가 힘들다

## 윈도우, Pane 찾기

`C-b f` 키 바인딩을 통해 윈도우 혹은 pane 이름을 검색할 수 있다. 

검색시 해당 이름을 찾을 수 없을경우 `filter: no matches`가 출력되며 모든 window, pane의 목록이 제공된다

![img](/tmux/tmux_window_find.png)

## 마우스 사용 활성화
Tmux에서도 마우스 입력 기능을 사용할 수 있다. 진짜 별의별 기능이 다 들어가 있다

기본적으로는 비활성화 되어 있기는 한데 다음 커맨드를 통해 마우스를 활성화 시킬 수 있다.
```
:set -g mouse on
```

![img](/tmux/tmux_mouse_sample.png)

이건 직접 캡쳐를 할 수가 없어서 다른 이미지를 가져왔다. 

## 마치며

아직 정리하지 못한 내용이 많지만, 일단 tmux와 약간 더 가까워 진 것 같다.

[Tmux Getting-Started](https://github.com/tmux/tmux/wiki/Getting-Started)

기본 사용법 외에도 tmux 환경을 커스터마이징 할 수 있는 기능이 제공되니 한번쯤 읽어보기를 권장한다. 