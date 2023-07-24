---
title: '[C++] zpp_bits을 활용해 데이터 직렬화 하기'
date: 2023-07-24 22:30:00 +/0900
categories: [c++, common]
tags: [c, c++, zpp_bits, c++20]
author: sdk
toc: true
comments: false 
math: true 
mermaid: true 
img_path: /gh/errorcode4319/cdn/images
---

최근 데이터 전송 모듈을 개발하면서 zpp_bits 라는 라이브러리를 사용하게 되었다. (사실 예전부터 눈여겨 보고 있었으나, 그간 딱히 쓸 일이 없었다..)

## zpp_bits
Repo: [zpp::bits](https://github.com/eyalz800/zpp_bits)   
"A modern C++20 binary serialization and RPC library, with just one header file."

C++20 기반 바이너리 직렬화 라이브러리이다. 단일 헤더파일로 제공되는것이 상당히 매력적이다.    
성능 또한 상당히 준수하다. ([cpp serializers benchmark](https://github.com/fraillt/cpp_serializers_benchmark/tree/a4c0ebfb083c3b07ad16adc4301c9d7a7951f46e))    

사용성 또한 좋아 보인다. 샘플 소스는 다음과 같다.
```c++
struct person
{
    std::string name;
    int age{};
};
```
```c++

// The `data_in_out` utility function creates a vector of bytes, the input and output archives
// and returns them so we can decompose them easily in one line using structured binding like so:
auto [data, in, out] = zpp::bits::data_in_out();

// Serialize a few people:
out(person{"Person1", 25}, person{"Person2", 35});

// Define our people.
person p1, p2;

// We can now deserialize them either one by one `in(p1)` `in(p2)`, or together, here
// we chose to do it together in one line:
in(p1, p2);
```

신나서 바로 써봤다.

## 빌드환경 구성
참고로 필자의 작업 환경은 Ubuntu 22.04이다. 본 포스팅에서는 간단하게 cmake로 빌드환경을 구성해볼까 한다.    

디렉토리 구조는 다음과 같다.(소스코드: [cpp-data-serialization](https://github.com/errorcode4319/cpp-data-serialization))
```
├── CMakeLists.txt
├── README.md
├── src
│   └── main.cpp
└── submodules
    └── zpp_bits
```

`CMakeLists.txt`는 다음과 같이 작성했다.
``` cmake
project(cpp-data-serialization)

cmake_minimum_required(VERSION 3.22)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED On)

file(GLOB_RECURSE sources src/*.cpp src/*.hpp)

add_executable(sample ${sources})
target_include_directories(
    sample PRIVATE 
    submodules/zpp_bits
)
```
단촐하다. 사실 소스파일은 src/main.cpp 하나뿐이다.

## 샘플 코드 
`main.cpp` 소스는 다음과 같다.  (공식 저장소 README를 꼭 읽어 보자. 보다 다양한 예제가 많이 포함되어 있다.)

```c++
#include <iostream>

#include <vector>
#include <map>
#include <deque>

#include <zpp_bits.h>


struct Data {
    std::string msg;
    std::map<std::string, std::string> table;
    std::deque<std::string> buf;
};

int main(int argc, char* argv[]) {
    std::cout << "Cpp Data Serialization\n";

    // 임의 데이터 구성 
    auto src = Data{
        .msg="Test String, Test String, Test String, ASDFQWERASDFQWERASDFQWERASDFQWER",
        .table={
            {"key1", "val1"},
            {"key2", "val2"},
            {"key3", "val3"},
            {"key4", "val4"},
            {"key5", "val5"},
            {"key________________________________long_______6", "val________________________________long_______6"},
            {"key________________________________long_______7", "val________________________________long_______7"},
            {"key________________________________long_______8", "val________________________________long_______8"},
        },
        .buf={
            "message1",
            "message2",
            "message3",
            "message4",
            "message5",
        }
    };

    // data_in_out 생성 
    auto [data, in, out] = zpp::bits::data_in_out();

    auto result = out(src);
    if (failure(result)) {
        std::cerr << "Serialization Failed" << std::endl;
        std::cerr << "Error Code: " << int(result.code) << std::endl;
        exit(1);
    }

    std::cout << "Bytes: " << data.size() << std::endl;

    Data dst;

    result = in(dst);

    if (failure(result)) {
        std::cerr << "Deserialization Failed" << std::endl;
        std::cerr << "Error Code: " << int(result.code) << std::endl;
        exit(1);
    }

    // 값 출력 
    std::cout << "msg: " << dst.msg << '\n';
    for (const auto&[k, v]: dst.table) {
        std::cout << k << ':' << v << '\n';
    };
    for(const auto& s: dst.buf) {
        std::cout << s << '\n';
    }
    
    return 0;
}
```

이때 해당 소스에서 `data`의 타입은 `std::vector<std::byte>`이다.   

`out`을 통해 데이터를 직렬화 시키면 `data`에 저장된다. 
이후 `in`을 사용해 데이터를 역직렬화 시킬 경우 해당 `data`내에 저장된 바이너리 데이터를 사용한다.

이것저것 테스트 해본 바 c++ 표준 라이브러리에 포함된 컨테이너중 `stack`, `queue`는 사용할 수 없었다. (iterator가 제공되지 않아서 그런가? 좀 더 알아봐야겠다.)

## 마치며
성능도 좋고 사용성도 상당히 직관적이다. 이제 앞으로 유용하게 사용해 봐야겠다. 