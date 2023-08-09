---
title: '[C++ Template] 11. 제네릭 라이브러리'
date: 2023-08-10 00:54:00 +/0900
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

### 멤버 함수
멤버 함수도 염연히 호출 가능한 실체이다. 하지만 위와같은 방식을 통해 구현할 경우 일반적인 형태로 멤버함수를 호출하는것은 상당히 힘들다. 

c++17에서 추가된 유틸리티인 `std::invoke()`를 활용하면 멤버 함수 호출도 일반 함수 호출 문법에 맞출 수 있다. 

```c++
template<typename Iter, typename Callable, typename... Args>
void for_each(Iter current, Iter end, Callable op, Args const&... args) {
    while(current != end) {
        std::invoke(op, args..., *current);
        ++current;
    }
}
```
std::invoke는 기본적으로 호출 가능한 객체가 멤버 함수에 대한 포인터일 경우, 첫 번째 인자를 `this` 객체로 사용한다. 다음 코드를 보자
```c++
class MyClass {
public:
    void func(int i) const {
        std::cout << i << '\n';
    }
};


// ...
std::vector<int> nums = {1, 2, 3, 4, 5};

MyClass obj;
for_each(nums.begin(), nums.end(), &MyClass::func, obj);
```

## 표준 라이브러리 유틸리티

### 타입 트레잇
사실 앞선 포스팅에서 종종 다룬적이 있다. 표준 라이브러리에서 제공하는 타입 트레잇(trait, 혹은 특질)을 사용하면 컴파일 시간에 타입을 평가하고 수정할 수 있다. 다음 코드를 보자
```c++
#include <type_traits>
template<typename T>
class C {

static_assert(!std::is_same_v<std::remove_cv_t<T>,void>,
        "Invalid instantiation of class C for void type");

public:
    template<typename V>
    void f(V&& val) {
        if constexpr(std::is_reference_v<T>) {
            //  V가 레퍼런스인 경우
            ...
        }
        if constexpr(std::is_convertible_v<std::decay_t<V>, T>) {
            //  V가 T로 변환될 수 있는 경우
            ...
        }
        if constexpr(std::has_virtual_destructor_v<V>) {
            // V가 가상 소멸자를 가진 경우 (진짜 별걸 다 제공한다)
            ...
        }
        ...
    }
};
```
이와 같이 타입 트레잇을 활용하면 상당히 유연하게 템플릿을 설계할 수 있다. 

하지만 타입 트레잇은 유의해야하는 사항이 몇가지 존재한다. 
```c++
std::remove_const_t<const int&>;    // == const int&
```
위와같이 코드를 작성할 경우 해당 타입은 `const int&`로 도출된다. 위 코드에서 참조자는 const가 아니기에 (`const int`에 대한 참조이기 때문에) 아무 일도 하지 않는다.

그러므로 const와 참조를 제거할때는 순서가 영향을 미칠 수 있다.
```c++
std::remove_const_t<std::remove_reference_t<const int&>>;   // == int 
// 이와 같은 경우 다음 코드를 사용할 수 있다.
std::decay_t<const int&>;   // == int
```

다음과 같은 경우도 있다. 
```c++
std::add_rvalue_reference_t<int>; // == int&&
std::add_rvalue_reference_t<const int>; // == const int&&
std::add_rvalue_reference_t<const int&>; // == const int&
```
c++ 참조자 붕괴 (reference collapsing) 법칙에 의해 lvalue 참조와 rvalue 참조를 조합하면 그냥 lvalue 참조자 된다. 


### std::addressof()
`std::addressof<>()` 함수 템플릿을 사용하면 객체와 함수의 실제 주소를 반환한다. 심지어 해당 객체가 `&`연산을 오버로딩 하더라도 동작한다. 
```c++
template<typename T>
void f(T&& x) {
    auto p = &x;    // &가 오버로딩되면 오류가 발생할 수 있음
    auto q = std::addressof(x);
    // ...
}
```

### std::declval<>()
`std::declval<>()` 함수 템플릿은 특정 타입의 객체 참조자를 위한 플레이스홀더로 사용할 수 있다. 물론 해당 함수 템플릿은 정의가 없기때문에 호출될 수는 없다. 그러므로 평가하지 않는 피연산자에서만 쓰일 수 있다.

다음 코드를 보자
```c++
#include <utility>

template<typename T1, typename T2, 
    typename RT = std::decay_t<
        decltype(true ? std::declval<T1>():std::declval<T2>())>>
RT max(T1 a, T2 b) {
    return b < a ? a : b;
}
```
`T1`과 `T2`의 기본 생성자를 통해 반환형 `RT`를 연역한다. 이 경우 `T1`과 `T2`의 생성자를 실제로 호출할 수는 없다. 이때 `std::declval`을 통해 해당 값을 평가할 수 있다. 이 방식은 `decltype`이 제공하는 평가되지 않는 문맥 안에서만 가능하다. 

## 임시 값에 대한 전달 참조자
일반적으로 전달 참조자를 통해 다음과 같이 완벽한 전달을 수행할 수 있다.
```c++
template<typename T>
void f(T&& t) {
    g(std::forward<T>(t));
}
```
허나 파라미터가 아닌 데이터를 완벽하게 전달하는 경우가 생길 수도 있다.
```c++
template<typename T>
void foo(T x) {
    f(g(x));
}
```
여기서 `g(x)`로 생성된 임시값에 몇 가지 추가적인 연산을 하는 경우 다음과 같이 작성할 수 있다.
```c++
template<typename T>
void foo(T x) {
    auto&& val = g(x);
    // ...
    f(std::forward<decltype(val)>(val));
}
```

## 평가 지연
템플릿을 구현할 때 종종 불완전한 형식을 처리하는 경우가 더러 생긴다. 
다음 코드를 보자
```c++
template<typename T>
class Cont {
private:
    T* elems;
public:
    // ...

};
```
위 코드는 T에 대한 포인터 타입을 사용하기 떄문에 불완전한 형식에 사용될 수 있다.    
```c++
struct Node {
    int value;
    Cont<Node> next;
};
```

하지만 다음과 같이 코드를 수정할 경우 문제가 될 수 있다.
```c++
template<typename T>
class Cont {
private:
    T* elems;
public:
    // ...
    typename std::conditional<
        std::is_move_constructible<T>::value, 
        T&&, T&>::type
    func();
};
```
위 코드의 경우 `func()`의 반환형을 `T&&`와 `T&`중 하나로 결정하기 위해 `std::conditional`을 사용한다. 하지만 해당 타입 트레잇을 사용하려면 인자가 완전한 형식이어야 한다. 

이 문제를 해결하기 위해 `func()`를 별도의 멤버 템플릿으로 바꿈으로써, 인스턴스화 시점까지 평가를 지연시킬 수 있다.
```c++
template<typename T>
class Cont {
private:
    T* elems;
public:
    // ...
    template<typename D = T>
    typename std::conditional<
        std::is_move_constructible<T>::value, 
        D&&, D&>::type
    func();
};
```
이후 불완전한 타입의 T가 실질적인 타입이 되고 난 후 `func()`가 호출될때까지 해당 템플릿에 대한 평가가 지연된다.

## 마치며
이제 템플릿에 대한 기본적인 내용은 모두 다룬듯 하다. 물론 아직 정리할건 많이 남았다...