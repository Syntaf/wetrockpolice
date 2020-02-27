FROM ruby:2.5.3
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client
RUN gem update --system && gem install bundler -v 2.0.1
WORKDIR /opt/wetrockpolice

COPY Gemfile /opt/wetrockpolice
COPY Gemfile.lock /opt/wetrockpolice
RUN bundle install
COPY . /opt/wetrockpolice

COPY entrypoint.sh /usr/bin
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT [ "entrypoint.sh" ]
EXPOSE 3000

CMD [ "rails", "server", "-b", "0.0.0.0" ]