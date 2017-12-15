FROM ruby:2.4.2
RUN apt-get update -qq && apt-get upgrade -y
RUN apt-get install -y build-essential nodejs && apt-get clean

ENV MONGODB_URI mongodb://mongo/manuals-publisher
ENV PORT 3205
ENV RAILS_ENV development
ENV REDIS_HOST redis
ENV TEST_MONGODB_URI mongodb://mongo/manuals-publisher-test

ENV APP_HOME /app
RUN mkdir $APP_HOME

WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
RUN bundle install
ADD . $APP_HOME

ARG COMPILE_ASSETS=false
RUN if [ "$COMPILE_ASSETS" = "true" ] ; then bundle exec rails assets:precompile ; fi

CMD bash -c "rm -f tmp/pids/server.pid && bundle exec rails s -p $PORT -b '0.0.0.0'"