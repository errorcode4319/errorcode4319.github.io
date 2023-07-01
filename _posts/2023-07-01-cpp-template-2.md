---
title: '[C++ Template] 2. 클래스 템플릿 1'
date: 2023-07-01 13:00:00 +/0900
categories: [c++, template]
tags: [c, c++, template]
author: sdk
toc: true
comments: false 
math: true 
mermaid: true 
img_path: /gh/errorcode4319/cdn/images
---

이번시간에는 클래스 템플릿에 대해서 다뤄볼까 한다. 

## 템플릿 기반 Stack 구현
본 포스팅에서 샘플로 사용하기 위해서, 클래스 템플릿 Stack을 구현해 보도록 하겠다.
```c++
#include <vector>

template<typename T>
class Stack {
public:
    void push(const T& e);
    void pop();
    const T& top() const;
    bool empty() const { return elems.empty()};
private:
    std::vector<T> elems;
};

template<typename T> 
void Stack<T>::push(const T& e) {
    elems.push_back(e);
}

template<typename T>
void Stack<T>::pop() {
    elems.pop_back();
}

template<typename T>
const T& Stack<T>::top() const {
    return elems.back();
}
```

위 예시는 T 타입의 데이터를 관리하는 스택 자료구조에 대한 템플릿 클래스이다. 내부적으로는 `std::vector<>`를 활용해 구현되었으며(이건 크게 중요하지 않음), 클래스 템플릿의 인터페이스를 중점적으로 살펴보자.

### 클래스 템플릿 선언
클래스 템플릿을 선언하는 방식은 함수 템플릿과 유사하다.
```c++
template<typename T>
class Stack {
public:
    void push(const T& e);
    void pop();
    const T& top() const;
    bool empty() const { return elems.empty()};
private:
    std::vector<T> elems;
};
```

이 클래스의 타입은 `Stack<>`이고, `T`는 템플릿 파라미터이다. 그러므로 템플릿 인자를 연역할 수 있는 경우를 제외하면 선언 내에서 해당 클래스의 형식을 사용할때는 `Stack<T>`로 표기한다.
```c++
template<typename T>
class Stack {
    ...
    Stack(const Stack<T>&);
    Stack<T>& operator= (const Stack<T>&);
    ...
};
```
또한 클래스명 뒤에 템플릿 인자를 명시하지 않을 경우, 자신의 인자로 템플릿 파라미터를 사용하는 클래스라는 의미로 사용된다. 해당 원리에 따라 위 코드는 다음처럼 작성할 수도 있다.
```c++
template<typename T>
class Stack {
    ...
    Stack(const Stack&);
    Stack& operator= (const Stack&);
    ...
};
```
물론 클래스 외부에서는 템플릿 타입(`<T>`)을 명시해야 한다. 

### 멤버 함수 정의
클래스 템플릿의 멤버 함수를 외부에서 정의하려면 함수 템플릿임을 명시해야 한다. `push()` 멤버함수를 정의하는 방법은 다음과 같다.
```c++
template<typename T>
void Stack<T>::push(const T& e) {
    elems.push_back(e);
}
```

## 클래스 템플릿 Stack 사용
위 코드를 통해 작성한 `Stack<>` 클래스를 사용하는 방법은 다음과 같다.
```c++
#include "stack.hpp"    // Stack<>
#include <iostream>
#include <string>

int main() {
    Stack<int>          int_stack;
    Stack<std::string>  string_stack;
    int_stack.push(7);
    std::cout << int_stack.top() << '\n';

    string_stack.push("Hello");
    std::cout << string_stack.top() << '\n';
    string_stack.pop();
}
```

`Stack<int>`을 사용할 경우, 템플릿 내에서는 `T`를 `int`로 사용한다. 그러므로 `int`형 벡터를 멤버로 가지고, push, pop, top 등을 통해 `int`형 데이터를 관리한다. `Stack<std::string>`도 마찬가지로 동작한다. 이때 호출된 멤버 함수에 대해서만 인스턴스화를 수행한다.
> C++11 전에는 두 템플릿 꺽쇠(`>`) 사이에 공백을 둬야 했다.   
`Stack<std::vector<int> > stack;`   
하지만 C++11 부터는 `>>`를 쉬프트 연산자로 오인식하는 문법 오류가 해결되었다.
`Stack<std::vector<int>> stack;`  
{: .prompt-tip}

