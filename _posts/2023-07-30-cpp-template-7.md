---
title: '[C++ Template] 6. 이동 의미론과 enable_if<> (+concepts)'
date: 2023-07-30 21:30:00 +/0900
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

이번 포스팅에서는 이동 의미론(move semantics)과 관련된 템플릿 문법과 enable_if를 활용한 조건부 템플릿 활성화를 다룰 예정이다. 

## 완벽한 전달
전달된 인자의 기본 속성을 전달하는 일반 코드를 작성하고자 한다.
- 수정 가능한 상태 (참조)
- 읽기 전용 객체 (상수)
- 이동 가능한 객체 (우측값 참조)

이때 인자를 전달하는 함수 f()를 템플릿 없이 구현할 경우 다음과 같이 작성할 수 있다.
```c++
#include <utility>
#include <iostream>

class X{
    //...
};

void g(X&) { std::cout << "g() for variable\n"; }
void g(const X&) { std::cout << "g() for constant\n"; }
void g(X&&) { std::cout << "g() for movable object\n"; }

// 기본 속성을 g()로 전달한다.
void f(X& val) { g(val);}
void f(const X& val) { g(val);}
void f(X&& val) { g(std::move(val));}   

int main() {
    X v;
    X const c;
    f(v);   // f(X&) -> g(X&)
    f(c);   // f(X const&) -> g(X const&)
    f(X()); // f(X&&) -> g(X&&)
    f(std::move(v)); // f(X&&) -> g(X&&)
}
```
이때 `f(X&& val)`은 `val`이 우측값 참조자로 선언되어 있지만, 해당 변수가 표현식으로 쓰일 때의 값 카테고리(value category)는 비상수 lvalue로 분류된다. 그러므로 `std::move()`를 사용하지 않으면 `g(X&)`를 호출하게 된다.

위 코드에서 `f()`함수를 템플릿화 시킬 경우 다음과 같이 작성해야 한다.
```c++
// OK, 인자에 따라 세 가지 버전의 g()이 호출된다
template<typename T>
void f(T&& val) {  
    g(std::forward<T>(val));
}

// 잘못된 코드, g(X&&)를 호출할 수 없다.
template<typename T>
void f(T val) { 
    g(T);
}
```
>`std::move()`는 인자에 대한 이동을 '촉발'시키는데 반해, `std::forward<>`는 전달받은 인자에 따라 잠재적인 이동을 '전달'시킨다. 
{:.prompt-tip}

이때 템플릿 파라미터 `T`에 대한 `T&&`는 문법적으로는 `X&&`와 동일하나, 이는 우측값 참조자가 아닌 전달 참조자(forwarding reference)이다. 이는 수정할 수 있는 객체나 수정할 수 없는(const) 객체, 혹은 이동 가능한 객체를 나타낼 수 있다(만능이다).     

이때 `T`가 템플릿 파라미터의 진짜 이름이어야 하며, 템플릿 파라미터에 종속되는 것만으로는 충분하지 않다. 예를 들어 템플릿 파라미터 `T`가 있을 경우 다음 선언은 우측값 참조일뿐 전달 참조자가 아니다.
```c++
typename T::iterator&& iter;    // rvalue reference
```

물론 가변 인자 템플릿에서도 완벽한 전달(perfect forwarding)을 수행할 수 있다.

## 특수 멤버 함수 템플릿
멤버 함수 템플릿은 생성자를 포함한 특수 멤버 함수에 쓰일 수 있다. 다음 코드를 보자.

