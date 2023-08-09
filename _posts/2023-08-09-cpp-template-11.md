---
title: '[C++ Template] 10. 제네릭 라이브러리'
date: 2023-08-09 22:00:00 +/0900
categories: [c++, template]
tags: [c, c++, template, cpp-templates-complete-guide]
author: sdk
toc: true
comments: false 
math: true 
mermaid: true 
img_path: /gh/errorcode4319/cdn/images
image:
    path: /languages/cpp-icon.png
    alt: C++
---

이번 포스팅에선 템플릿을 통해 제네릭한 라이브러리를 작성하는 것에 대해 다뤄볼까 한다. 

## 호출 가능한 객체
흔히 함수의 인자로 호출 가능한 실체를 전달하는 경우 콜백(Callback) 이라는 용어를 사용한다.    

C++에서 콜백으로 사용할 수 있는 타입들은 다음과 같다. 
- 함수 포인터
- `operator()`를 오버로딩한 클래스
- 함수에 대한 포인터 혹은 레퍼런스를 도출하는 변환 함수를 갖는 클래스
위 타입들을 통틀어 함수 객체라고 칭하며, 이는 호출 가능한 객체(Callable Object)를 의미한다. 

### 함수 객체 지원
표준 라이브러리에서 제공하는 `for_each()`를 다음과 같이 구현할 수 있다. 
```c++
template<typename Iter, typename Callable>
void for_each(Iter current, Iter end, Callable op) {
    while(current != end) {
        op(*current);
        ++current;
    }
}
```
위 함수 템플릿은 마지막 인자(`op`)로 함수 객체를 받고 있다. 

해당 인자로 일반적인 함수를 전달할 경우, 타입 소실이 발생하며 해당 함수에 대한 포인터 타입으로 연역된다. 물론 참조를 통해 타입 소실을 막을 수 있지만 함수 타입에 const는 사용할 수 없다(무시된다).   

일반적을 c++코드에서는 `operator()`를 오버로딩한 호출 가능한 객체를 전달하는 것이 보다 보편적이다.
```c++
op(*current);   
// 다음과 같이 변환된다
op.operator()(*current);
```
또한 클래스 타입의 객체라면 대리 호출 함수(surrogate call function)에 대한 포인터나 참조자로 변환될 수 있다.
```c++
(op.operator F())(*current);
```
F는 임의의 함수 포인터 혹은 참조자 형식이다. 

람다를 사용할 경우 클로저를 생성하며, 이는 일반적인 호출 가능한 객체와 별반 다를바가 없다. 
허나 캡처가 없을 경우 함수 포인터로의 변환 연산자를 생성한다. 


