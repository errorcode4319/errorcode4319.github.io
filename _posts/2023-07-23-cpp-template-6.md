---
title: '[C++ Template] 5. 까다로운 기초 지식'
date: 2023-07-23 20:50:00 +/0900
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

이번 포스팅에서는 보다 기본적이면서도 까다로운 템플릿 관련 C++ 기초 지식에 대해 다뤄볼까 한다.    
(기초 아닌 기초)

## typename 키워드
`typename` 키워드는 템플릿 내 식별자(identifier)가 타입임을 명시하기 위해 도입되었다.

```c++
template<typename T>
class MyClass {

public:
    ...
    void foo() {
        typename T::SubType* ptr;
    }
};
```

위 코드에서는 `SubType`이 클래스 `T` 내에서 정의된 타입임을 명시하기 위해 `typename`키워드를 사용하였다.
만일 `typename`이 없다면 `SubType`은 타입이 아닌 멤버로 간주될 수도 있다. 가령 위 코드의 경우 `T`의 정적 멤버인 `SubType`과 `ptr`을 곱하는 코드가 될 수도 있다.(일부 `MyClass<>`인스턴스화에 대해서)

일반적으로 템플릿 파라미터의 종속된 이름이 타입일 경우 `typename`키워드를 사용해야 한다. 

## 0 초기화
`int`, `double` 혹은 포인터형과 같은 기본형(`fundamental type`)에는 기본값으로 초기화하는 기본 생성자가 없다. 그래서 지역변수는 초기화되기 전까지 정해지지 않은 어떠한 값을 가진다.

기본값으로 초기화되는 템플릿형 변수가 필요하다면 다음과 같은 간단한 정의로는 내장 형식(`built-in type`)을 초기화할 수 없다는 문제가 생긴다.
```c++
template<typename T>
void foo() {
    T x;
}
```
이와 같은 문제를 해결하기 위해 내장 형식에 대해서 0으로 초기화하는 기본 생성자를 명시적으로 호출할 수 있다.
```c++
template<typename T>
void foo() {
    T x{};
}
```

이러한 방식으로 초기화하는 것을 값 초기화(`value initialization`)라고 하며, 제공된 생성자를 호출하거나 0으로 초기화한다는 뜻이다. 생성자가 `explicit`일 경우에도 잘 동작한다. 

c++ 11 이전에는 초기화를 위해 다음과 같은 코드를 작성해야 했다. (지금도 유효하다)
```c++
T x = T();
```

c++17 이전에는 복사 초기화를 위한 생성자가 `explicit`이 아닐 경우에만 이 방식이 동작하였으나, c++17 부터는 필수적 복사 생략 방식이 생겨 이러한 제약이 사라졌다. 하지만 중괄호(`{}`)를 활용해 초기화를 할 경우, 기본 생성자가 없을 때에만 `initializer_list` 생성자를 사용할 수 있다. 

참고로 기본 인자로 해당 문법을 사용할 수는 없다.
```c++
template<typename T>
void foo(T p{}) {   // Error 

}

template<typename T>
void foo(T p = T{}) {   // OK 

}
```

## this
기본 클래스가 있는 클래스 템플릿에서 기본 클래스로부터 X를 상속받은 경우, X라는 이름이 항상 this->X를 의미하진 않는다. 

```c++
template<typename T>
class Base {
public:
    void bar();
};

template<typename T>
class Derived : Base<T> {
public:
    void foo() {
        bar();  // 오류, 혹은 외부 bar()를 호출 
    }
};
```
위 코드에서 `foo()`안의 `bar` 라는 심볼을 해석할 때 `Base<T>`에서 정의된 `bar()`는 고려하지 않는다. 이는 템플릿에 종속적인 기본 클래스 사용시 해당 심볼을 인스턴스화 이후에 룩업 시키기 때문이다. (이 부분에 대해서는 나중에 다시 다룰 생각이다) 

