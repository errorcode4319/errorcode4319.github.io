---
title: '[C++ Template] 8. 컴파일 과정 프로그래밍'
date: 2023-08-02 23:00:00 +/0900
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

이번 포스팅에서는 컴파일 과정 프로그래밍에 대해 다뤄볼까 한다. 

## 메타프로그래밍
템플릿은 기본적으로 컴파일 과정에서 인스턴스화된다. 그러므로 템플릿의 특성을 인스턴스 과정과 결합시키면 c++ 언어 자체적으로 '프로그램을 계산' 할 수 있다. 

다음 코드를 보자, 템플릿을 활용해 컴파일 시점에 값에 대한 소수 판별 여부를 구할 수 있다. 
```c++
template<unsigned p, unsigned d>
struct DoIsPrime {
    static constexpr bool value = (p%d != 0) && DoIsPrime<p,d-1>::value;
};

template<unsigned p>
struct DoIsPrime<p, 2> {
    static constexpr bool value = (p%2 != 0);
};

template<unsigned p>
struct IsPrime {
    static constexpr bool value = DoIsPrime<p,p/2>::value;
}

template<>
struct IsPrime<0> { static constexpr bool value = false; }
template<>
struct IsPrime<1> { static constexpr bool value = false; }
template<>
struct IsPrime<2> { static constexpr bool value = true; }
template<>
struct IsPrime<3> { static constexpr bool value = true; }
```
이때 다음과 같은 코드를 사용한다면 어떻게 될까?
```c++
IsPrime<9>::value;  // == false 
```
컴파일 과정을 거치고 나면, 해당 값은 false로 확장된다. 확장 과정은 다음과 같다.
```c++
IsPrime<9>::value;

// 다음으로 확장
DoIsPrime<9,9/2>::value;

// 다음으로 확장됨
(9%4!= 0) && DoIsPrime<9, 3>::value;

// 다음으로 확장됨
(9%4!= 0) && (9%3!= 0) && DoIsPrime<9, 2>::value;

// 다음으로 확장됨
(9%4!= 0) && (9%3!= 0) && (9%2!=0); // struct DoIsPrime<p, 2> 부분 특수화됨

// 결과, IsPrime<9>::value == false
false
```
이와 같은 확장 과정이 컴파일 시점에 계산된다.

>어윈 운러(Erwin Unruh)라는 사람이 처음으로 이러한 특성(템플릿 기반 컴파일 과정 프로그래밍)을 발견했다고 한다.
{:.prompt-tip}

## constexpr 
앞서 본 컴파일 과정 소수 판별 로직은 너무 코드가 다소 보기 불편하다(사람에 따라 다르겠지만)   

c++11에 추가된 `constexpr`를 사용하면 컴파일 과정 프로그래밍을 보다 간편하게 할 수 있다. 해당 기능 (`constexpr` 함수)을 온전히 사용하려면 모든 계산 과정이 컴파일 과정에 가능하며 유효해야 한다. 물론 힙 할당 혹은 예외 발생(throw)과 같은 작업은 지원되지 않는다.

앞서 본 컴파일 과정 소수 판별 로직을 다음과 같이 구현할 수 있다.
```c++
// c++11
constexpr bool
doIsPrime(unsigned p, unsigned d) {
    return p != 2 ? (p % d != 0) && doIsPrime(p, d-1)
                : (p%2 != 0);
}

constexpr bool isPrime(unsigned p) {
    return p < 4 ? (p < 2>)     // 예외처리
            : doIsPrime(p, p/2);
}
```
코드를 하나하나 뜯어 보면, 앞서 보았던 템플릿 기반 소수 판별 로직과 동일하다. 

c++11에서는 `constexpr`에 제약사항이 다소 많았는데, 그중 한가지가 `constexpr`함수는 단일 `return`문으로만 이루어져야 한다는 것이다. 그렇기에 위 코드는 단일 `return`구문과 삼항 연산자를 통해 재귀적으로 로직을 수행한다.

