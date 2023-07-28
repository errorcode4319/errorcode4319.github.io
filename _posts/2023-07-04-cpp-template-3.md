---
title: '[C++ Template] 2. 클래스 템플릿 2'
date: 2023-07-04 23:25:00 +/0900
categories: [c++, template]
tags: [c, c++, template, cpp-templates-complete-guide]
author: sdk
toc: true
comments: false 
math: true 
mermaid: true 
img_path: /gh/errorcode4319/cdn/images
---

지난 포스팅에 이어서 클래스 템플릿에 대해 마저 정리해볼까 한다.

## 클래스 템플릿 특수화 
클래스 템플릿 역시 함수 템플릿 처럼 특수화가 가능하다. 틀래스 템플릿을 특수화 시키는 방법은 다음과 같다.
```c++
template<>
class Stack<std::string> {
    // ...
};
```
이때 클래스 템플릿을 특수화 하려면 모든 멤버 함수를 특수화해야 한다.

클래스 템플릿 특수화 시 모든 멤버 함수의 정의는 일반 멤버 함수처럼 정의되어야 하며, 타입 파라미터(`T`) 대신 특수화된 타입을 사용해야 한다.
```c++
void Stack<std::string>::push(const std::string& e) {
    // ...
}
```

## 클래스 템플릿 부분 특수화
클래스 템플릿은 부분적으로 특수화할 수 있다. 특정 환경에서만 필요한 구현을 명시할 수 있지만, 일부 템플릿 파라미터는 여전히 사용자가 지정해야만 한다. 

다음은 포인터 타입을 위해 `Stack<>` 클래스를 부분 특수화한 코드다.
```c++
template<typename T>
class Stack<T*> {
    // ...
}
```

위 코드는 타입이 T로 파라미터화되어 있기는 하지만, 포인터를 위해 특수화된 클래스 템플릿이다. 

여러 템플릿 파라미터 사이의 관계를 특수화 시킬수도 있다. 
```c++
template<typename T1, typename T2>
class MyClass {
    // ...
};
```
위와 같은 클래스 템플릿이 있을 경우 다음과 같이 부분 특수화를 할 수 있다.
```c++
// 두 템플릿 파라미터의 타입이 같은 경우
template<typename T>
class MyClass<T, T> {
    // ...
}

// 두 번째 파라미터 타입이 int형인 경우
template<typename T>
class MyClass<T, int> {
    // ...
};

// 두 템플릿 파라미터의 타입이 모두 포인터형인 경우
template<typename T1, typename T2> 
class MyClass<T1*, T2*> {
    // ...
};
```

이때 주의해야할 점은 부분 특수화시 다음과 같은 경우 선언이 모호해 질 수 있다는 점이다.
```c++
MyClass<int, int> m;    // Error: MyClass<T, T>, MyClass<T, int> 둘다 일치
MyClass<int*, int*> m;    // Error: MyClass<T, T>, MyClass<T1*, T2*> 둘다 일치
```

## 기본 클래스 템플릿 인자
클래스 템플릿에서는 템플릿 파라미터의 기본값을 지정할 수 있다. 
다음과 같이 `Stack<>`에서 두 번째 템플릿 파라미터로 데이터를 관리할 컨테이너를 정의하되 `std::vector<>`를 기본값으로 지정할 수 있다.
```c++
template<typename T, typename Cont = std::vector<T>>
class Stack{

    // ...

private:
    Cont elems;
};


Stack<int>  int_stack;  // Int형 스택


// Double형 스택, 데이터를 deqeu으로 관리한다.
Stack<double, std::deque<double>> double_stack; 
```

## 타입 별칭
타입에 새로운 이름을 부여하여 클래스 템플릿을 보다 간편하게 사용할 수 있다.
```c++
typedef Stack<int> IntStack;    
// or 
using IntStack = Stack<int>;    // C++ 11 이상

void foo(const IntStack& s);

IntStack    istack[10];
```

`using`키워드는 C++11부터 지원하는 키워드로, `typedef`와 같이 타입에 대한 새로운 이름을 부여한다. 하지만 `using` 사용시 아래와 같이 별칭 템플릿(alias template)을 사용할 수 있다.
```c++
template<typename T>
using DequeStack = Stack<T, std::deque<T>>;
```

