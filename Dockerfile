FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Seoul

ENV GEM_HOME=/gems 
ENV PATH=/gems/bin:$PATH

RUN apt update && apt -y install tzdata git ruby-full build-essential zlib1g-dev

RUN gem install jekyll bundler

WORKDIR workspace
CMD     bundle install; bundle exec jekyll serve --livereload --host 0.0.0.0