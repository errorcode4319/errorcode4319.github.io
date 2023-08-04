---
title: '[C++ Template] 9. 템플릿의 실제 사용'
date: 2023-08-03 23:00:00 +/0900
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

이번 포스팅에선 실용적으로 템플릿을 사용할 수 있는 방법에 대해 다뤄볼까 한다. 

## 포함 모델
템플릿 소스를 구성하는 방식은 여러가지가 있지만, 그중에서도 가장 흔하게 사용되는 방식인 포함 모델에 대해 다뤄보고자 한다.

### 링커 오류
일반적으로 C/C++에선 코드를 헤더와 소스로 구성한다. 하지만 함수 템플릿을 다음과 같이 일반적인 코드처럼 헤더와 소스로 분리하면 문제가 생긴다.
```c++
// func.hpp
template<typename T>
void func(T const&);
```
```c++
// func.cpp
template<typename T>
void func(T const& x) {
    // ... 
}
```
```c++
// main.cpp
#include "func.hpp"

int main() {
    double num = 1.0;
    func(num);
}
```
보통 컴파일러는 위 코드에서 오류를 발생시키진 않는다. 하지만 링커에서 에러가 발생하는데, 이는 `func()`의 정의가 인스턴스화되지 않았기 때문이다. 당연하게도 `main.cpp`에서 `func(num)`으로 호출한다고 해서, `func.cpp`를 컴파일 할때 `func(double const& x)`에 대한 정의를 인스턴스화 하진 않는다.

### 헤더 파일에 템플릿 정의
앞서 설명한 링커 오류를 해결하는 가장 쉬운 방법은, 템플릿의 정의를 선언부와 같이 헤더 파일에 포함시키는 것이다.

```c++
template<typename T>
void func(T const&);
// ...


template<typename T>
void func(T const& x) {
    // ... 
}
```

이런식으로 템플릿을 포함시키는 것을 포함 모델이라고 한다. 이 방식을 사용하면 컴파일 및 링크 작업을 올바르게 수행할 수 있다. 하지만 이런식으로 템플릿의 정의까지 헤더에 다 포함시키게 되면, 헤더파일을 포함시키는 비용이 다소 많아진다 (컴파일 시간이 길어진다).   

이러한 문제를 해결하기 위해 사전 컴파일된 헤더나 명시적 템플릿 인스턴스화를 사용할 수 있다. 

### 템플릿과 인라인
함수 템플릿은 인라인과 마찬가지로 여러 컴파일 단위에 정의가 포함될 수 있다. 그리고 컴파일러에 의해 함수 템플릿이 인라인과 같이 동작할 수도 있다. 

함수 템플릿은 인라인 함수와 유사하지만, 엄연히 인라인과 다르다. 또한 함수 템플릿의 전체 특수화시 일반 함수와 동일해지며, inline이 아닌 전체 특수화 정의는 일반 함수처럼 단 한 번만 나타날 수 있다.

## 사전 컴파일된 헤더 
템플릿이 아니더라도 헤더 파일의 크기는 매우 커질수 있고, 그로인해 컴파일 시간 역시 상당히 길어질 수 있다. 이러한 상황을 위해 컴파일러마다 사전 컴파일된 헤더(PCH, precompiled header)라는 기능을 제공한다. 

사전 컴파일된 헤더 기법은 대부분 동일한 코드로 시작한다는 점에서 착안되었다. 동일한 헤더파일을 포함시키면 동일한 그 부분에 한해서는 코드가 생성된다. 그러므로 사전 컴파일된 헤더를 효율적으로 사용하기 위해서는 시작 부분에 동일한 코드가 최대한 많이 들어가야 한다. 

실제로 헤더가 포함되는 (`#include<>`) 순서만 동일하게 맞춰도 컴파일 성능이 크게 향상된다. 또한 불필요한 헤더를 포함시키더라도 사전 컴파일 헤더를 통해 컴파일 성능에 크게 영향을 주진 않는다.    

예를 들어 다음과 같이 여러 c++ 표준 라이브러리 헤더를 포함시켜도 컴파일 시간 측면에서 크게 걱정할 필요는 없다.
```c++
// std.hpp
#include <iostream>
#include <string>
#include <vector>
#include <deque>
#include <list>
// ...
```
```c++
// main.cpp
#include "std.hpp"

```

## 템플릿 오류 메시지 
보통 컴파일 오류가 발생할 경우 오류 메시지는 상당히 직관적으로 중요한 지점만 알려준다. 하지만 템플릿의 경우 오류 메시지는 다소 사람을 힘들게 만든다. (겪어본 사람은 안다)

이번 포스팅에선 아주 기본적인 템플릿 오류 메시지의 내용을 분석해볼까 한다.