일단 이러한 문제를 해결하기 위해 `this->`나 `Base<T>::`를 붙여 해당 심볼이 템플릿 파라미터에 종속되도록 하는 것을 추천한다. 
이렇게 되면 템플릿 파라미터에 종속되므로 심볼에 대한 룩업 시점 역시 인스턴스화 이후로 지연시킬 수 있다.

## 원시 배열과 문자열 리터럴 템플릿
원시 배열(raw array)이나 문자열 리터럴을 템플릿으로 전달할 경우 주의할 점이 있다. 앞선 포스팅에서도 관련 내용을 다룬적 있다.

먼저 템플릿 인자를 레퍼런스로 선언할 경우 타입 소실이 발생하지 않는다. 이는 다시 말해 `"hello"`를 전달한다면 해당 타입은 `char const[6]`이 된다. 만일 다른 길이의 원시 배열이나 문자열 리터럴을 전달할 경우 다른 타입으로 간주될 수 있다. 

인자를 값으로 전달할 때에만 타입이 소실되며 배열과 문자열 리터럴은 포인터 타입이 된다. (`char const*`)

하지만 이러한 특성을 활용해 원시 배열 혹은 문자열 리터럴만을 위한 템플릿을 제공할 수도 있다.
```c++
template<typanem T, int N, int M>
bool less(T(&a)[N], T(&b)[M]) {
    for (int i=0;i < N && i < M; i++) {
        if (a[i] < b[i]) return true;
        if (a[i] > b[i]) return false;
    }
    return N < M;
}

// ...
int x[] = {1, 2, 3};
int y[] = {1, 2, 3, 4, 5};
std::cout << less(x, y) << '\n';
```
위 코드를 통해 `less<>`는 `less<int, 3, 5>`로 인스턴스화 된다. 

문자열 리터럴 또한 같은 방식으로 적용시킬 수 있다.
```c++
template<int N, int M>
bool less(const char(&a)[N], const char(&b)[M]) {
    // ...
}
```

크기가 알려지지 않은 배열을 다룰 경우 템플릿을 오버로딩 하거나 특수화 시킬 수 있다. 상황에 따라 필요할 수 있다.
```c++
template<typanem T>
struct MyClass;

template<typename T, std::size_t SZ>    // 크기가 알려진 배열 
struct MyClass<T[SZ]> { /* ... */ }

template<typename T, std::size_t SZ>    // 크기가 알려진 배열에 대한 참조 
struct MyClass<T(&)[SZ]> { /* ... */ }

template<typename T>    // 크기가 알려지지 않은 배열 
struct MyClass<T[]> { /* ... */ }

template<typename T>    // 크기가 알려지지 않은 배열에 대한 참조
struct MyClass<T(&)[]> { /* ... */ }

template<typename T>    // 포인터
struct MyClass<T*> { /* ... */ }
```

배열로 선언된 파라미터는 언어 규칙에 따라 실제로는 포인터형임을 잊지 말자. 또한 크기가 알려지지 않은 배열에 대한 템플릿은 다음과 같이 불완전한 형식에도 사용할 수 있다.
```c++
extern int i[];
```


## 멤버 템플릿 
클래스 멤버도 템플릿이 될 수 있다. (사실 어떻게 보면 당연한 얘기다)

다음 예시를 보자. 템플릿을 기반으로 스택 자료구조를 구현한 `Stack<>` 클래스가 있다.

```c++

template<typename T>
class Stack {
private:
    std::deque<T> elems;
public:
    void push(const T&);
    void pop();
    const T& top() const;
// ...

};

Stack<int>  int_stack1, int_stack2;
Stack<float> float_stack;
```
이때 해당 `Stack<>` 클래스 인스턴스에 대해 대입 연산자를 사용하려면 양측이 같은 타입이어야 한다. 
```c++
int_stack1 = int_stack2;    // OK
int_stack1 = float_stack;   // 에러
```

