# syntax=docker/dockerfile:1
FROM ruby:3.3-slim AS base

# System dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      libyaml-dev \
      git \
      curl \
      postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Build args for non-root user
ARG UID=1000
ARG GID=1000

# Create non-root user
RUN groupadd -g ${GID} appuser && \
    useradd -m -u ${UID} -g ${GID} -s /bin/bash appuser

# Set working directory
WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock* ./
RUN bundle install --jobs 4 --retry 3

# Copy application code
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 3000

# Default command
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
