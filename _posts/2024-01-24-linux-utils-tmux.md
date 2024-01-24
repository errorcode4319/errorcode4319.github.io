---
title: '[Linux] tmux #1, 기본 개념 및 사용법'
date: 2024-01-24 21:30:00 +/0900
categories: [linux]
tags: [linux]
author: sdk
toc: true
comments: false 
math: true 
mermaid: true 
img_path: /gh/errorcode4319/cdn/images
---


이번에는 tmux에 대해서 한번 정리해볼까 한다.    
> 참고 문서: [Tmux Getting-Started](https://github.com/tmux/tmux/wiki/Getting-Started)
{:.prompt-tip}


## tmux에 대해서
tmux는 하나의 터미널에서 여러 다른 터미널 프로그램을 실행시킬 수 있는 프로그램이다. 
정확히 말하면 tmux를 통해 독립적인 구동 환경(세션)을 만들고 터미널 환경에서 해당 세션에 접근할 수 있도록 해준다.

독립적인 구동 환경을 가지다보니 터미널을 종료해도 구동 상태를 유지시킬 수 있으며, 다른 터미널에서 세션에 접근할 수도 있다.

그러다 보니 다양한 상황에서 활용할 수 있는데
* 터미널 원격 접속이 끊어져도 프로그램을 계속 구동시켜야 할때 
* 원격 pc에서 구동중인 프로그램을 다른 로컬 pc에서 접근해야 할때
* 하나의 터미널에서 여러개의 프로그램을 동시에 구동시켜야 할때 

## tmux에 대한 기본 개념
Tmux를 사용하기 전 숙지하면 좋은 기본 개념들이 몇가지 있다

### tmux 서버
tmux는 기본적으로 서버-클라이언트 방식으로 동작한다. 

tmux서버는 백그라운드로 실행되며 터미널에서 tmux 명령어를 실행할때 자동으로 시작되고, 구동 중인 프로그램이 없을때 종료된다. 
사용자가 터미널에서 클라이언트를 실행하면 소켓 파일을 통해(`/tmp`) 서버와 통신을 시작한다. 

### Session, Window, Pane
> 추가 예정



## tmux 사용법

### 세션 생성 
`new-session` 명령을 통해 신규 tmux 세션을 생성할 수 있다. 
```sh
tmux new-session
# or 
tmux new    # 간소화된 버전, 기능은 동일하다
```

세션 생성시 세션의 이름은 0부터 순차적으로 부여된다. 이때 `-s` 플래그를 통해 세션의 이름을 임의로 지정할 수도 있다.
```sh
tmux new -smysession
```
세션 생성시 명령어를 추가하여, 세션 생성과 동시에 특정 명령 혹은 프로그램이 바로 실행되도록 할 수도 있다.
```sh
tmux new htop
```
> [new-session](https://man.openbsd.org/tmux#new-session) 링크를 타고가면 `new-session`에 대한 추가적인 옵션 정보를 확인할 수 있다.

### 상태 표시줄
클라이언ㅌ가 tmux 세션에 연결되면 하단 상태 표시줄을 통해 현재 세션의 상태를 볼 수 있다. 

![img](/tmux/tmux_status_line_diagram.png)   
이건 일일이 설명하기 보다는 이미지로 보는편이 빠를것 같다.

### prefix key
tmux 클라이언트에서 키보드를 입력하면 기본적으로 현재 활성화된 창으로 입력이 전달된다. 
그러다 보니 tmux 자체를 제어하기 위해서는 특수한 단축키를 입력해야 하며, 이를 **prefix key** 라고 부른다.   

기본적인 prefix key는 `C-b` (Ctrl + b) 이다. 
> `C-`: Ctrl, `M-`: Meta(alt키와 동일), `S-`: Shift 

prefix key를 입력하고 난 후에 추가적인 키 입력을 통해 tmux를 제어할 수 있다. 

예를 들어서 `C-b x`는 `C-b`를 입력하고 난 후에 `x` 키를 입력한다. 만일 `C-b C-x`가 들어온다면 `C-b` 입력 후 Ctrl키만 유지한채 `C-x`를 입력해 줘야 한다.   

또한 tmux 제어가 아닌, 내부 프로그램으로 prefix key (Ctrl + b)를 입력해야 할 경우 `C-b`를 두번(`C-b C-b`) 입력하면 된다.   

### 도움말
tmux 내부에서 `C-b ?`를 입력하면 도움말 화면을 볼 수 있다. 
```
C-b C-b     Send the prefix key                                                                      [38/38]
C-b C-o     Rotate through the panes                                                                        
C-b C-z     Suspend the current client                                                                      
C-b Space   Select next layout                                                                              
C-b !       Break pane to a new window                                                                      
C-b "       Split window vertically                                                                         
C-b #       List all paste buffers                                                                          
C-b $       Rename current session                                                                          
C-b %       Split window horizontally                                                                       
C-b &       Kill current window                                                                             
C-b '       Prompt for window index to select                                                               
C-b (       Switch to previous client                                                                       
C-b )       Switch to next client                                                                           
C-b ,       Rename current window                                                                           
C-b -       Delete the most recent paste buffer                                                             
C-b .       Move the current window                                                                         
C-b /       Describe key binding                                                                            
C-b 0       Select window 0                                                                                 
C-b 1       Select window 1                                                                                 
C-b 2       Select window 2                                                                                 
C-b 3       Select window 3                                                                                 
C-b 4       Select window 4          
... 생략 ...

``` 
설명을 읽고 필요한 기능의 단축키를 prefix key 항목에서 익힌 대로만 하면 입력하면 된다.   

터미널에서 다음 명령어를 통해 동일한 정보를 확인할 수 있다
```sh
tmux lsk -N|more
```

`C-b /`를 통해 개별적인 키의 기능을 확인할 수 있다. `C-b /` 입력 후 특정 키를 누르면 해당 키에대한 설명이 하단에 출력된다. (직접 해보자)

### command prompt
tmux 내부에서 `C-b :`를 통해 명령 프롬프트를 사용할 수 있다.

![img](/tmux/tmux_command_prompt.png)   

터미널에서 `tmux ...` 형태로 입력하는 커맨드를 프롬프트 내부에서도 사용할 수 있다.    
또한 세미콜론(`;`)을 통해 여러개의 tmux 명령을 한번에 수행할 수도 있다. 


### Attaching, Detaching
구동중인 세션에서 쉘로 돌아오는 것을 detaching 한다고 하며, tmux 내부에서 `C-b d` 혹은 `detach` 명령을 통해 수행 가능하다

```sh
# 세션 생성 후 내부에서 C-b d를 통해 detach
tmux new
[detached (from session 18)]
```
> 이때 detach는 세션의 구동 상태를 유지한 채 밖으로 빠져나오며 exit와는 다르다.
{:.prompt-tip}

반대로 `attach-session` 명령을 통해 쉘에서 구동중인 세션으로 접근(attaching) 할 수 있다.
```sh
tmux attach-session
# or
tmux attach     # 기능은 동일하다
```

`-t`를 통해 접근할 세션을 지정할 수 있다. 세션이 지정되지 않을 경우 가장 최근 사용한 세션을 사용한다. 
```sh
tmux attach -tmysession
```

### 세션 목록 보기
`ls` 명령을 통해 현재 구동중인 세션의 목록을 확인할 수 있다.
```sh
tmux ls

10: 1 windows (created Wed Jan 24 22:43:09 2024) (attached)
11: 1 windows (created Wed Jan 24 22:48:44 2024) (attached)
8: 1 windows (created Wed Jan 24 22:18:12 2024)
9: 1 windows (created Wed Jan 24 22:19:01 2024)
mysession: 1 windows (created Wed Jan 24 23:10:45 2024)
test: 1 windows (created Wed Jan 24 22:08:46 2024)
... 생략 ...

```

### tmux 서버 강제 종료
구동중인 세션이 없을 경우 tmux 서버는 자동으로 종료된다. 만일 tmux 서버를 강제로 종료시키고 싶을 경우 `kill-server` 명령을 통해 tmux 서버를 종료시킬 수 있다
```sh
tmux kill-server
```
물론 구동중인 세션들 또한 모두 날아간다


### 윈도우 생성
`new-window` 명령을 통해 윈도우를 생성할 수 있다. (`C-b c`로도 실행 가능)
```
:new-window
# or 
:neww   # new-window와 기능 동일
```
명령 실행시 `-n`플래그를 넣으면 윈도우의 이름을 지정할 수 있다. 
```
:neww -nmynewwindow
```
윈도우 생성시 신규 생성된 윈도우가 현재 윈도우로 설정되는데 이때 `-d`를 넣으면 기존 윈도우 환경을 유지시킬 수 있다
```
:neww -dnmynewwindow
``` 
윈도우 생성시 인덱스는 0부터 순차적으로 부여되며 `-t`플래그를 통해 임의로 인덱스를 지정할 수도 있다.
```
:neww -t999
```
세션과 마찬가지로 윈도우 생성시 실행시킬 명령을 지정할 수도 있다
```
:neww htop
``` 

### 윈도우 분할
`split-window` 명령을 통해 현재 윈도우를 여러개의 pane으로 분할시킬 수 있다.

![img](/tmux/tmux_split_window.png)   

`split-window` 명령에 사용 가능한 플래그는 다음과 같다
* `-h`: 수평 분할 (키 바인딩: `C-b %`)
* `-v`: 수직 분할 (키 바인딩: `C-b "`)
* `-d`: 현재 pane을 신규 pane으로 변경하지 않음
* `-b`: 신규 pane을 왼쪽 혹은 위쪽으로 배치 (오른쪽 혹은 아래로 배치됨)


### 현재 윈도우 변경
현재 윈도우를 변경하기 위해 다음과 같은 키 바인딩을 사용할 수 있다.
* `C-b 0` ~ `C-b 9`: 현재 윈도우를 0번 ~ 9번 인덱스에 해당하는 윈도우로 변경
* `C-b'`: 인덱스 번호 직접 입력 가능 (인덱스 범위가 0~9를 초과하는 경우)
* `C-bn`: 다음 윈도우로 변경
* `C-bp`: 이전 윈도우로 변경
* `C-bl`: 마지막 윈도우로 변경

> 해당 키 바인딩은 `select-window` 명령을 사용
{:.prompt-tip}

### 활성 pane 변경
분할된 윈도우에서 특정 pane을 활성화 시키기 위한 키 바인딩은 다음과 같다
* `C-b <방향키>`: 분할된 윈도우 환경에서 여러 pane을 방향키로 옮겨 다닐 수 있음
* `C-b q`: 현재 윈도우에 분할된 pane들의 번호를 잠깐동안 보여줌
* `C-b q 0~9`: 입력된 번호의 pane을 활성화  
* `C-b o`: 다음 번호의 pane을 활성화
* `C-b C-o`: 다음 번호의 pane과 현재 pane을 스왑

> 해당 키 바인딩은 `select-pane`과 `display-panes` 명령을 사용
{:.prompt-tip}

## 마치며
생각보다 내용이 너무 많아서 상당히 힘들다 (이거 괜히 했나...)    
나머지 내용들은 나중에 이어서 올려야 할것같다. 