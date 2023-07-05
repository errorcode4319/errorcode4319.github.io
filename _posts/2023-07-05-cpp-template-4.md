---
title: '[C++ Template] 3. 타입이 아닌 템플릿 파라미터'
date: 2023-07-05 22:00:00 +/0900
categories: [c++, template]
tags: [c, c++, template]
author: sdk
toc: true
comments: false 
math: true 
mermaid: true 
img_path: /gh/errorcode4319/cdn/images
---

앞서 포스팅한 함수 템플릿과 클래스 템플릿에서는 타입에 대한 템플릿 파라미터를 설명했었다. 하지만 템플릿 파라미터는 타입이 아닌 일반 값 또한 사용 가능하다.   
이번 포스팅에선 타입이 아닌(Non-type) 템플릿 파라미터에 대해 다뤄볼까 한다.

## 타입이 아닌 클래스 템플릿 파라미터
기존 `Stack<T>` 클래스에서 최대 사이즈를 템플릿을 통해 명시할 경우 다음과 같이 클래스를 수정할 수 있다. (Stack<>는 이전 포스팅에서 다룬 샘플 클래스 템플릿이다.)
```c++
template<typename T, std::size_t MaxSize>
class Stack {
    // ...
};


Stack<int, 20>  i20_stack;
Stack<int, 40>  i40_stack;
Stack<std::string, 40>  str_stack;
```
>이때 `Stack<int, 20>`과 `Stack<int, 40>`은 서로 다른 타입으로 인스턴스화 된다.    
그러므로 둘 사이의 형변환이나 할당 역시 불가능하다. 
{:.prompt-tip}

마찬가지로 기본값 또한 명시할 수 있다.
```c++
template<typename T, std::size_t MaxSize = 100>
class Stack {
    // ...
};
```
## 타입이 아닌 함수 템플릿 파라미터
함수 템플릿에도 타입이 아닌 템플릿 파라미터를 사용할 수 있다.
```c++
template<int Val, typename T>
T addValue(T x) {
    return x + Val;
}
```

이런류의 함수는 보통 특정 함수나 연산이 파라미터로 사용될때 유용하다.
```c++
std::transform(src.begin(), src.end(), dst.begin(), addValue<5, int>);
```

이때 전달된 값을 통해 T를 연역하기 위해 다음과 같이 함수 템플릿을 수정할 수 있다.
```c++
template<auto Val, typename T = decltype(Val)>
T foo();
```

혹은 전달된 값이 전달된 타입과 같은 타입을 갖게 강제할 수도 있다.
```c++
template<typanem T, T Val = T{}>
T bar();
```

## 각종 제약 사항
타입이 아닌 템플릿 파라미터에는 몇 가지 제약 사항이 있다. 

일반적으로 정수 상수값(열거형 포함), 객체/함수/멤버에 대한 포인터, 객체나 함수에 대한 좌측값 참조 또는 `std::nullptr_t`(`nullptr`의 타입) 이어야 한다.

부동소수점(float, double) 혹은 클래스 타입은 템플릿 파라미터로 사용될 수 없다.
```c++
template<double VAT>
double process(double v) {  // 에러, double은 템플릿 파라미터로 사용 불가
    return v * VAT;
}

template<std::string name>  // 에러, 클래스 타입은 템플릿 파라미터로 사용 불가 
class MyClass {
    // ...
};
```

포인터나 레퍼런스를 템플릿 파라미터로 전달할 때 객체는 문자열 리터럴, 임시 객체, 데이터 멤버 혹은 타 하위 객체여서는 안된다. 
```c++
template<const char* name>
class MyClass {
    // ...
};
MyClass<"hello">    x;  // 에러, 문자열 리터럴은 사용할 수 없다. 
```
문자열의 경우 포인터 타입이 아닌 상수 배열 형태로는 템플릿 파라미터로 전달할 수 있으며 해당 내용은 해당 포스팅의 'auto 타입' 항목에서 다룬다. 

### 유효하지 않은 표현식 
타입이 아닌 템플릿 파라미터는 컴파일 과정 표현식이기만 하면 된다. 

```c++
template<int I, bool B>
class C;
//...
C<sizeof(int)+4, sizeof(int)==4> c;
```
`>`연산을 템플릿 파라미터의 표현식에서 사용하려면 `>`때문에 파라미터 목록이 끝나지 않게 전체 표현식을 괄호로 감싸야 한다.
```c++
C<42, sizeof(int) > 4> c;   // 에러
C<42, (sizeof(int) > 4)> c;
```

## auto 타입
c++17부터는 타입이 아닌 템플릿 파라미터로 허용된 어떠한 형식이든 받아들일 수 있게 정의할 수 있다. 
```c++
template<typename T, auto MaxSize>
class Stack {
    using size_type = decltype(MaxSize);
    // ...
};
```
위처럼 플레이스홀더 타입(placeholder type) auto를 사용해 아직 명시되지 않은 타입을 갖는 값으로 `MaxSize`를 정의할 수 있다.

```
Stack<int, 20>  i20stack;   // size_type == int
Stack<int, 40u> i40stack;   // size_type == unsigned int 
Stack<int, 3.5> i3_5stack;  // 에러
```
물론 앞서 설명했던 제약 조건에 따라 실수형 값은 사용할 수 없다.

또한 문자열은 상수 배열로 전달할 수 있기 때문에 다음 코드 역시 사용 가능하다. 
```c++
#include <iostream>

template<auto T>
class Message {
public:
    void print() {
        std::cout << T << '\n';
    }
};

int main() {
    Message<42>     msg1;
    msg1.print();

    static const char s[] = "hello";
    Message<s> msg2;    // T == "hello", Type == const char[6]
    msg2.print();
}
```
문자열의 경우 포인터 타입이 아닌 상수 배열로 전달할 수 있으며 C++17까지 오면서 점점 이러한 제약 사항이 완화되고 있다.    
```c++
extern const char s03[] = "hello"  // 외부 링크 
const char s11[] = "hello";        // 내부 링크 

int main() {
    Message<s03>    m03;        // 모든 버전 사용 가능
    Message<s11>    m11;        // c++11 이상 사용 가능

    static const char s17[] = "hello"; // 링크 없음
    Message<s17>    m17;        // c++17 이상 사용 가능 
}
```
객체가 외부 링크를 가졌다면 모든 c++ 버전에서 사용할 수 있다. 또한 c++11부터는 내부 링크만 있어도 사용 가능하며, c++17부터는 링크 없이도 사용 가능하다. 


심지어 `template<decltype(auto) N>`도 가능하다. `N`을 레퍼런스로써 인스턴스화 시킬때 사용 가능하다. 
```c++
template<decltype(auto) N>
class C{
    // ...
};

int i;
C<(i)>  x;
```
위 코드에서 `N`의 타입은 `int&`가 된다.

## 마치며
템플릿은 언제나 힘든 주제인것 같다. (아직 다뤄야할 것들이 많은데..)   
다음 포스팅에서는 가변 인자 템플릿에 대해 다뤄볼까 한다. 