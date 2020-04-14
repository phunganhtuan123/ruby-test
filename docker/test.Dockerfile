FROM ruby:2.6.3

RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get install -y build-essential
RUN apt-get install -y git
RUN apt-get install -y libgd-dev
RUN apt-get install -y zsh
RUN PATH="$PATH:/usr/bin/zsh"

RUN mkdir /teko
WORKDIR /teko
COPY Gemfile /teko/Gemfile
COPY Gemfile.lock /teko/Gemfile.lock
RUN bundle install
COPY . /teko

EXPOSE 4567

CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "4567"]