이때 암묵적인 타입 변환을 통해서라도 다른 타입간의 대입 연산을 구현하고자 할 경우 다음과 같이 클래스를 수정할 수 있다.
```c++
template<typanem T>
class Stack {

// ...
    template<typanem T2>
    Stack& operator= (const Stack<T2>&);
};

template<typename T>
template<typename T2> 
Stack<T>& Stack<T>::operator= (const Stack<T2>& op2) {
    // ...
}
```
멤버 템플릿을 정의할 경우 템플릿 파라미터 T를 사용하는 템플릿 안에 템플릿 파라미터 T2를 쓰는 내부 템플릿이 정의된다.

이때 `op2`는 엄연히 다른 클래스 타입이므로 모든 멤버에 접근할 수 없다. 이를 해결하기 위해 다른 `Stack<>` 인스턴스화 모두를 프렌드로 선언할 수 있다.
```c++
template<typanem T>
class Stack {

// ...
    template<typanem T2>
    Stack& operator= (const Stack<T2>&);
    template<typename> friend class Stack;
};
```
앞선 포스팅에서도 설명한 바 있으나, 템플릿 파라미터의 이름이 사용되지 않는 경우 해당 이름을 생략할 수 있다.
```c++
template<typename> friend class Stack;
```

### 멤버 함수 템플릿 특수화
멤버 함수 템플릿 역시 특수화할 수 있다.
```c++
class BoolString {

private:
    std::string value;

public:
    BoolString (const std::string& s): value(s) {}

    template<typename T = std::string>
    T get() const {
        return value;
    }
};
```
위와 같은 클래스 템플릿이 있을 경우 다음과 같이 `get()`메서드를 특수화 시킬 수 있다.
```c++
template<>
inline bool BoolString::get<bool>() const {
    return value == "true";
}
```
특수화를 선언할 수도 없고 할 필요도 없다. 전체 특수화이고 헤더파일에 있기 때문에 다른 컴파일 단위에 이 정의가 포함될 경우 오류가 발생할 수 있다. 그러므로 `inline`으로 선언해야 한다. 

## 변수 템플릿 
C++14에서는 변수 템플릿(variable template)을 만들 수 있다.
```c++
template<typename T>
constexpr T pi{3.14159265355897932385};

// 둘은 엄연히 다른 변수이다. 
std::cout << pi<double> << '\n';
std::cout << pi<float> << '\n';
```
위 코드를 쓸 경우 `pi<>`가 정의된 영역에서 서로 다른 두 변수를 만들 수 있다.

다른 컴파일 단위에 사용되는 변수 템플릿을 선언할 수도 있다.
```c++
// header.hpp
template<typename T> T val{};
```
```c++
// main.cpp
#include "header.hpp"

int main() {
    val<long> = 42;
    print();
}
```
```c++
// print.cpp
#include "header.hpp"

void print() {
    std::cout << val<long> << '\n'; // 42가 출력된다
}
```

변수 템플릿을 타입이 아닌 파라미터로도 파라미터화할 수 있다.
```c++
template<auto N>
constexpr decltype(N) dval = N;

// ...
std::cout << dval<'C'> << '\n'; // 'C'
```

### 데이터 멤버를 위한 변수 템플릿
다음은 변수 템플릿을 유용하게 사용하는 예시이다.
다음 클래스 템플릿이 정의되어있다고 가정한다.
```c++
template<typanem T>
class MyClass {
public:
    static constexpr int max = 1000;
};

auto i = MyClass<std::string>::max;
```

그러면 `MyClass<>`의 여러 가지 특수화 버전들에 따라 각기 다른 값을 정의할 수 있으며, 다음과 같은 정의를 할 수 있다.
```c++
template<typename T>
int myMax = MyClass<T>::max;

auto i = myMax<std::string>;
```

