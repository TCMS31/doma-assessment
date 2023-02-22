# syntax=docker/dockerfile:1

# ---------- build ----------------------------------------------------------
# Gems and the esbuild/tailwind bundles are produced here; none of the build
# toolchain survives into the runtime image.
FROM ruby:3.1.3-slim AS builder

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_PATH=/usr/local/bundle

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential git libpq-dev nodejs npm pkg-config && \
    npm install --global yarn@1.22.22 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /rails

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 && \
    rm -rf "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

COPY . .

# Bootsnap and Sprockets both want a writable cache; precompiling here keeps
# the runtime image read-only-friendly. SECRET_KEY_BASE is only needed so the
# production environment will boot for the asset task.
RUN SECRET_KEY_BASE=precompile-placeholder bundle exec rails assets:precompile && \
    bundle exec bootsnap precompile app/ lib/ && \
    rm -rf node_modules tmp/cache log/*

# ---------- runtime --------------------------------------------------------
FROM ruby:3.1.3-slim AS runtime

ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=1 \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_PATH=/usr/local/bundle \
    PORT=3000

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libpq5 postgresql-client && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd --system --gid 1000 rails && \
    useradd --system --uid 1000 --gid rails --create-home rails

WORKDIR /rails

COPY --from=builder --chown=rails:rails /usr/local/bundle /usr/local/bundle
COPY --from=builder --chown=rails:rails /rails /rails

USER rails:rails

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl --fail --silent http://127.0.0.1:${PORT}/up || exit 1

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