```c++
#include <utility>
#include <string>
#include <iostream>

class Person {

private:
    std::string name;

public:
    // 생성자
    explicit Person(const std::string& n): name(n) {}
    explicit Person(std::string&& n): name(std::move(n)) {}

    // 복사, 이동 생성자 
    Person(const Person& p): name(p.name) {}
    Person(Person&& p): name(std::move(p.name)) {}
};

int main() {
    std::string s = "name";
    Person p1(s);               // Person(const std::string&)
    Person p2("tmp");           // Person(std::string&&) 
    Person p3(p1);              // Person(const Person&)
    Person p4(std::move(p1));   // Person(Person&&)
    return 0;
}
```
여기에서 앞서 설명한 전달 참조자(`T&&`)를 통해 두 개의 문자열 생성자 대신 전달받은 인자를 멤버 `name`의 초기값으로 전달하는 일반 생성자를 만들 수 있다.
```c++
class Person {

private:
    std::string name;

public:
    template<typename STR>
    explicit Person(STR&& n): name(std::forward<STR>(n)) {}

    Person(const Person& p): name(p.name) {}
    Person(Person&& p): name(std::move(p.name)) {}
};
```
하지만 위 코드의 경우 치명적인 오류가 있다. 다음 코드를 보자.
```c++
Person p1("name");  // OK
Person p2(p1);  // 컴파일 에러, 복사생성자 대신 Person(STR&&)를 호출한다.
Person p3(std::move(p1));   // OK
```
c++ 오버로딩 해석 규칙에 따라 비상수 lvalue인 `Person p`에 대해는 복사 생성자보다 전달 참조자를 사용한 생성자에 우선순위가 간다. 
```c++
template<typename STR>
Person(STR&& n);    // 우선순위가 더 높다

Person(const Person& p);
```
`STR`은 `Person&`로 치환하기만 하면 되지만, 복사 생성자를 사용하려면 const로 변환해야하기 때문이다. 
   
이와 같은 상황을 해결하기 위해 다음과 같이 비상수 복사 생성자를 제공할 수도 있지만, 
```c++
Person(Person& p);
```
이렇게 하더라도 파생 클래스의 객체에 대해서는 여전히 멤버 템플릿이 우선순위가 더 높다.   

가장 좋은 방법은 인자가 `Person` 인스턴스일 경우 문제가 되는 멤버 템플릿을 비활성화 시키는 것이다.   

## enable_if<> (c++11)
`std::enable_if<>`는 c++11에서 타입 트레잇에 추가된 템플릿이다. 컴파일 시간에 특정 조건에 따라 함수 템플릿을 활성화(혹은 비활성화) 시킬 수 있도록 해준다.

다음 코드를 보자
```c++
template<typename T>
typename std::enable_if<(sizeof(T)>4)>::type
foo() {
    // ...
}
```
만일 `sizeof(T)`가 4보다 같거나 작을경우 해당 함수 템플릿의 정의는 무시한다. 만일 해당 조건에 부합할 경우 이 함수 템플릿은 다음과 같이 인스턴스화 된다.
```c++
void foo(){
    // ...
}
```

`std::enable_if<>`는 컴파일 시간에 다음과 같은 작업을 수행한다.
- 표현식이 참일 경우 타입 멤버 `type`은 두 번째 템플릿 인자의 타입이 된다.
    - 두 번째 템플릿 인자가 전달되지 않았을 경우 `void`타입이 된다.
- 표현식이 거짓일경우 멤버 `type`은 정의되지 않는다. 
    - **SFINAE**에 의해 `enable_if`표현식을 가진 함수 템플릿이 무시된다.
      
참고로 c++14에서는 타입을 도출하는 모든 타입 트레잇에 대해 `typename`과 `::type`을 생략할 수 있게 되었으며 위 코드는 다음과 같이 바꿀 수 있다.
```c++
template<typename T>
std::enable_if_t<(sizeof(T)>4)>
foo() {
    // ...
}
```

선언 중간에 반환형으로써 `enable_if` 표현식을 사용하는 것은 그다지 보기 좋은 코드는 아니다.   
그래서 보통은 다음과 같이 기본값을 갖는 부가적인 함수 템플릿 인자를 사용한다.

