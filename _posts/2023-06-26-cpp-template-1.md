---
title: '[C++ Template] 1. 함수 템플릿'
date: 2023-06-26 23:44:00 +/0900
categories: [c++, template]
tags: [c, c++, template, cpp-templates-complete-guide]
author: sdk
toc: true
comments: false 
math: true 
mermaid: true 
img_path: /gh/errorcode4319/cdn/images
---

이번 기회에 C++ 템플릿에 대해서 처음부터 끝까지 쭉 연재해 나갈 계획이다. 비록 얼마나 긴 여정이 될지 모르겠지만... 하는데까지 해볼까 한다. 

이번시간에는 함수 템플릿에 대해서 다뤄볼까 한다. 템플릿의 가장 기본적인 용법에 대해 다뤄볼 생각이다.

## 함수 템플릿
함수 템플릿은 함수군(function family)을 표현할 수 있게 파라미터화한 함수다. 함수 템플릿은 다양한 형식에 대해 호출될 수 있는 함수적 동작(functional behavior)을 제공한다. 

함수의 일부 요소가 정해지지 않았다는 것을 제외하고는 일반 함수와 거의 같은 기능을 수행한다. 이때 정해지지 않고 남은 부분은 파라미터화된 템플릿 요소이다.

### 템플릿 정의
다음은 두 값 중 큰 값을 반환하는 함수 템플릿이다.
```c++
template<typename T>
T max(T a, T b) {
    return b < a ? a : b;
}
```

템플릿에 대한 가장 기본적인 예시이다. 위 함수는 파라미터 `a`와  `b`의 값을 비교하여, 더 큰 값을 반환하는 함수군을 제공한다. 이때 해당 파라미터의 타입은 템플릿 파라미터 `T`로, 아직 정해지지 않은 타입이다. 

위 예제와 같이 템플릿 파라미터는 다음과 같은 문법을 사용해 명시한다.
```c++
template< ... >
```
위 예제에서 사용된 파라미터 목록은 `typename T`이다. 타입 파라미터(`typename`)가 C++코드 전반에 걸쳐 가장 흔히 사용되지만, 사용 가능한 다른 파라미터도 많다(이건 나중에).

위 예제에서 타입 파라미터는 `T`를 사용한다. 물론 `T`가 아닌 다른 이름을 사용할 수 있으나, 일반적으로 `T`를 많이 사용한다. 타입 파라미터는 함수를 호출할 때 결정할 임의의 타입을 나타낸다. 위 예제에서는 `a`와  `b`를  `<` 연산자로 비교하므로, 타입 `T`는 `<`연산자를 지원해야 한다.



> `typename`대신 `class`라는 타입 파라미터도 사용 가능한다. `typename` 키워드가 C++98 표준을 만드는 중 상당히 늦게 도입된 탓에, 이전에는 `class` 키워드를 타입파라미터로 사용해야 했다고 한다. 그리고 `class`역시 여전히 유효하다
{: .prompt-tip} 

### 템플릿 사용 
다음 코드는 앞서 작성한 `max<T>` 함수를 호출하는 예시이다.
```c++
#include <iostream>
#include <string>

template<typename T>
T max(T a, T b) {
    return b < a ? a : b;
}

int main() {

    int i = 42;
    std::cout << "max(7,i):  " << max(7, i) << '\n';

    double f1 = 3.4;
    double f2 = -6.7;
    std::cout << "max(f1,f2):  " << max(f1, f2) << '\n';

    std::string s1 = "mathematics";
    std::string s2 = "math";
    std::cout << "max(s1,s2):  " << max(s1, s2) << '\n';
}
```
위 코드에서 `max()`함수는 총 세번, 각기 다른 타입으로 호출된다. 

일반적으로 템플릿은 모든 다양한 타입을 지원하는 하나의 구현체가 컴파일되지 않는다. 대신 템플릿이 사용될 때마다 각 타입에 맞는 구현체를 컴파일러가 만들어낸다.

