# syntax=docker/dockerfile:1
# The app as one container: Rails + Puma, SQLite under /rails/storage (mount it), and the Hue
# listener thread started by Puma. Build with `docker build -t you-can-hue-better .`
ARG RUBY_VERSION=4.0.0
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Runtime packages: SQLite, jemalloc (less memory), curl for the healthcheck.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libsqlite3-0 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"
# jemalloc is enabled by bin/docker-entrypoint, which finds the library for the image's architecture.

# ---- build stage: gems and precompiled assets ----
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY . .

RUN bundle exec bootsnap precompile app/ lib/
# Assets need no secrets; a dummy key lets precompile run without the master key.
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# ---- final image ----
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run as a non-root user; the database and logs live under storage/ and log/.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 CMD curl -fsS http://localhost:3000/up || exit 1
CMD ["./bin/rails", "server"]
