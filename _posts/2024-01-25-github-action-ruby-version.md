---
title: '[Github] jekyll 블로그 빌드시 Ruby 버전 에러'
date: 2024-01-25 00:10:00 +/0900
categories: [github]
tags: [github]
author: sdk
toc: true
comments: false 
math: true 
mermaid: true 
img_path: /gh/errorcode4319/cdn/images
---

방금 오랜만에 깃헙 블로그에 포스팅을 올렸더니 빌드가 안되는 현상이 있었다. (약 3달만에 포스팅 한듯)

![build-failed](/github/2024-01-25-page-build-failed.png)

보아하니 다음과 같은 에러가 뜨고 있었는데
```
The process '/opt/hostedtoolcache/Ruby/3.3.0/x64/bin/bundle' failed with exit code 5
```

인터넷을 찾아보던중 ruby 버전을 3.2로 맞추면 해결된다는 내용이 있었고, 다음 링크에서 해결책을 찾았다. (https://talk.jekyllrb.com/t/build-error-at-setup-ruby-need-help/8791)


`.github/workflows/pages-deploy.yml`파일에서 기존에 3으로 설정되어 있던 `ruby-version` 값을 3.2로 변경하니 빌드 에러가 싹 사라졌다.
```yaml
# ... 생략 ...

jobs:
# ...
    steps:
# ...
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2   # 이 부분을 3.2로 변경
          bundler-cache: true
# ...
```

늦은 시간이라 좀만 보다가 자려고 했는데, 생각보다 쉽게 해결되서 맘편히 잘 수 있겠다.