c++17부터는 값을 도출 하는 타입 트레잇(type_traits)에 대해 `_v` 접미사를 제공하며, 이때도 변수 템플릿을 제공한다.
```c++
std::is_const<T>::value;    // c++11

std::is_const_v<T>;         // c++17
```
표준 라이브러리내에 다음과 같이 정의되어 있다.
```c++
namespace std{
    template<typename T> constexpr bool is_const_v = is_const<T>::value;
}
```

## 템플릿 템플릿 파라미터 
템플릿 파라미터 자체가 클래스 템플릿일 수 있다. ('템플릿 템플릿 파라미터'는 오타가 아니다)

다음 예시를 보자
```c++
template<typename T, typename Cont>
class Stack {

private:
    Cont elems;
// ...

};

Stack<int, std::vector<int>> vec_stack;
```
위 예시를 보면 데이터를 저장할 컨테이너의 타입을 명시할 때, 해당 컨테이너에 저장할 요소의 타입을 추가로 명시해야 한다. (즉 요소의 형식을 두 번씩 명시하는 셈) 

이때 템플릿 템플릿 파라미터를 사용하면 요소의 형식에 대해 다시 명시하지 않고도 컨테이너 타입을 명시할 수 있다.
```c++
template<typename T,
    template<typename Elem> class Cont = std::deque>
class Stack {
private:
    Cont<T> elems;
};
```
참고로 c++17 이전 버전에서는 템플릿 템플릿 파라미터 사용 시 `typename`키워드 대신 `class`키워드를 사용해야 한다. 또한 c++17 이전 버전에서는 위 코드를 사용할 경우 기본값 `std::deque`에 한해 에러가 발생한다. (해당 내용은 밑에서 다룬다) 

### 템플릿 템플릿 파라미터 일치
c++17 이전 버전에서는 위 코드를 사용할 경우 `std::deque`가 Cont에 대응될 수 없다는 오류 메시지가 발생할 수 있다. 이는 템플릿 템플릿 파라미터가 자신이 치환할 템플릿 템플릿 파라미터의 파라미터들과 정확히 일치해야 하기 때문에 발생하는 문제이다.

c++17 이전 버전에서는 표준 라이브러리의 `std::deque` 템플릿이 파라미터를 하나 이상 가지기 때문에 발생한다. 물론 두 번째 파라미터에 기본값이 있긴 하지만, C++17 이전에는 파라미터 일치 여부를 검사할 때 기본값을 고려하지 않는다.

이를 우회하는 방법은 다음과 같이 작성해 `Cont` 파라미터가 두 개의 템플릿 파라미터를 갖는 컨테이너와 일치하도록 만들면 된다.
```c++
template<typaname T,
    template<typename Elem, typename Alloc = std::allocator<Elem>>>
    class Cont = std::deque>
class Stack {
private:
    Cont<T> elems;
};
```
이때 `Alloc`역시 사용되지 않으며, 생략 가능하다. (하지만 문서화 차원에선 남겨두는 것이 좋다.)

또한 앞서 다른 템플릿 타입에 대한 대입 연산자를 구현할 때 보았듯, 모든 `Stack<>` 인스턴스화를 프렌드로 선언할 경우 다음과 같이 선언하면 된다.
```c++
template<typaname T,
    template<typename Elem, typename Alloc = std::allocator<Elem>>>
    class Cont = std::deque>
class Stack {
// ...

    template<typename, template<typename, typename>class>
    friend class Stack;
};

```
참고로 위 구현의 경우 모든 표준 컨테이너 템플릿을 사용할 수 있는 것은 아니며, 파라미터 구성을 고려해 적절히 사용(혹은 구현)해야 한다.

## 마치며
템플릿은 상당히 강력한 요소이지만 그만큼 기본적인 사항을 숙지하지 않으면 끝없는 컴파일 에러의 향연에서 허우적 거리기 십상이다. (필자의 경험담, 결국 고생은 본인의 몫이다...)     

그러니 불필요한 삽질을 피하기 위해서라도 언어의 특성과 기본적인 문법 사항은 숙지할 필요가 있다고 본다.     