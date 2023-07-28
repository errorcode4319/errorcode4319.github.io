---
title: '[C++ Template] 4. 가변 인자 템플릿'
date: 2023-07-07 16:30:00 +/0900
categories: [c++, template]
tags: [c, c++, template, cpp-templates-complete-guide]
author: sdk
toc: true
comments: false 
math: true 
mermaid: true 
img_path: /gh/errorcode4319/cdn/images
---

이번 포스팅에서는 가변인자 템플릿(variadic templates)에 대해 다뤄볼까 한다. 
가변인자 템플릿을 활용하면 여러개의 템플릿 인자를 전달할 수 있다. 


## 가변 인자 템플릿
다음 코드를 보자
```c++
#include <iostream>

void print() {}

template<typename T, typename... Types> 
void print(T first_arg, Types... args) {
    std::cout << first_arg << ' ';
    print(args...)
}

int main() {
    print(1, 2.4, "str");
}
```
`print(...)`은 다양한 타입의 값을 인자로 받아 모든 값을 순차적으로 출력시켜주는 함수 템플릿이다.    

위 코드를 보면 첫 번째 인자만 따로 명시해서 그 인자만 출력한 후 나머지 인자들은 재귀적으로 `print()` 함수를 호출한다.
이때 나머지 인자들을 나타내는 `args`는 함수 파라미터 꾸러미(function parameter pack)이다.
```c++
void print(T first_arg, Types... args)
```

이때 템플릿 파라미터 꾸러미(template parameter pack)인 `Types`를 사용한다. 
```c++
template<typename T, typename... Types>
```

재귀 호출을 끝내기 위해서는 함수 템플릿이 아닌 `print()`의 오버로딩 버전이 필요하다. 파라미터 꾸러미가 비었을 때에만 사용된다.
>해당 포스팅에서 파라미터 꾸러미라는 이름은 파라미터 팩으로도 명시한다. 
{:.prompt-tip}  

### print(...) 함수 템플릿 처리 과정
가변인자를 가진 `print()` 함수 템플릿을 재귀적으로 호출할 경우 인스턴스화 되는 과정은 다음과 같다.
```c++
print(1, 2.4, "str");   // 호출
```
```c++
// 첫 호출 
print<int, double, const char*>(1, 2.4, "str");
// 재귀 호출 
print<double, const char*>(2.4, "str");
// 재귀 호출 
print<const char*>("str");
// 재귀 호출 (마지막)
print();
```
마지막에는 남은 파라미터 팩이 없으므로 일반 함수인 `print()`가 호출된다. 

### 또 다른 구현
위 코드를 다음과 같이 변경할 수 있다. 
```c++
#include <iostream>

template<typename T>
void print(T arg) {
    std::cout << arg << '\n';
}

template<typename T, typename... Types>
void print(T first_arg, Types... args) {
    print(first_arg);
    print(args...);
}
```
위 코드를 보면 두 `print()` 함수 템플릿은 뒤따라오는 파라미터 팩의 유무에서 갈린다. 
이때 템플릿 인자가 하나일 경우 위 `print()`함수 템플릿에 우선순위가 간다.   

### sizeof...
c++11 부터는 가변 인자 템플릿에 대한 `sizeof` 연산인 `sizeof...`를 사용할 수 있다. 
해당 연산자를 사용하면 파라미터 팩에 남은 인자의 수를 구할 수 있다. 
```c++
template<typename T, typename... Types>
void print(T first_arg, Types... args) {
    std::cout << sizeof...(Types) << '\n';  // 남은 타입 수 출력
    std::cout << sizeof...(args) << '\n';   // 남은 인자 수 출력 
    // ...
}
```

`sizeof...` 연산을 통해 다음과 같이 코드를 수정한다고 가정해 보자. 재귀를 멈추기 위해 별도로 `print()` 일반 함수를 오버로딩 하지 않기 위해 `sizeof...`로 남은 인자의 수를 검사하는 코드이다.
```c++
template<typename T, typename... Types>
void print(T first_arg, Types... args) {
    std::cout << first_arg << '\n';
    if (sizeof...(args) > 0) {  // 남은 인자가 없을 경우 재귀호출을 종료한다
        print(args...)
    }
}
```
하지만 위 코드는 실제로 동작하지 않는다. 템플릿은 기본적으로 컴파일 시간에 처리되기 때문에 `sizeof...(args)`가 0인 경우라도 해당 시점에 대한 `print(args...)`역시 인스턴스화가 된다. 결국 인자가 없는 경우에 대한 `print()` 함수를 제공하지 않으면 오류가 발생한다. 
>c++17부터는 컴파일 시점에 `if`문을 사용할 수 있다. 해당 문법을 통해 위에서 의도한 바가 동작하게끔 구현할 수 있다. 
이 부분은 나중에 다룰 예정이다.  
{:.prompt-tip}