```c++
int i = 42;
max(7, i);
```
위와 같이 `max()`함수를 `int` 타입으로 사용할 경우, 실제로는 다음과 같이 `max(int, int)`에 대한 구현체가 생성된다.
```c++
int max(int a, int b) {
    return b < a ? b : a;
}
```

템플릿 파라미터를 실제 형식으로 만드는 작업을 인스턴스화(instantiation)라고 하며, 이를 통해 템플릿의 인스턴스(instance)가 생성된다. 

마찬가지로 `max(f1,f2)`와 `max(s1,s2)` 역시 `double max(double, double)`와 `std::string max(std::string,std::string)`으로 인스턴스화된다.
>템플릿의 인스턴스는 OOP의 인스턴스와 약간 의미가 다르다
{: .prompt-tip}

### 이중 컴파일
함수 템플릿 내에서 사용된 모든 연산자를 지원하지 않는 형식에 대해 템플릿을 인스턴스화하면 컴파일 오류가 발생한다. 
```c++
std::complex<float> c1, c2;
max(c1, c2);    // Compile Error !!
```
이를 위해 템플릿은 두 번의 컴파일 과정을 거친다.
1. 템플릿 자체의 문법이 정확한지 검사한다. (이때 템플릿 파라미터는 무시한다)
2. 인스턴스화 시점에 코드의 유효성을 검사하기 위해 템플릿 코드를 다시 검사한다.

또 다른 예시가 있다.

```c++
template<typename T>
void foo(T t) {
    undeclared();   // undeclared()가 선언되지 않았다면 첫 번째 단계 컴파일 오류
    undeclared(t);  // undeclared(T)가 선언되지 않았다면 두 번째 단계 컴파일 오류
    static_assert(sizeof(int) > 10, "int too small");
    static_assert(sizeof(T) > 10, "T too small");   
    // 크기가 10보다 작은 T로 인스턴스화 되었다면 실패
}
```
이름을 두 번 검사한다는 점에서 두 단계 룩업(loopkup) 이라고 한다(나중에 다시 다룰 예정).

>일부 컴파일러는 첫 번째 컴파일 단계에서 전체 검사를 하지 않는다.
{: .prompt-tip}

함수 템플릿을 사용해 인스턴스화를 시키기위해서 컴파일러가 템플릿의 정의를 알아야 한다. 일반 함수는 컴파일과 링크가 분리될 수 있지만, 템플릿을 사용하면 무조건 컴파일 타임에 처리되어야 한다.   
물론 이러한 문제를 해결하기 위한 방법 또한 존재하지만, 일단은 모든 템플릿은 헤더 파일에 구현하는 것으로 하겠다.

## 템플릿 인자 연역(추론)
코드에서 어떠한 인자로 `max()`와 같은 함수 템플릿을 호출하면 해당 인자의 타입을 통해 해당 함수 템플릿의 타입을 결정한다. 앞선 예시와 같이 두 `int`형 인자를 넘긴다면, 컴파일러는 `T`를 `int`형으로 결정한다.  
>타입 연역은 타입 추론과 같은 의미로 사용된다. 보다 자세하게 파고 들면 연역은 추론의 두 가지 유형중 하나이다. 하지만 타입 추론 이라는 표현 또한 보편적으로 사용되는듯 하다...  
{: .prompt-tip} 

하지만 `T`가 타입의 일부을 이루고 있을 수도 있다.
```c++
template<typename T>
T max(const T& a, const T& b) {
    return b < a ? a : b;
}
```
위 코드와 같이 `T`에 상수 참조(const reference)를 추가할 경우, 마찬가지로 `int`형 인자를 전달하면 `T`는 `int`로 연역(deduction)된다. `int`형 인자를 넘기면 함수 파라미터는 `int const&`와 일치하기 때문이다.

다음 코드를 살펴보자.
``` c++
template<typename T>
T max(T a, T b) { ... };

const int c = 42;
max(i, c);      // T는 int로 연역된다.
max(c, c);      // T는 int로 연역된다.
int& ir = i;
max(i, ir);     // T는 int로 연역된다. 
int arr[4];
foo(&i, arr);   // T는 int*로 연역된다.
```

