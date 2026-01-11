#!/bin/bash

docker run -p 3005:3005 \
  -e DATABASE_URL="postgresql://zinpainghtet:test1234@host.docker.internal:5432/testserver?schema=public" \
  express-backend