## 클래스 템플릿의 일부 사용
클래스 템플릿은 인스턴스화된 대상인 템플릿 인자에 대해 여러 가지 연산을 적용한다. 하지만 템플릿 인자는 모든 멤버 함수에 필요한 모든 연산을 지원할 필요는 없다. 실제로 사용되는 필요 연산들만 제공하면 된다. 

다음 예시를 보자.  
```c++
template<typename T>
class Stack {
    ...
    void print() (std::ostream& strm) const {
        for (const T& e : elems) {
            strm << e << ' ';
        }
    } 
};
```
`Stack<>`클래스의 각 요소에 대해 `operator<<`를 호출해 모든 스택의 내용을 출력하는 멤버 함수가 있다. 이때 `operator<<`가 없는 타입을 통해서도 `Stack<>` 클래스를 사용할 수 있다.
```c++
Stack<std::pair<int,int>> ps;
ps.push({4, 5});
ps.push({6, 7});
std::cout << ps.top().first << '\n';
```
위 코드는 에러가 발생하진 않지만, 잠재적인 문제를 가지고 있다. `std::pair<>`는 `operator<<`를 지원하지 않는 타입이다. 그래서 `print()` 멤버는 컴파일 에러가 발생할 수 밖에 없다. 하지만 해당 멤버를 사용하지 않은 시점에는 인스턴스화 또한 되지 않기 때문에, 해당 에러가 발생하지 않는다. 

하지만 위 코드에서 `print()` 멤버 함수를 호출할 경우 컴파일 에러가 발생한다.
```c++
Stack<std::pair<int,int>> ps;
ps.push({4, 5});
ps.push({6, 7});
ps.print(std::cout);    
// 컴파일 에러, T(=pair<>)는 ostream에 대한 <<연산을 지원하지 않는다
```

## friend 멤버 함수 
스택의 내용을 출력할 때 `print()` 함수를 호출하는 것 보다, `std::ostream`에 대한 `operator<<`를 구현하는 편이 더 좋은 사용성을 제공한다.   
`std::ostream`에 대한 `operator<<`을 비멤버 함수로 구현하고, 내부에서 `print()` 함수를 호출하도록 하는 코드는 다음과 같다.

```c++
template<typename T>
class Stack {

    void print(std::ostream& strm) const {
        ...
    }

    friend std::ostream& operator<< (std::ostream& strm, const Stack& s) {
        s.print(strm);
        return strm;
    }

};
```
이때 중요한 점은 `Stack<>`에 포함된 `operator<<`가 함수 템플릿이 아닌, 필요에 의해 클래스 템플릿과 같이 인스턴스화 되는 일반 함수라는 점이다.

하지만 friend 함수에 대한 선언과 정의를 분리할 경우, 다소 문제가 복잡해진다. 일반적으로 다음과 같이 작성할 경우 다음과 같은 오류가 발생한다. 

```c++
template<typename T>
class Stack {
    ...
    void print(std::ostream& strm) const { ... }

    friend std::ostream& operator<< (std::ostream& strm, const Stack<T>& s);

};

template<typename T>
friend std::ostream& operator<< (std::ostream& strm, const Stack<T>& s) {
    s.print(strm);
    return strm;
}


int main() {
    Stack<int> s;
    s.push(1);
    s.push(2);
    std::cout << s << std::endl;
}
```
```sh
undefined reference to `operator<<(std::ostream&, Foo<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > > const&)'
collect2: error: ld returned 1 exit status
```
에러 메시지를 보면 알겠지만, Stack<int>에 대한 `operator<<`를 인스턴스화 시키지 못한다.  

이때 다음과 같이 전방선언을 통해 문제를 해결할 수 있다.

```c++
template<typename T>
class Stack;
template<typename T>
std::ostream& operator<< (std::ostream&, const Stack<T>&);

template<typename T>
class Stack {
    ...
    void print(std::ostream& strm) const { ... }

    // 함수명 뒤에 <T>를 명시
    friend std::ostream& operator<< <T>(std::ostream& strm, const Stack<T>& s);

};
```
위 코드를 통해 비멤버 함수 템플릿의 특수화를 friend로 선언한 것이다.