## 폴드 표현식
c++17부터 파라미터 팩의 모든 인자를 대상으로 하는 이항 연산자를 제공한다. 
다음 예시는 함수에 전달된 인자들의 합을 반환하는 표현식이다.
```c++
template<typename... T>
auto foldSum(T... s) {
    return (... + s);   // ((s1 + s2) + s3)...
}
```
물론 파라미터 팩이 비었다면 표현식도 잘못 만들어진다.

c++17부터 사용가능한 폴드 표현식의 목록은 다음과 같다.
- `( ... op pack )` -> `((( pack1 op pack2 ) op pack3 ) ... op packN )`
- `( pack op ... )` -> `( pack1 op (... ( packN-1 op PackN )))`
- `( init op ... op pack )` -> `((( init op pack1 ) op pack2 ) ... op packN )`
- `( pack op ... op init )` -> `( pack1 op ( ... ( packN op init )))`
대부분의 이항 연산자는 폴드 표현식에 사용할 수 있다. 

`init`을 사용하는 폴드 표현식을 통해 앞서 작성했던 `print()` 함수 템플릿을 더 간단하게 만들 수 있다.
```c++
template<typename... Types>
void print(const Types&... args) {
    (std::cout << ... << args) << '\n';
}
```

## 가변 인자 템플릿 활용
가변 인자 템플릿은 일반적인 라이브러리를 구현할 때 상당히 유용하다. 
c++ 표준 라이브러리상에서 가변 인자 템플릿이 사용되는 경우는 다음과 같다. 

```c++
// 스마트 포인터가 소유한 새 힙 객체의 생성자에 인자를 전달 
auto sp = std::make_shared<std::complex<float>>(4.2, 7.7);

// 쓰레드 인자 전달 
std::thread t(foo, 42, "hello");    // -> foo(42, "hello")

// 새 요소의 생성자에 인자 전달
std::vector<Customer>   v;
v.emplace("Tim", "Jovi", 1962);
```

보통 이와 같은 경우 인자들은 무브 시맨틱을 통한 완벽한 전달(perfect forwarding)이 수행된다. 
```c++
namespace std {

// make_shared 
template<typenmae T, typename... Args> shared_ptr<T>
make_shared(Args&&... args);

// thread 
class thread {
    public:
        template<typename F, typename... args>
        explicit thread(F&& f, Args&&... args);
    // ...
};

// vector
class vector {
    public:
        template<typename... Args> reference emplace_back(Args&&... args);
};

}
```

또한 가변 함수 템플릿 파라미터 역시 일반 파라미터와 동일한 법칙이 적용된다. 
```c++
// 인자가 복사되며 타입이 소실(decay)됨 
template<typename... Args> void foo(Args... args);

// 참조로 전달할 경우 타입이 소실되지 않음
template<typename... Args> void bar(const Args&,,, args);
```

## 가변 표현식
파라미터 팩에 포함된 모든 인자를 대상으로 계산을 수행할 수 있다. 

다음 코드는 모든 인자를 두 배로 한 다음 `print()`로 전달하는 함수이다.
```c++
template<typename... T>
void printDoubled(const T&... args) {
    print(args + args...);
}
```
```c++
printDoubled(7.5, std::string("hello"), std::complex<float>(4, 2));
/* 
print(
    7.5 + 7.5, 
    std::string("hello") + std::string("hello"),
    std::complex<float>(4, 2) + std::complex<float>(4, 2)
);
*/
```

다음 코드는 각 요소에 1을 더하는 코드이다. 이때 숫자 뒤에 줄임표(...)가 바로 붙지 않도록 조심하자
```c++
template<typename... T>
void addOne(const T&... args) {
    print(args + 1...);     // 에러, 1...은 소수점이 너무 많은 리터럴
    print(args + 1 ...);    
    print((args + 1)...);  
}
```

