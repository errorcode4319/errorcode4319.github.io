---
title: '[C++] simdjson을 활용해 빠르게 Json 데이터 처리하기'
date: 2023-07-25 22:10:00 +/0900
categories: [c++, common]
tags: [c, c++, zpp_bits, c++20]
author: sdk
toc: true
comments: false 
math: true 
mermaid: true 
img_path: /gh/errorcode4319/cdn/images
---

기존 코드베이스에선 c++ json 파싱 라이브러리로 rapidjson을 사용하였으나, 최근 새로운 코드베이스를 작성하면서 simdjson를 도입하게 되었다. 성능과 사용성 둘 다 rapidjson보다는 좋다고 판단하였다. 

## simdjson
Git: [simdjson: Parsing gigabytes of JSON per second](https://github.com/simdjson/simdjson/)    
**"simdjson: Parsing gigabytes of JSON per second"**

성능을 상당히 강조하고 있다.    

그럴법도 한게 성능 테스트 결과를 보면 타 라이브러리에 비해 압도적으로 좋은 성능을 보여주고 있다.
![Simdjson Performance Test](/cpp/simdjson.png)
(기존에 쓰던 rapidjson이 너무 처량해 보인다...)

simdjson에서 강조하는 주요 특징은 고성능, 쉬운 사용성, 시스템 안정성 등이 있다.
(일반적으로 프로덕션 레벨에서 사용되는 Json 파서들보다 약 4배 이상 빠르다고 한다) 

README에 Quick Start 샘플 코드도 같이 작성되어 있다.

```c++
#include <iostream>
#include "simdjson.h"
using namespace simdjson;
int main(void) {
    ondemand::parser parser;
    padded_string json = padded_string::load("twitter.json");
    ondemand::document tweets = parser.iterate(json);
    std::cout << uint64_t(tweets["search_metadata"]["count"]) << " results." << std::endl;
}
``` 
일단 직접 써 봐야 알겠지만, 사용성은 좋아 보인다. 

## 기본 사용법 
simdjson에서 공식적으로 제공하는 [The Basics](https://github.com/simdjson/simdjson/blob/v3.2.1/doc/basics.md) 가이드 문서를 참고했다. 이번 포스팅에서 해당 가이드 문서의 모든 내용을 다 다루진 못하고 간략하게나마 정리해볼까 한다.

### 빌드 구성
simdjson을 프로젝트에서 사용할 경우 `simdjson.h`, `simdjson.cpp` 두 파일만 프로젝트 내에 포함시키면 된다. 
```c++
#include "simdjson.h"
using namespace simdjson;
```
```sh
c++ source.cpp simdjson.cpp
```
이 외에도 다양한 방법을 제공하며, 나는 개인적으로 개별적인 라이브러리로 빌드해서 사용하는 방식을 더 선호한다.

### Json 데이터 로드 및 파싱
Json 데이터를 로드 후 파싱하는 코드는 다음과 같다. 
```c++
using namespace simdjson;

ondemand::parser parser;
auto json = padded_string::load("twitter.json"); // load JSON file 'twitter.json'.
ondemand::document doc = parser.iterate(json); // position a pointer at the beginning of the JSON data
```
위 예제는 Json 파서 생성 후 `iterate()` 메서드를 통해 json document를 생성하는 코드이다. (상당히 심플하다)

simdjson에서는 padded_string을 사용하는데, 이는 문자열 뒤에 몇 바이트 가량의 여분 메모리 공간이 추가된 문자열 자료구조이다. 효율적인 데이터 처리를 위해서 이와 같은 형태의 문자열을 사용한다고 한다.

다음과 같이 padded_string을 만드는 다양한 방법을 제공한다.
```c++
auto json = padded_string::load("twitter.json");    // 파일 로드
```
```c++
auto json = "[1,2,3]"_padded;  // _padded 접미사 사용
```
```c++
ondemand::parser parser;
char json[3+SIMDJSON_PADDING];      // 일반 원시 배열도 사용 가능하다
strcpy(json, "[1]");
ondemand::document doc = parser.iterate(json, strlen(json), sizeof(json));
``` 
```c++
std::string data = "my data";
simdjson::padded_string my_padded_data(data); // 이게 가장 무난해 보인다
```

### 파싱 데이터 활용
문서의 내용을 기반으로 간단하게 파싱 데이터(document) 활용 예제를 작성해 봤다. 
```json
// ../data/sample.json
{
    "foo": 123,
    "obj": {
        "msg": "test",
        "num": 295.23
    },
    "arr": [1, 2, 3, 4, 5]
}
```
```c++
#include <iostream>
#include <simdjson.h>

using namespace simdjson;

int main(int argc, char* argv[]) {

    ondemand::parser parser;
    auto json = padded_string::load("../data/sample.json");
    ondemand::document doc = parser.iterate(json); 

    int64_t foo = doc["foo"];
    auto obj = doc["obj"];
    std::string_view msg = obj["msg"];
    double num = obj["num"];

    auto arr = doc["arr"].get_array();

    std::cout << "foo:" << foo << '\n';
    std::cout << "obj::msg: " << msg << '\n';
    std::cout << "obj::num: " << num << '\n';
    std::cout << "arr: ";
    for (auto e: arr) {
        std::cout << int(e.get_int64()) << ' ';
    }
    std::cout << '\n';
    return 0;
}
```

가이드 문서에 활용 예제(파싱 데이터 활용, 에러 핸들링, 성능 최적화 등)가 상당히 많이 있으니, 한번쯤 읽어볼 것을 권장한다. (이번 포스팅에서 다 다루기엔 다소 분량이 많다)

해당 테스트 코드는 [simdjson-sample](https://github.com/errorcode4319/simdjson-sample) 여기에 업로드 해 두었다.

## 유의사항
simdjson에서 파서를 통해 document를 생성할 경우, 이는 독립적인 Json 값을 가진 인스턴스가 아닌 Json데이터 파서에 대한 프론트엔드 인터페이스 역할을 수행한다.

필드를 검색하거나 배열에 대한 반복을 수행할 경우, 원본 Json 데이터(문자열) 위에서 커서를 옮기는 방식으로 데이터를 처리한다고 한다.

즉 원본 Json 데이터(문자열), parser, document 세 가지 인스턴스는 상호 보완적인 관계로 데이터를 파싱하는 동안 위 세가지 인스턴스는 메모리 상에 올라가 있어야 한다. 

또한 파서는 한 번에 하나의 Json 문서만을 열 수 있으며, json 데이터 하나당 하나의 document 인스턴스만이 존재해야 한다. 그렇기에 함수의 인자로 document를 넘겨야 하는 경우 값 대신 레퍼런스 형태로 전달해야 한다.  

simdjson 공식 문서 상에는 최적의 성능을 위해 파서 인스턴스를 여러 json 문서에 걸쳐 재사용할 것을 권장하고 있다. (자세한 사항은 [simdjson: performance-tips](https://github.com/simdjson/simdjson/blob/v3.2.1/doc/basics.md#performance-tips) 참조)


## 마치며
이번 포스팅에선 간단한 내용 위주로만 다뤄보았다.    

상당히 볼 거리도 많고 문서도 친절하게 세세한 부분까지 잘 다루고 있는듯 하니 앞으로 json데이터 파싱할때 상당히 유용하게 사용할듯 하다.