c++14부터는 여러 제약사항이 사라지고, 일반적인 C++코드들을 `constepxr`함수에서 사용할 수 있게 되었다.
```c++
// c++14, 코드가 훨씬 보기 좋아졌다 
constexpr bool isPrime(unsigned p) {
    for (unsigned d = 2, d <= p / 2; d++) {
        if (p % d == 0)
            return false;
    }
    return p > 1;
}
```
이후 다음과 같이 일반 함수 호출과 동일하게 사용 가능하다.
```c++
isPrime(9); // == false
```
이때 중요한 점은 `constexpr`가 붙는다고 해서 무조건 모든 로직을 다 컴파일 과정에 계산하지는 않는다는 것이다. 컴파일 과정에 계산을 시도하며, 계산할 수 없다면(최종적으로 상수 값이 생성되어야 한다) 오류를 발생시킨다. 그 외 상황에서는 컴파일 과정에 계산을 하거나, 런타임 시간에 호출하는 식으로 남겨둔다.

다음 코드를 보자
```c++
constexpr bool b1 = isPrime(9); // 컴파일 과정에 계산

int x;
isPrime(x);     // 런타임 시간에 계산
```
아무리 `constexpr`를 붙이더라도, 런타임 시간에 값이 변경될 수 있는 변수 `x`를 사용할 경우 이에대한 결과값을 컴파일 시간에 계산할 수는 없다(무슨 값이 들어올 줄 알고). 이처럼 컴파일 과정에 계산을 수행하고 싶을 경우, 계산에 필요한 모든 요소가 갖춰진 상태에서만 가능하다.   
>미리 계산할 수 있으면 미리 계산해 두고, 미리 계산할 수 없으면 실행중에 계산한다 
{:.prompt-tip}

## SFINAE 
c++에서 다양한 인자의 타입에 따라 함수를 오버로딩하는 경우가 많다. 함수 오버로딩시 컴파일러는  여러 호출 후보를 나열해 두고, 호출 인자를 평가하여 가장 적합한 후보를 선택한다.

후보중 함수 템플릿이 있으면 컴파일러는 먼저 함수 템플릿을 호출 인자에 맞게 치환시킨 후, 해당 함수가 오버로딩에 적합한지 평가한다. 이때 치환 과정에서 논리적으로 말이 안되는 이상한 함수가 생성될 수도 있다. 그러면 무의미한 치환에서 오류를 발생시키는 대신 해당 함수 템플릿을 무시한다.
    
말 그대로 치환 실패는 오류가 아닌 단지 오버로딩에 적합하지 않은 후보를 걸러내는 과정일 뿐이며, 이와 같은 법칙을 SFINAE라고 부른다. (정말 이름 그대로다)
> SFINAE: Substitution failure is not an error (치환 실패는 오류가 아니다)
{:.prompt-tip}     

참고로 앞서 설명한 치환 과정은 필요에 의해 실행되는 인스턴스화 과정과 다르다. 필요하지 않을 수 있는(잠재적인) 인스턴스화까지도 치환하며, 이후 컴파일러가 해당 결과물의 실제 필요 여부를 다시 평가한다.    

다음 코드를 보자.
```c++
template<typename T, unsigned N>
std::size_t len(T(&)[N]) {
    return N;
}


template<typename T>
typename T::size_type len(T const& t) {
    return t.size();
}
```
이후 해당 함수 템플릿을 사용할 경우 다음 코드는 모두 원시 배열을 위한 첫번째 `len()` 함수 템플릿을 호출한다.
```c++
int a[10];
std::cout << len(a);        
std::cout << len("temp");
```

함수 서명(signature)상으로는 사실 `int[10]`, `char const[4]` 둘 다 `len(T const& t)`으로 연역될 수 있다. 하지만 두 번째 `len()`으로 치환할 경우 반환형 `typename T::size_type`에 문제가 생긴다. 그러므로 위 코드상에선 두 번째 함수 템플릿은 무시한다.(에러는 아니다, 단지 아다리가 맞지 않을뿐) 

반면 `std::vector<>`를 전달할 경우 두 번째 함수 템플릿만 일치한다.
```c++
std::vector<int> v;
std::cout << len(v);
```

그렇다면 `std::allocator<>`을 사용한다면 어떨까? 
```c++
std::allocator<int> x;
std::cout << len(x);
```
해당 템플릿은 `size_type`을 멤버로 가지고 있다. 그러므로 컴파일러는 반환형과 인자가 모두 충족되는 두 번째 `len()` 함수 템플릿이 일치한다고 판단한다.    

