---
title: '[C++ Template] 7. 인자 전달 방식'
date: 2023-08-01 22:00:00 +/0900
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


이번 시간에는 보다 인자 전달 방식에 대해 다뤄볼까 한다.

## Call by Value
인자를 값으로 전달할 경우 원치적으로 모든 인자는 복사된다. 특히 복사를 통해 객체를 생성할 경우 복사 생성자를 통해 초기화된다. 

기본적으로 복사 생성자 호출은 비용이 많이 드는 작업이다. 하지만 인자를 값으로 전달하더라도 다양한 방법으로 비싼 복사 연산을 피할 수 있으며, 컴파일러 자체적으로도 복사 연산을 최적화할 수 있다.

다음 코드를 보자
```c++
template<typename T>
void print(T arg) {
    // ...
}
```
위 코드에서 파라미터 `arg`는 전달된 인자가 무엇이든 간에 해당 값의 복사본이다. 이때 다음과 같이 `std::string`값으로 위 함수 템플릿을 호출하게 되면
```c++
std::string s = "test";
print(s);
```
`T`는 `std::string`으로 인스턴스화되어 다음과 같은 코드가 생성된다.
```c++
void print(std::string arg) {
    // ...
}
```

원칙적으로 이렇게 되면 `std::string` 인스턴스에 대한 깊은 복사를 수행해야 하므로, 높은 복사 비용이 발생한다. 하지만 사실 무조건 복사 생성자만 호출되는 건 아니다.
```c++
std::string getString() { /* ... */ }

std::string s = "test";

print(s);   // 복사
print(std::string("test")); // 어떻게든 최적화됨 (혹은 이동)
print(getString());         // 어떻게든 최적화됨 (혹은 이동)
print(std::move(s));    // 이동
```
인자를 값으로 받더라도 일반적인 lvalue가 아닌 prvalue 혹은 xvalue일 경우, 그에 따라 적절한 최적화를 수행한다. 따라서 위 코드에 작성된 `print()`의 경우 값으로 전달되는 파라미터로 선언하더라도 lvalue를 전달할 때에만 비용이 높아진다.(하지만 대체로 이런 경우가 많다) 
> prvalue: 임시 객체, 식별자를 갖지 않으며 이동 가능한 객체(혹은 표현식)   
xvalue: 이동 가능한 객체, 식별자를 가지며 이동 가능한 객체 (std::move를 쓴 경우)
{:.prompt-tip}

### 타입 소실 (Type Decaying)
인자를 값으로 전달할 경우 중요한 특성 중 하나는 타입 소실이 발생한다는 것이다.   

원시 배열은 포인터로 변환되며 `const`, `volatile`같은 한정자 또한 제거된다.
```c++
template<typename T>
void print(T arg) { /* ... */ }

const std::string c = "test";
print(c);       // -> print(std::string)
print("hi");    // -> print(char const*)

int arr[4];
print(arr);     // -> print(int*)
```
이전 포스팅에서도 한번 템플릿 인자를 통해 문자열과 원시 배열을 다루는 법에 대해서 다룬적이 있다.

## Call by Reference
인자를 참조자로 전달하는 경우 어떠한 경우에도 복사는 일어나지 않으며, 타입 소실 또한 발생하지 않는다. 하지만 간혹 전달할 수 없거나, 전달을 하더라도 최종적으로 인스턴스화 되는 타입이 문제가 될 수 있다.

### 상수 참조자 (const reference)
객체를 전달할 때 어떠한 복사도 방지하려면 상수 참조자(const reference)를 사용해야 한다.

```c++
template<typename T>
void printR(T const& arg) {
    // ...
}
```
이렇게 선언하면 전달받은 객체를 절대 복사하지 않는다. 

참조로 전달을 할 경우 내부적으로는 해당 인자의 메모리 주소를 활용하며 (사실 당연한 얘기다) 주소를 전달하는 것은 상당히 효율적이다. 하지만 주소로 전달하면 호출자의 코드를 컴파일할 때 호출된 쪽이 그 주소를 갖고 무슨 일을 할지 모른다. 