컴파일 과정 표현식도 이와 같은 방식으로 파라미터 팩을 포함시킬 수 있다.    
다음 코드는 모든 인자의 타입이 같은지 여부를 반환한다.
```c++
template<typename T1, typename... TN> 
constexpr bool isHomogeneous(T1, TN...) {
    return (std::is_same<T1, TN>::value && ...);    // c++17 이상
}
```

또 다른 예시로 인덱스의 목록을 받아 해당 인덱스에 해당하는 요소들을 출력하는 코드도 구현 가능하다. 
```c++
template<typename C, typename... Idx>
void printElems(const C& coll, Idx... idx) {
    print(coll[idx]...);
}

std::vector<std::string> coll = {"good", "times", "say", "bye"};
printElems(coll, 2, 0, 3);
// -> print(coll[2], coll[0], coll[3]);
```

타입이 아닌 템플릿 파라미터도 파라미터 팩으로 선언할 수 있다.
```c++
template<std::size_t... Idx, typename C>
void printIdx(const C& coll) {
    print(coll[idx]...);
}

printIdx<2, 0, 3>(coll);
```


## 가변 클래스 템플릿
클래스 템플릿도 가변 템플릿으로 만들 수 있다. 

템플릿 파라미터로 멤버의 타입을 자유자재로 명시할 수 있는 클래스는 만든다고 가정해 보자.
```c++
template<typename... Elements>
class Tuple;
Tuple<int, std::string, char> t;
```
혹은 자신이 가질 수 있는 객체 타입을 명시할 수도 있다.
```c++
template<typename... Types>
class Variant;
Variant<int, std::string, char> v;
```
인덱스의 목록을 나타내는 타입으로서 클래스를 정의할 수도 있다.
```c++
template<std::size_t...>
struct Indices {
    // ... 
};

template<typename T, std::size_t... Idx>
void printByIdx(T t, Indices<Idx...>) {
    print(std::get<Idx>(t)...);
}

auto t = std::make_tuple(12, "test", 2.0);
printByIdx(t, Indices<0, 1, 2>());
```

## 가변 연역 가이드 
클래스 템플릿이 가변적이라면 연역 가이드 역시 가변적일 수 있다.

다음은 c++ 표준 라이브러리에서 `std::array`에 대한 연역 가이드이다.
```c++
namespace std {

template<typename T, typename... U> array(T, U...)
    -> array<
        enable_if_t<(is_same_v<T, U> && ...), T>, 
        (1 + sizeof...(U))>;
}

std::array a{42, 45, 77};   // std::array<int, 3> a{42, 45, 77};
```
연역 가이드가 어떻게 동작하는지 차근차근 읽어보면 바로 이해가 될 것이다. (이해가 안된다면 이전 내용을 다시 보고 오자)
> enable_if<true, T>::type -> T, 타입 트레잇은 나중에 별도로 다룰 예정이다
{:.prompt-tip}

## 가변 기본 클래스
다음 예제 코드를 보자

```c++
#include <string>
#include <unordered_set>

class Customer {
public:
    Customer(const std::string& n) : name(n) {}
    std::string getName() const { return name; }
private:
    std::string name;
};
struct CustomerEq {
    bool operator() (const Customer& c1, const Customer& c2) const {
        return c1.getName() == c2.getName();
    }
};
struct CustomerHash {
    std::size_t operator() (const Customer& c) const {
        return std::hash<std::string>()(c.getName());
    }
};
```
위 코드를 보면 `Customer`클래스를 위한 비교 및 해시 연산을 `CustomerEq`, `CustomerHash`를 통해 제공하고 있다.
이때 다음 코드를 통해 `operator()`를 하나의 클래스로 결합시킬 수 있다.
```c++
template<typename... Bases>
struct Overloader : Bases... {
    using Bases::operator()...;     // C++17 이상
};

// Customer를 위한 연산이 결합된 하나의 타입 (CustomerOP)가 생성됨 
using CustomerOP = Overloader<CustomerHash, CustomerEq>;
```
위 코드는 가변적인 기본 클래스로부터 상속받는 클래스를 정의한다. 이후 각 기본 클래스에서 `operator()`선언을 불러온다. 

## 마치며
c++은 기본 원리만 잘 이해하면, 상상하는 웬만한 것들을 다 구현시켜 주는듯 하다. 내가 생각하는 이 언어의 매력 포인트중 하나이다.

헌데 가변인자 템플릿으로 이렇게 분량이 많아질줄은 몰랐다. (물론 템플릿 관련된 내용은 아직도 정리할게 많다....)