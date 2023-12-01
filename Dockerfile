FROM node:20-alpine as base

RUN apk update && apk upgrade --no-cache \
    && apk add --no-cache shadow \
    && npm i -g npm \
    && npm config -g set fund false

ENV API_DIR="/usr/src/api" \
    API_GROUP="api" \
    API_USER="api" \
    API_PORT=3000

ARG API_USER_ID=1000
ARG API_GROUP_ID=1000

RUN groupmod -g 1001 node \
  && usermod -u 1001 -g 1001 node

WORKDIR ${API_DIR}

RUN addgroup -g ${API_GROUP_ID} ${API_GROUP} \
    && adduser -u ${API_USER_ID} -G ${API_GROUP} -s /bin/sh -D ${API_USER} \
    && chown -R ${API_USER}:${API_GROUP} ${API_DIR}

USER ${API_USER}:${API_GROUP}

COPY --chown=${API_USER}:${API_GROUP} package*.json ./
RUN npm ci --quiet
COPY --chown=${API_USER}:${API_GROUP} . .
EXPOSE ${API_PORT}

FROM base as dev
ENV NODE_ENV=development
EXPOSE 9229
CMD ["npm", "run", "start:debug"]

FROM base as prod
ENV NODE_ENV=production
RUN npm run build && npm prune --production
CMD ["npm", "run", "start:prod"]