다음 코드를 보자 
```c++
#include <string>
#include <map>
#include <algorithm>

int main() {
    std::map<std::string, double> coll;

    auto pos = std::find_if(coll.begin(), coll.end(), 
        [](const std::string& s) { return s != "";}
    );
}
```
다소 사소한 실수이다. `std::pair<std::string const, double>`을 인자로 받아야 하는데 `const std::string&`을 인자로 받는 람다를 사용한다. g++로 컴파일 할 경우 다음과 같은 에러 메시지가 출력된다. (엔터는 임의로 추가했다)
```c++
In file included from /usr/include/c++/11/bits/stl_algobase.h:71,
                 from /usr/include/c++/11/bits/char_traits.h:39,
                 from /usr/include/c++/11/string:40,
                 from main.cpp:1:

/usr/include/c++/11/bits/predefined_ops.h: In instantiation of ‘constexpr bool __gnu_cxx::__ops::_Iter_pred<_Predicate>::operator()(_Iterator) [with _Iterator = std::_Rb_tree_iterator<std::pair<const std::__cxx11::basic_string<char>, double> >; _Predicate = main()::<lambda(const string&)>]’:

/usr/include/c++/11/bits/stl_algobase.h:2052:42:   required from ‘constexpr _InputIterator std::__find_if(_InputIterator, _InputIterator, _Predicate, std::input_iterator_tag) [with _InputIterator = std::_Rb_tree_iterator<std::pair<const std::__cxx11::basic_string<char>, double> >; _Predicate = __gnu_cxx::__ops::_Iter_pred<main()::<lambda(const string&)> >]’

/usr/include/c++/11/bits/stl_algobase.h:2114:23:   required from ‘constexpr _Iterator std::__find_if(_Iterator, _Iterator, _Predicate) [with _Iterator = std::_Rb_tree_iterator<std::pair<const std::__cxx11::basic_string<char>, double> >; _Predicate = __gnu_cxx::__ops::_Iter_pred<main()::<lambda(const string&)> >]’

/usr/include/c++/11/bits/stl_algo.h:3910:28:   required from ‘constexpr _IIter std::find_if(_IIter, _IIter, _Predicate) [with _IIter = std::_Rb_tree_iterator<std::pair<const std::__cxx11::basic_string<char>, double> >; _Predicate = main()::<lambda(const string&)>]’

main.cpp:8:28:   required from here

/usr/include/c++/11/bits/predefined_ops.h:318:30: error: no match for call to ‘(main()::<lambda(const string&)>) (std::pair<const std::__cxx11::basic_string<char>, double>&)’
  318 |         { return bool(_M_pred(*__it)); }
      |                       ~~~~~~~^~~~~~~

/usr/include/c++/11/bits/predefined_ops.h:318:30: note: candidate: ‘bool (*)(const string&)’ {aka ‘bool (*)(const std::__cxx11::basic_string<char>&)’} (conversion)

/usr/include/c++/11/bits/predefined_ops.h:318:30: note:   candidate expects 2 arguments, 2 provided

main.cpp:9:9: note: candidate: ‘main()::<lambda(const string&)>’
    9 |         [](const std::string& s) { return s != "";}
      |         ^
main.cpp:9:9: note:   no known conversion for argument 1 from ‘std::pair<const std::__cxx11::basic_string<char>, double>’ to ‘const string&’ {aka ‘const std::__cxx11::basic_string<char>&’}
```
벌써부터 어지럽다. 

가장 시작 지점을 보면 어디에서부터 문제가 발생했는지 알 수 있다.

```c++
In file included from /usr/include/c++/11/bits/stl_algobase.h:71,
                 from /usr/include/c++/11/bits/char_traits.h:39,
                 from /usr/include/c++/11/string:40,
                 from main.cpp:1:
```

뒤이어 오는 출력 메시지를 잘 읽어 보면 문제가 발생한 해당 템플릿의 인스턴스화가 어떻게 수행되는지를 알려준다.
```c++
// 최종적인 문제의 원인 
/usr/include/c++/11/bits/predefined_ops.h: In instantiation of ‘constexpr bool __gnu_cxx::__ops::_Iter_pred<_Predicate>::operator()(_Iterator) [with _Iterator = std::_Rb_tree_iterator<std::pair<const std::__cxx11::basic_string<char>, double> >; _Predicate = main()::<lambda(const string&)>]’:

// 3단계
/usr/include/c++/11/bits/stl_algobase.h:2052:42:   required from ‘constexpr _InputIterator std::__find_if(_InputIterator, _InputIterator, _Predicate, std::input_iterator_tag) [with _InputIterator = std::_Rb_tree_iterator<std::pair<const std::__cxx11::basic_string<char>, double> >; _Predicate = __gnu_cxx::__ops::_Iter_pred<main()::<lambda(const string&)> >]’

// 2단계 
/usr/include/c++/11/bits/stl_algobase.h:2114:23:   required from ‘constexpr _Iterator std::__find_if(_Iterator, _Iterator, _Predicate) [with _Iterator = std::_Rb_tree_iterator<std::pair<const std::__cxx11::basic_string<char>, double> >; _Predicate = __gnu_cxx::__ops::_Iter_pred<main()::<lambda(const string&)> >]’

// 1단계
/usr/include/c++/11/bits/stl_algo.h:3910:28:   required from ‘constexpr _IIter std::find_if(_IIter, _IIter, _Predicate) [with _IIter = std::_Rb_tree_iterator<std::pair<const std::__cxx11::basic_string<char>, double> >; _Predicate = main()::<lambda(const string&)>]’

// main
main.cpp:8:28:   required from here
```