이론적으로는 호출된 쪽은 그 주소로 도달 가능한 모든 값을 변경할 수 있다. 즉 컴파일러는 호출 후 캐시나 레지스터에 올라왔을 수도 있는 모든 값을 유효하지 않다고 처리해야 한다. 물론 해당 값을 다시 로딩할때도 비용이 든다.

상수 참조자로 전달할 경우에도, 호출자가 자신의 비상수 참조자를 통해 참조된 객체를 변경할 수도 있기 때문에 컴파일러 입장에선 상수 참조자로 전달하더라도 변경사항이 없음을 보장할 수 없게된다.

inline을 통해 이 문제를 어느정도 완화시킬 수는 있다. 짧은 함수 템플릿의 경우 인라인으로 확장하기는 좋지만, 상당히 복잡한 알고리즘을 내포하고 있을 경우 인라인화하기 어려울 수 있다.

### 비상수 참조자 (non-const reference)
인자를 통해 값을 결과값을 반환하고 싶을 경우 비상수 참조자(non-const reference)를 전달한다.
```c++
template<typename T>
void outR(T& arg) {
    // ...
}
```
물론 위와 같이 비상수 참조자로 인자를 전달할 경우 prvalue 혹은 xvalue를 전달할 수 없다.
```c++
std::string s = "test";
outR(s);    // OK
outR(std::string("test"));  // 에러, prvalue
outR(std::move(s));     // 에러, xvalue 
```

그런데 여기서 템플릿이 약간 이상하게 동작하는 것을 볼 수 있는데, const 인자를 전달할 경우 rvalue를 전달할 수 있게 된다.

```c++
std::string const c = "test";
outR(c);    // OK, outR(std::string const&)
outR(std::move(c)); // OK, outR(std::string const&)
outR("hi"); // OK: outR(char const[3]&)
```
>`std::string const`에 `std::move()`를 사용할 경우 `std::string const&&`가 된다. 
이는 `std::string const`로 연역된다.
{:.prompt-tip}

물론 전달이 가능하다 할지라도, 내부적으로 값을 수정하는 경우 인스턴스화 시점에 컴파일 에러가 발생한다.

상수 참조자를 비상수 참조자로 전달하지 못하게 하고 싶다면 `static_assert()` 혹은 `std::enable_if<>`, `concept`을 사용할 수 있다.

```c++
// static_assert
template<typename T>
void outR(T& arg) {
    statis_assert(!std::is_const<T>::value, "Error Message");
    // ...
}

// enable_if
template<typename T,
    typename = std::enable_if_t<!std::is_const<T>::value>>
void outR(T& arg) {
    // ...
}

// concepts (c++20)
template<typename T>
requires !std::is_const_v<T>
void outR(T& arg) {
    // ...
}
```
### 전달 참조자 (forwarding reference)
전달 참조자는 이전 포스팅에서도 다룬 내용 내용이다. 전달 참조자를 사용할 경우 어떤 값이든 전달할 수 있으며, 복자를 하진 않는다

```c++
template<typename T>
void passR(T&& arg) {
    // ...
}
```
위 함수 템플릿의 인자 `arg`는 전달된 값이 rvalue인지 상수 or 비상수 lvalue인지 구분할 수 있다. (전달된 값의 유형에 따라 동작을 구분할 수 있다.) 

하지만 전달 참조자도 마냥 완벽한 것은 아니다. 다음 코드를 보자
```c++
template<typename T>
void foo(T&& arg) {
    T x;
}

foo(42);    // OK: T == int

int i;
foo(i);     // 에러: T == int&, foo()내 지역변수 x의 선언이 유효하지 않다
```

> 함수 템플릿에서 Call by Reference는 여러모로 피곤한 구석이 많다... 상황에 맞게 적절한 코드를 작성하자
{:.prompt-tip}