위 코드는 모두 정상적으로 연역을 수행한다. 하지만 다음 코드는 컴파일 오류가 발생한다.
```c++
max(4, 7.2);    // T는 int나 double로 연역될 수 있다. (두 인자의 타입이 다름)
std::string s;
foo("hello", s);    // T는 char const[6] 혹은 std::string으로 연역될 수 있다. 
```
해당 오류는 다음과 같이 해결할 수 있다.
```c++
max(static_cast<double>(4), 4.2);   // 두 인자의 타입이 일치하도록 만든다
max<double>(4, 4.2);    // 컴파일러가 타입 연역을 시도하지 않도록, 임의로 타입을 명시한다.  
```

### 기본 인자에 대한 타입 연역(추론)
기본 인자에 대해서는 타입 연역을 하지 않는다.
```c++
template<typename T>
void f(T = "");


f(1);   // T == int
f();    // 에러
```

기본 인자를 사용해 타입 연역을 수행하고 싶다면 다음과 같이 코드를 수정해야 한다.
```c++
template<typename T = std::string>
void f(T = "");


f();    // OK
```

## 다중 템플릿 파라미터 
템플릿 파라미터는 얼마든지 추가할 수 있다.
```c++
template<typename T1, typename T2>
T1 max(T1 a, T2 b) {
    return b < a ? a : b;
}

auto m = max(4, 7.2); 
```
위 코드에서 두 인자는 서로 다른 템플릿 파라미터를 사용하므로(`T1`, `T2`) 두 인자의 타입이 달라도 타입 연역이 가능하다. 허나 위 `max()` 함수의 경우 인자의 순서에 따라 반환형이 달라진다는 문제가 있다. 이를 해결하기 위해 다음과 같은 방법을 사용할 수 있다.

### 반환형을 위한 템플릿 파라미터
템플릿은 기본적으로 인자를 통한 타입 연역이 가능하기 때문에, 템플릿 파라미터에 대한 타입을 명시하지 않아도 된다. 하지만 다음과 같이 타입을 임의로 명시할 수도 있다.
``` c++
template<typename T>
T max(T a, T b);

max<double>(4, 7.2);    // T == double
```
혹여나 인자를 통해 타입을 결정할 수 없는 경우, 템플릿 파라미터를 명시해야 한다.
``` c++
template<typename T1, typename T2, typename TR>
TR max(T1 a, T2 b);

max(4, 7.2);    // 에러, Rt를 연역할 수 없다.
max<int, double, double>(4, 7.2);   // 컴파일 가능, 하지만 코드가 너무 장황하다
```
물론 위와 같은 경우, 템플릿 파라미터의 순서를 바꿔 반환형만 연역하도록 수정할 수도 있다.
``` c++
template<typename T1, typename T2, typename TR>
TR max(T1 a, T2 b);

max<int>(4, 7.2);
```

### 반환형 연역(추론)
반환형이 템플릿 파라미터에 종속된다면 컴파일러가 자동으로 반환형을 연역하도록 할 수 있다.
``` c++
template<typename T1, typename T2>
auto max(T1 a, T2 b) {
    return b < a ? a : b;
}
```
위 코드는 C++14 이상에서 유효한 코드이다. 반환형으로 `auto`를 사용할 경우, 함수 본문 내 `return` 구문을 통해 실제 반환 타입을 연역한다. `return` 구문이 여러 개 있다면 서로 동일한 타입을 반환해야 한다. 

C++11에서는 인자를 통해 반환형을 도출하기 위해 후위 반환 타입(trailing return type)을 사용한다. 
``` c++
// C++ 11 
template<typename T1, typename T2>
auto max(T1 a, T2 a) -> decltype(b<a?a:b) {
    return b < a ? a : b;
}
```
위와 같이 `decltype`구문을 통해 반환형을 연역할 수 있는데, 이때 `T1`과 `T2`가 다른 타입을 가질 경우 공통된 타입을 찾는다. 실제 로직과 무관하게, 반환형이 중요하므로 `decltype`구문은 다음과 같이 바꿔도 된다.
```c++
-> decltype(true?a:b) 
```

