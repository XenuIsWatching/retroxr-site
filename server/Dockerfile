# No dependencies, so no install step and nothing to audit but the one file.
FROM node:22-alpine

WORKDIR /app
COPY registry.mjs ./

# Never root. This process is reachable from the open internet and parses JSON
# from strangers.
USER node

EXPOSE 8080
CMD ["node", "registry.mjs"]
