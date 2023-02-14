FROM ruby:3.2.0-alpine as base

WORKDIR /mnt

RUN adduser --system app &&\
  bundle config --local path vendor/bundle &&\
  bundle config set --local deployment 'true' &&\
  bundle config set --local without 'development test'

FROM base as builder

RUN apk update &&\
  apk add alpine-sdk --no-cache

COPY Gemfile Gemfile.lock ./
RUN bundle install

FROM base

COPY --from=builder /mnt .

ADD . .

USER app

CMD ["bundle", "exec", "./exe/faas_supervisor"]