하지만 해당 클래스 템플릿은 `size()`멤버 함수가 없으므로 컴파일 과정에선 `size()`를 호출할 수 없다고 컴파일 오류를 낸다. 즉, 두 번째 함수 템플릿이 무시되지 않은 것이다.

### decltype을 갖는 SFINAE 표현식
어떠한 제약 사항이 있을 때, 해당 템플릿 코드가 유효하지 않게 만들어 결과적으로 무시되도록 SFINAE 메커니즘을 적용시킬 수 있다. (이를 'SFINAE 퇴출' 시킨다고도 표현한다) 

앞서 본 상황과 같이 `std::allocator<>`가 두 번째 `len()` 함수 템플릿을 무시하도록 하고자 할 경우 다음과 방법을 사용할 수 있다.

```c++
template<typanem T>
auto len(T const& t) -> decltype((void)(t.size()), T::size_type()) 
{
    return t.size();
}
```
위 코드를 보면 반환형을 `(void)(t.size()), T::size_type()` 표현식을 통해 연역한다. decltype 내에서 쉼표를 통해 표현식을 구분할 경우, 결과적으로 마지막 표현식을 통해 타입을 연역한다. (사용자 정의 쉼표 연산자가 있을 경우를 대비해, 마지막 표현식을 제외한 앞선 표현식의 결과값은 void형으로 변환시켜 준다.)   

결과적으로 `std::allocator<>`는 `size()`멤버가 없으므로 위 `len()` 함수 템플릿 치환시 유효하지 않은 코드가 생성된다. 그러므로 `len()`호출 시 해당 함수 템플릿은 무시된다.


## 컴파일 과정 if 
부분 특수화, SFINAE와 std::enable_if 등을 사용해 템플릿의 활성화 여부를 설계할 수 있다.    

c++17에서는 전체 템플릿 단위가 아닌 조건에 따른 특정 명령문의 활성 여부를 설계하기 위해 컴파일 과정 if문이 추가되었다. 다음 코드를 보자

```c++
template<typename T, typename... Types>
void print(T const& first_arg, Types const&... args) {
    std::cout << first_arg << '\n';
    if constexpr(sizeof...(args) > 0) {
        print(args...);
    }
}
```
위 코드는 가변 인자 템플릿을 통해 여러 값들을 출력시켜 주는 함수 템플릿 코드이다. 이때 뒤따라오는 가변인자의 개수가 0개인 경우에 대한 예외 처리가 필요한데, 이전 [4. 가변인자 템플릿](https://errorcode4319.github.io/posts/cpp-template-4/) 포스팅에서는 남은 인자가 없는 상황에 대한 예외 처리를 함수 오버로딩을 통해 구현했었다.  
```c++
#include <iostream>

void print() {} 

template<typename T, typename... Types> 
void print(T first_arg, Types... args) {
    std::cout << first_arg << ' ';
    print(args...)  // args...가 없을 경우, print()가 호출된다
}
```

이때 다음 코드가 왜 동작하지 않는지에 대해서 설명했었는데
```c++
// 4. 가변인자 템플릿 포스팅에서 다룬 샘플 코드, 컴파일 오류가 발생한다
template<typename T, typename... Types>
void print(T first_arg, Types... args) {
    std::cout << first_arg << '\n';
    // 해당 조건문은 런타임 시점에 평가된다
    // 그로므로 값이 false라고 할지라도 일단 print(args...)에 대한 인스턴스화는 수행된다 
    if (sizeof...(args) > 0) {  
        print(args...)
    }
}
```
여기에서 `if(...)`대신 `if constexpr(...)`를 사용하게 되면, 해당 시점에 대한 `print(args...)`구문 역시 컴파일 과정에서 비활성화되므로 인스턴스화되지 않는다.

참고로 `if constexpr(...)` 구문은 템플릿이 아닌 일반 코드상에서도 사용 가능하다. 물론 컴파일 시점에 계산 가능한 표현식이 필요하다. 

## 마무리
비록 컴파일 과정 프로그래밍은 쉬운 작업은 아니지만, 기본적인 원칙만 지키면 매우 유용하게 활용할 수 있다. c++14, c++17을 거쳐 컴파일 과정에 대한 프로그래밍이 한결 수월해지기도 했다.   

물론 좀만 실수해도 컴파일 오류 지옥에 빠지긴 십상이니, 최대한 중요한 기본 원칙들을 잘 숙지해 두자. 