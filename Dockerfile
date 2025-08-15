FROM ruby:3.3-alpine

VOLUME /data
LABEL description="Ruby Maat - A Ruby port of Code Maat for mining VCS data"

ARG dest=/usr/src/ruby-maat

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git

# Set working directory
RUN mkdir -p $dest
WORKDIR $dest

# Copy gem files first for better caching
COPY ruby-maat.gemspec Gemfile Gemfile.lock $dest/
COPY lib/ruby_maat/version.rb $dest/lib/ruby_maat/

# Install dependencies
RUN bundle install --deployment --without development test

# Copy the rest of the application
COPY . $dest

# Build and install the gem
RUN gem build ruby-maat.gemspec && \
    gem install ruby-maat-*.gem && \
    rm -rf $dest

# Create a non-root user
RUN adduser -D -s /bin/sh ruby-maat
USER ruby-maat

# Set working directory to /data for user convenience
WORKDIR /data

ENTRYPOINT ["ruby-maat"]
CMD ["--help"]
