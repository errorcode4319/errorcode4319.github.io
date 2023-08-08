---
title: '[C++ Template] 10. 템플릿 용어 정리'
date: 2023-08-07 21:00:00 +/0900
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

이번 포스팅에선 템플릿과 관련된 기본적인 용어에 대해 정리해볼까 한다.

## 클래스 템플릿? 템플릿 클래스?
템플릿인 클래스를 칭할 때 다소 애매한 구석이 있다.
- **클래스 템플릿**
    - 템플릿인 클래스. (특정 클래스군을 파라미터화해 설명하는 것)
- **템플릿 클래스**
    - 클래스 템플릿의 동의어 혹은 템플릿으로 생성된 클래스
    - 템플릿 식별자인 이름을 가지는 클래스라는 의미로도 쓰인다   

함수 템플릿, 멤버 템플릿, 변수 템플릿등도 동일하다.  

## 치환, 인스턴스화, 특수화 
템플릿 코드를 처리할 때 컴파일러는 템플릿 내의 템플릿 파라미터를 실제 템플릿 인자로 치환하는 작업을 한다. 치환 결과가 유효하지 않을 수도 있기에 잠정적으로만 치환하는 경우도 있다. 

치환된 템플릿을 통해 클래스, 타입 별칭, 함수 등의 일반적인 정의를 만들어내는 작업을 템플릿 인스턴스화라고 한다. 

의외로 템플릿 파라미터 치환으로 정의가 아닌 선언을 만드는 과정에 대한 용어는 아직 표준화된것이 없다. 다음과 같은 용어들이 있기는 하다.
- 부분 인스턴스화(partial instantiation)
- 선언의 인스턴스화(instantiation of a declaration) 
- 불완전한 인스턴스화(incomplete instatiation)    

인스턴스화 혹은 불완전한 인스턴스화를 통해 생성된 실체(entity)는 일반적으로 특수화(specialization)라고 한다.   

특수화의 경우 인스턴스화 과정에 의존하는 것이 아닌, 사용자가 임의로 선언할 수도 있다.

다음과 같은 코드가 있을 경우
```c++
template<typename T1, typename T2> // 클래스 템플릿 
class MyClass {
    // ...
};
```
```c++
template<>  // 명시적 특수화
class MyClass<std::string, double> {
    // ...
};
```
```c++
template<typename T>  // 부분 특수화
class MyClass<T, double> {
    // ...
};
```

일반적으로 인스턴스화를 통해 생성된 특수화(generated specialization)가 아닌, 사용자가 임의로 명시하는 경우 명시적 특수화(explicit spetialization)이라 칭한다.   

템플릿 파라미터중 일부를 남겨둘 경우 부분 특수화(parial specialization)라 한다. 또한 특수화에 대해 언급할때 일반 템플릿은 기본 템플릿(primary template)이라 한다.

## 선언과 정의
선언(declaration)과 정의(definition)는 이미 범용적으로 널리 쓰이는 용어이지만, 이번에는 표준 c++상에서 갖고 있는 약간은 정밀한 의미를 다뤄볼까 한다. 

선언이란 c++가 그 이름을 c++ 영역에 도입하거나 재도입한다는 뜻이다. 이러한 도입시에는 항상 그 이름의 부분 분류(partial classfication)가 포함되지만, 세부 사항이 꼭 필요하진 않다. 
```c++
class C;    // C를 클래스로 선언
void f();   // f()를 함수로 선언
extern int v;   // v를 변수로 선언
```
매크로 정의와 goto 라벨은 선언으로 간주되진 않는다.

선언에서 자체적인 구조에 대한 세부 사항이 알려지거나 변수의 저장 공간이 할당된다면 그것은 정의로 바뀐다. 
```c++
class C{};  // 클래스 C 정의(+선언)

void f() {  // 함수 f() 정의(+선언)
    std::cout << "func\n";
}

extern int v = 1;   // v에 대한 정의
int w;  // 변수 정의
```
클래스 템플릿이나 함수 템플릿의 선언이 몸체를 가질 경우 정의라고도 할 수 있다.
```c++
template<typename T>
void func(T);   // 선언

template<typename T>
class S{ /* ... */ };   // 정의 (+선언)
```

## 완전한 타입과 불완전한 타입
c++에서 타입은 완전할(complete)수도 있고 불완전할(incomplete)수도 있다. 
불완전환 타입은 다음과 같다
- 선언은 됐지만 아직 정의되지 않은 클래스
- 크기가 지정되지 않은 배열
- 요소의 타입이 불완전한 배열
- void
- 타입 혹은 열거 값이 정의되지 않은 상태의 열거형

```c++
class C;    // 불완전한 타입의 클래스 C
C const* cp;    // 불완전한 타입에 대한 포인터
extern C elems[10]; // 불완전한 타입을 요소로 갖는 배열
extern int arr[];   // 불완전한 타입의 배열 
```
```c++
class C { /*...*/ };    // 완전한 타입의 클래스 C
int arr[10];    // 완전한 타입의 배열 
```


## 단정의 법칙 (ODR)
정의는 다양한 실체(entity)들의 재선언에 대한 몇 가지 제약사항을 갖는다. 이들 제약사항을 통틀어서 단정의 법칙 혹은 ODR(one-definition rule)이라고 한다. 

ODR의 기본 법칙은 다음과 같다.(ODR에 대해서는 나중에 따로 다뤄볼까 한다.)
- **인라인이 아닌** 일반 함수, 멤버 함수, 전역 변수, 정적 데이터 멤버는 한 프로그램 내에서 단 한 번만 정의되어야 한다.
-  클래스 타입(구조체, 공용체 초함), 템플릿(전체 특수화는 제외), 인라인 함수 및 변수는 한 번역 단위(translate unit)마다 최대 한 번 정의되어야 하며, 모든 정의는 동일해야 한다.

나열해보니 다소 복잡해 보이긴 하지만 일반적으로 헤더와 소스로 선언과 정의부를 나눌때 유의해야 할 사항이라고 보면 된다. 이미 대다수의 c++ 개발자들이 어느정도 숙지중인 내용이지만, 그래도 보다 명시적으로 기본 원칙들을 나열해 봤다.

## 템플릿 인자(Argument)와 템플릿 파라미터(Parameter)
템플릿 인자(argument)와 템플릿 파라미터(parameter)는 명확하게 구분되는 용어이다. 간단하게 보자면 파라미터는 인자로 초기화된다. 
- 템플릿 파라미터(parameter)
    - 템플릿 선언 혹은 정의에서 키워드 `template` 다음에 나열된 이름들
- 템플릿 인자(argument)
    - 템플릿 파라미터의 자리에 대신 들어갈 아이템

```c++
// 템플릿 파라미터: T, N
template<typename T, int N>
class ArrayInClass {
public:
    T array[N];
};

// 템플릿 인자: double, 10
ArrayInClass<double, 10> ad;
```
>인자는 실체(actual) 파라미터, 파라미터는 형식적(formal) 파라미터로도 불린다.
{:.prompt-tip}