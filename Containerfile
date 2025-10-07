FROM docker.io/library/node:20-alpine AS assets
WORKDIR /build
COPY package.json vite.config.js ./
COPY app/assets ./app/assets
RUN npm install && npm run build

FROM docker.io/library/ruby:3.3-alpine AS backend
WORKDIR /app
COPY Gemfile ./

RUN apk add --no-cache build-base gettext && gem install bundler && bundle install
COPY . .

COPY --from=assets /build/public/assets ./public/assets

RUN apk add --no-cache nginx

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9292

ENTRYPOINT ["/entrypoint.sh"]
