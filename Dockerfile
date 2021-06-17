FROM ruby:3-slim
MAINTAINER Populate <lets@populate.tools>

RUN apt-get update && apt-get install -y -q nodejs

WORKDIR /app