## std::ref(), std::cref()
`<functional>`에 선언된 `std::ref()`과 `std::cref()`을 사용할 경우, 인자를 값으로 전달(Call by Value)하는 경우에 임의로 참조로 전달할 수 있다. 다음 코드를 보자
> `std::cref()`는 `std::ref()`의 const 버전이다. 참고 링크: [std::ref, std::cref](https://en.cppreference.com/w/cpp/utility/functional/ref)
{:.prompt-tip}

```c++
template<typename T>
void printT(T arg) {
    // ...
}


std::string s = "hello";
printT(s);  // s 복사, printT(std::string)
printT(std::cref(s));   // s를 'Call by Reference 처럼' 전달
```

`std::cref()`을 사용할 경우 원래 인자를 참조하는 `std::reference_wrapper<>` 객체를 생성한 후 이 객체를 값으로 전달한다(엄연히 Call by Value이긴 하다).

해당 객체는 기존 타입으로 되돌리는 암묵적 형 변환 한 가지 연산만 지원하며, 이를 통해 원래 객체를 얻을 수 있다. 따라서 전달된 객체에 대해 유효한 연산자가 있을 경우, 해당 참조 래퍼(reference wrapper) 객체에도 사용할 수 있다.
```c++
#include <functional>
#include <string>
#include <iostream>

void printString(std::string const& s) {
    std::cout << s << '\n';
}

template<typename T>
void printT(T arg) {
    printString(arg);
}

std::string s = "hello";
printT(s);  
printT(std::cref(s)); 
```
이때 중요한 것은 기존 타입으로의 암묵적 변환이 필요하다는 것을 컴파일러 또한 알 필요가 있다. 즉, 원본 객체를 필요로 할 경우 암묵적 형 변환이 발생하는 코드를 작성할 필요가 있다.    

그래서 `std::ref()`, `std::cref()`는 보통 일반 코드를 통해 객체를 전달할 때 잘 동작한다. 
다음과 같이 `arg`를 바로 출력하려고 하면 오류가 발생한다. 
```c++
template<typename T>
void print(T arg) {
    std::cout << arg << '\n';
}


std::string s = "hello";
printT(std::cref(s));   // 에러
```
`std::reference_wrapper<>`는 `operator<<`을 지원하지 않기 때문에 에러가 발생한다. 
당연히 비교 연산 또한 없기 때문에 일반적인 값과 비교하는 코드 역시 오류가 발생한다.

## 반환 값 다루기
함수 실행 후 결과 값을 반환할때도 값 또는 참조자로 반환할 수 있다. 각각의 특성을 고려하여 적절한 반환형을 제공하는 것은 필요한 부분이기도 하다. 
 
하지만 함수 템플릿의 반환값이 템플릿 파라미터에 종속되어 있다면, 다음과 같은 오류가 발생할 수 있다.
```c++
template<typename T>
T retR(T&& p) {
    return T{...};  // lvalue에 의해 호출될 경우, 참조자를 반환한다(위험)
}
```
`T`를 값으로 연역하는 다음 코드 역시, 해당 인자를 임의로 참조자로 명시할 수 있다.
```c++
template<typename T>
T retV(T p) {
    return T{...};
}

int x;
retV<int&>(x);  // int& retV(int& p)로 인스턴스화 된다..
```

이럴땐 다음 방법을 통해 무조건 항상 값으로 반환하도록 만들 수 있다.
```c++
// 방법1: std::remove_reference<> 
template<typename T>
typename std::remove_reference<T>::type retV(T p) {
    return T{...};  
}

// 방법2: auto 반환 (c++14 이상 지원) 
template<typename T>
auto retV(T p) {
    return T{...};  
}
```

## 마치며
템플릿 인자 구성은 언제나 고민의 연속인 듯 하다. 다양한 구성에 대한 특징을 보다 자세히 이해하고, 상황에 맞는 적절한 코드를 작성하는 것이 권장한다.     