다시 문제의 코드로 돌아가 보자
```c++
std::map<std::string, double> coll;

auto pos = std::find_if(coll.begin(), coll.end(), 
    [](const std::string& s) { return s != "";}
);
```
해당 코드에서 컴파일 할 경우, 먼저 `stl_algo.h`에 있는 `find_if` 템플릿을 다음과 같이 인스턴스화 한다.
```c++
_IIter std::find_if(_IIter, _IIter, _Predicate)
[with   
    `_IIter = std::_Rb_tree_iterator<
        std::pair<std::__cxx11::basic_string<char>, double>>;
    // std::__cxx11::basic_string<char> == std::string 
    
    _Predicate = main()::<lambda(const string&)>
]
```
1단계 에러 메시지를 좀 더 보기좋게 만들면 위와 같은 내용이 된다. `_IIter`, `_Predicate` 가 어떻게 인스턴스화 되는지 보다 상세하게 설명해 준다.

이후 최종적으로 문제가 되는 부분은 다음과 같다.
```c++
// /usr/include/c++/11/bits/predefined_ops.h: In instantiation of 

constexpr bool __gnu_cxx::__ops::_Iter_pred<_Predicate>::operator()(_Iterator) [with 
    _Iterator = std::_Rb_tree_iterator<
        std::pair<const std::__cxx11::basic_string<char>, double>>; 
    _Predicate = main()::<lambda(const string&)>
]:
```
앞뒤로 보다 복잡한 요소들이 많이 붙었지만 결론적으로는, 앞서 람다로 정의했던 `_Predicate` 호출 인자를 `_Iterator`로 전달하는 시점에 인스턴스화에 실패한다. 

뒤이어 오는 에러 메시지를 살펴보자
```c++
/usr/include/c++/11/bits/predefined_ops.h:318:30: error: no match for call to ‘(main()::<lambda(const string&)>) (std::pair<const std::__cxx11::basic_string<char>, double>&)’
  318 |         { return bool(_M_pred(*__it)); }
      |                       ~~~~~~~^~~~~~~
```
내용 그대로 타입이 맞지 않아 함수 호출에 실패했다는 내용이다.  

```c++
/usr/include/c++/11/bits/predefined_ops.h:318:30: note: candidate: ‘bool (*)(const string&)’ {aka ‘bool (*)(const std::__cxx11::basic_string<char>&)’} (conversion)

/usr/include/c++/11/bits/predefined_ops.h:318:30: note:   candidate expects 2 arguments, 2 provided

main.cpp:9:9: note: candidate: ‘main()::<lambda(const string&)>’
    9 |         [](const std::string& s) { return s != "";}
      |         ^
```
이후 `note: candidate:` 메시지를 통해 후보 형식으로  `bool (*)(const string&)` 타입을 기대하고 있으며, `main.cpp` 9번째 라인에 있는  `[](const std::string& s) { return s != "";}`에 해당 후보가 정의되어 있음을 설명한다.

그리고 최종적으로 해당 후보를 왜 사용할 수 없는지에 대한 설명이 나온다
```c++
main.cpp:9:9: note:   no known conversion for argument 1 from ‘std::pair<const std::__cxx11::basic_string<char>, double>’ to ‘const string&’ {aka ‘const std::__cxx11::basic_string<char>&’}
```
`std::pair<const std::string, double>` 인자를 `const string&`으로 변환할 수 없음을 설명하고 있다.

즉 결론적으로 앞서 설명한 코드의 문제점을 컴파일러가 아주 디테일한 형태로 설명하고 있는 것이다.
>다소 사소한 실수이다. `std::pair<std::string const, double>`을 인자로 받아야 하는데 `const std::string&`을 인자로 받는 람다를 사용한다.

## 마치며 
사실 오류 메시지를 차근차근 읽어나가다 보면 상당히 디테일하게 필요한 내용 위주로 나열되어 있다 보니, 갑자기 방대한 양의 에러 메시지가 뿜어져 나오더라도 너무 당황하지 말고 침착하게 대처하자.

막상 또 템플릿 컴파일 오류 메시지는 몇 번 보면, 어느 순간엔 나름대로의 요령이 생기는 듯 하다. 