별칭 템플릿은 다음과 같이 활용할 수 있다.
```c++
struct MyType {
    using iterator = ...;
};

template<typename T>
using MyTypeIterator = typename MyType<T>::iterator;


MyTypeIterator<int> pos;
```

c++14부터 타입 트레잇(표준 라이브러리) 내에 모든 타입에 대해 다음과 같은 별칭을 제공한다.
```c++
std::add_const_t<T>     // c++14 이상

typename std::add_const<T>::type    // c++11

// 표준 라이브러리에는 이런식으로 정의되어 있음
namespace std {
    template<typename T> using add_const_t = typename add_const<T>::type;
}
```

## 클래스 템플릿 인자 연역
c++17 이전에는 클래스 템플릿을 사용할 때 모든 템플릿 파라미터 타입을 명시해야 했다.(기본값이 있는 경우 제외). c++17 부터는 템플릿 인자를 명시적으로 표시할 필요가 없어졌다. 물론 생성자를 통해 모든 템플릿 파라미터를 연역할 수 있는 경우에만 해당된다.

```c++
Stack<int>  istack1;
Stack<int>  istack2 = istack1;  
Stack istack3 = istack1;    // c++17 이상
```

다음과 같이 하나의 요소로 초기화된 스택을 제공한다고 하자.
```c++
template<typename T>
class Stack{
private:
    std::vector<T> elems;

public:
    Stack() = default;
    Stack(const T& e) : elems({e}) {}
};

Stack int_stack = 0;    // c++17 이상, Stack<int>으로 연역됨
```
스택을 정수형 값 0으로 초기화하면 템플릿 파라미터 T를 int로 연역할 수 있으므로 Stack<int>가 인스턴스화 된다.

### 문자열 값과 템플릿 인자 연역
원칙적으로 문자열 값으로도 해당 클래스를 초기화할 수 있다.
```c++
Stack string_stack = "bottom";  // Stack<const char[7]>
```
일반적으로 템플릿 형식 T의 인자를 레퍼런스 형태로 전달하면 파라미터에 타입 소실(decay)이 일어나지 않는다. (타입 소실을 통해 원시 배열을 원시 포인터 형으로 바꾸는 매커니즘이 수행된다.)

하지만 위 코드는 T가 const char*가 아닌 const char[7]로 연역하게 되므로, 크기가 다른 문자열은 해당 스택에 저장할 수 없다. 

그로므로 이를 해결하기 위해서는 생성자를 값으로 받아야 한다.
```c++
template<typename T>
class Stack{
private:
    std::vector<T> elems;

public:
    Stack() = default;
    Stack(T e) : elems({std::move(e)}) {}
};

Stack string_stack = "bottom";  // Stack<const char*>
```

### 연역 가이드
컨테이너 내에서 원시 포인터를 다루는 것은 좋지 않다. (여러모로) 이때 다음과 같이 연역 가이드 (deduction guide)를 통해 문자열 리터럴 혹은 C 문자열이 전달되면 std::string으로 인스턴스화하도록 정의할 수 있다.

```c++
template<typename T>
class Stack{
    // ...
    Stack(const T& e) : elems({e}) {}

};

Stack(const char*) -> Stack<std::string>;
```

이후 다음과 같이 선언하면 `Stack<std::string>`이 인스턴스화된다.
```c++
Stack string_stack{"bottom"};   // Stack<std::string>

Stack string_stack = "bottom"   // Stack<std::string>
```

하지만 C++ 문법상 std::string을 기대하는 생성자에 문자열 리터럴을 통한 복사 생성(=)을 수행할 수가 없다... 그러므로 이 이 스택은 위와 같은 방법으로 초기화되어야 한다. 


## 템플릿화된 집합 
집합(aggregate) 클래스도 템플릿이 될 수 있다. 다음 예를 살펴보자.
```c++
template<typename T>
struct ValueWithComment {
    T value;
    std::string comment;
};

ValueWithComment<int> vc;
vc.value = 42;
vc.comment = "initial value";
```

또한 집합 클래스 템플릿에 대해서도 연역 가이드를 정의할 수 있다. (c++17이상)
```c++
ValueWithComment(const char*, const char*) -> ValueWithComment<std::string>;

ValueWithComment vc2 = {"hello", "initial value"};
```
만일 연역 가이드가 없다면 연역을 수행할 생성자가 없어서 위와 같은 초기화가 불가능하다. 