### 공통 타입으로 반환형 결정
C++ 11부터는 C++ 표준 라이브러리에서 보다 일반화된 타입을 선택하는 방법을 제공한다. `std::common_type<>::type`은 템플릿 인자로 전달 된 두 개 이상의 서로 타른 형식의 공통 타입을 도출해낸다. 
``` c++
// C++ 11
#include <type_traits>
template<typename T1, typename T2>
std::common_type<T1, T2>::type max(T1 a, T2 b) {
    return b < a ? a : b;
}
// C++ 14 이상
#include <type_traits>
template<typename T1, typename T2>
std::common_type_t<T1, T2> max(T1 a, T2 b) {
    return b < a ? a : b;
}
```

## 기본 템플릿 인자
템플릿 파라미터를 위해 기본 인자를 정의할 수 있다. 앞서 보았던 반환형 연역 코드는 다음과 같이 변경할 수 있다.
``` c++
#include <type_traits>

// C++ 14이상
template<typename T1, typename T2,
    typename TR = std::decay_t<decltype(true ? T1() : T2())>>
TR max(T1 a, T2 b) {
    return b < a ? a : b;
}

// C++ 11
template<typename T1, typename T2,
    typename TR = std::decay<decltype(true ? T1() : T2())>::type()>
TR max(T1 a, T2 b) {
    return b < a ? a : b;
}
```
위 코드에서 중요한 점은, `TR`의 기본 타입이 `a`, `b`가 선언되기 전에 결정되어야 한다는 것이다. 
그렇기에 `T1`과 `T2`에 대한 기본 생성자를 호출할 수 있어야 한다.    
레퍼런스가 반환되지 않도록, `decay`를 사용해 준다.

다음과 같이 `std::common_type<>`을 활용할 수도 있다.
``` c++
#include <type_traits>
template<typename T1, typename T2,
    typename TR = std::common_type_t<T1, T2>>
TR max(T1 a, T2 b) {
    return b < a ? a : b;
} 
```
위 코드의 경우 `TR`의 타입이 `T1`, `T2`에 따라 기본값으로 결정된다. 
``` c++
auto a = max(4, 7.2);
```
물론 템플릿 파라미터에 대한 기본값일뿐, 명시적으로 다른 타입을 사용할 수 있다.
``` c++
auto a = max<double, int, double>(7.2, 4);
```

기본 템플릿 파라미터는 일반적인 함수의 기본 인자와 달리, 기본값이 없는 파라미터가 뒤에 와도 상관없다.
``` c++
template<typename TR=long, typename T1, typename T2>
TR max(T1 a, T2 b) {
    return b < a ? a : b;
}

auto a = max(1, 2);     // return long (default)
auto b = max<int>(4, 42);   // return int 
```

## 함수 템플릿 오버로딩 
일반 함수처럼 함수 템플릿도 오버로딩할 수 있다. 
``` c++
int max(int a, int b) {
    return b < a ? a : b;
}

template<typename T>
T max(T a, T b) {
    return b < a ? a : b;
}

max(7, 42);     // max(int, int) 호출
max(7.0, 42.0); // max<double> 호출
max('a', 42.0); // max(int, int) 호출
```

위 코드와 같이 일반 함수와 함수 템플릿은 서로 오버로딩 될 수 있다. 모든 요소가 동일할 경우, 일반 함수를 우선적으로 호출한다. 

`max(7, 42);`는 템플릿을 통해 `max<int>(7, 42);` 로 연역될 수 있으나 이미 일반 함수 `max(int, int)`가 존재하므로 함수 템플릿이 아닌, 일반 함수를 호출한다. 

`max('a', 42.0);`는 두 인자의 타입이 다르기 때문에 타입 연역이 불가능하다. 그러므로 일반 함수 `max(int, int);`가 호출된다.  



## 마치며
힘들다... 이게 이렇게 길어질 줄 몰랐다. 템플릿의 가장 기초적인 부분을 정리했을 뿐인데, 이렇게 힘이 빠질 줄 몰랐다. 앞으로는 좀 더 간단하게 정말 핵심만 정리해야겠다.