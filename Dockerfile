# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t sentiment_analyzer .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name sentiment_analyzer sentiment_analyzer

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Use Ubuntu 24.04 LTS (Noble Numbat) as base image
FROM ruby:3.4.1

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV RAILS_ENV=production
ENV NODE_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_LOG_TO_STDOUT=true

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    software-properties-common \
    build-essential \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    libsqlite3-dev \
    libpq-dev \
    libxml2-dev \
    libxslt1-dev \
    libcurl4-openssl-dev \
    libffi-dev \
    libyaml-dev \
    libgdbm-dev \
    libncurses5-dev \
    libtool \
    pkg-config \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Bundler
RUN gem install bundler

# Create a non-root user
RUN useradd -m -s /bin/bash rails

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install Ruby gems as root first
RUN bundle config set --local without 'development test' \
    && bundle install --jobs 4 --retry 3

# Copy the rest of the application
COPY . .

RUN curl -sLO https://github.com/tailwindlabs/tailwindcss/releases/download/v3.4.3/tailwindcss-linux-x64 \
  && mv tailwindcss-linux-x64 /usr/local/bin/tailwindcss && chmod +x /usr/local/bin/tailwindcss

# Set PATH so tailwindcss is available for non-root user
ENV PATH="/usr/local/bin:${PATH}"

# Create necessary directories
RUN mkdir -p tmp/pids tmp/sockets log

# Set proper permissions
RUN chmod +x bin/rails bin/docker-entrypoint

# Change ownership of the entire app directory to rails user
RUN chown -R rails:rails /app

# Change ownership of bundle directories to rails user
RUN chown -R rails:rails /usr/local/bundle

# Switch to rails user
USER rails

# Expose port
EXPOSE 3000

# Set entrypoint
ENTRYPOINT ["bin/docker-entrypoint"]

# Start the application
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