```c++
template<typename T,
    typename = std::enable_if_t<(sizeof(T) > 4)>>
void foo() {
    // ...
}
```
다음과 같이 별칭 템플릿을 사용하면 활성화 조건을 보다 구체적으로 표현할 수 있다
```c++
template<typename T>
using EnableIfSizeGreater4 = std::enable_if_t<(sizeof(T)>4)>;

template<tyupename T, typename = EnableIfSizeGreater4<T>>
void foo() {
    // ...
}
```
### Person(STR&&) 생성자 문제 개선
`enable_if<>`를 통해 앞서 보았던 `Person` 클래스 생성자 오버로딩 문제를 해결할 수 있다.
```c++

class Person {

private:
    std::string name;

public:
    template<typename STR,
        typename = std::enable_if_t<
            std::is_convertible_v<STR, std::string>>>
    explicit Person(STR&& n): name(std::forward<STR>(n)) {}

    Person(const Person& p): name(p.name) {}
    Person(Person&& p): name(std::move(p.name)) {}
};
```
`STR`을 `std::string`으로 변환할 수 있다면 선언 전체가 다음과 같이 확장된다.
```c++
template<typename STR, typename = void>
Person(STR&& n);
```
만일 인자를 `std::string`으로 변환할 수 없을 경우 해당 함수 템플릿을 무시한다. 
```c++
int main() {
    Person p1("name");  // OK
    Person p2(p1);      // OK, Person(STR&&) 무시, 복사 생성자 호출
    Person p3(std::move(p1));   // OK
    return 0;
}
```

마찬가지로 별칭 템플릿을 활용해 해당 `enable_if`문을 보다 명시적으로 변경할 수 있다.
```c++
template<typename T>
using EnableIfString = std::enable_if_t<
    std::is_convertible_v<STR, std::string>>;

template<typename STR,
    typename = EnableIfString<STR>>
explicit Person(STR&& n): name(std::forward<STR>(n)) {}
```

## 특수 멤버 함수 비활성화
일반적으로 사전 정의된 복사/이동 생성자와 할당 연산자는 `enable_if<>`를 사용해 비활성화시킬 수 없다.   
기본적으로 멤버 함수 템플릿은 특수 멤버 함수로 간주하지 않는다. 다음 코드를 보자 
```c++
class C{
public:
    template<typename T>
    C(const T&) {
        std::cout << "Template Copy Constructor\n";
    }
    //...
}

int main() {
    C x;
    C y{x}; // 사전 정의된 복사 생성자를 사용하며, 멤버 템플릿은 사용하지 않음
    return 0;
}
```
이와 같은 경우 사전 정의된 복사 생성자 대신 멤버 템플릿을 사용하고자 할 경우 가전 정의된 복사 생성자가 삭제되었음을 명시하는 방법을 사용할 수 있다.
```c++
class C{
public:
    C(const volatile C&) = delete;  // 사전 정의 복사 생성자
    // 최대한 구체적으로 명시하기 위해 volatile 키워드를 붙여준다 

    template<typename T>
    C(const T&) {
        std::cout << "Template Copy Constructor\n";
    }
    //...
}
```

## concept (c++20)
별칭 템플릿을 사용하더라도 `enable_if<>` 문법은 상당히 가독성이 떨어진다.   

이에 c++20에서 새로 추가된 `concept`를 통해 템플릿 인자에 대한 요구 사항(제약 사항)을 표현할 수 있다. 

앞서 보았던 `Person(STR&&)`을 다음과 같이 수정할 수 있다.
```c++
template<typename STR>
requires std::is_convertible_v<STR, std::string>
Person(STR&& n): name(std::forward<STR>(n)) {}
```

또한 해당 요구 사항을 일반적인 개념(Concepts)으로 명시할 수 있다.
```c++
// 네임스페이스 스코프에서 정의해야 한다. (클래스 내부 X)
template<typename STR>
concept ConvertibleToString = std::is_convertible_v<STR, std::string>;

class Person {

public:
    template<typename STR>
    requires ConvertibleToString<STR>
    Person(STR&& n): name(std::forward<STR>(n)) {}

    // ...
}

```

`requires`구문 대신 다음과 같은 형태로도 사용 가능하다.
```c++
template<ConvertibleToString STR>
Person(STR&& n): name(std::forward<STR>(n)) {}
```

>[Constraints and concepts](https://en.cppreference.com/w/cpp/language/constraints)
{:.prompt-tip}