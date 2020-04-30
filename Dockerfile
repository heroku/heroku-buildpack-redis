ARG BUILD_IMAGE
ARG RUNTIME_IMAGE
FROM $BUILD_IMAGE AS builder

ARG STACK

# Emulate the platform where root access is not available
RUN useradd -d /app non-root-user
RUN mkdir -p /app /cache /env
RUN chown non-root-user /app /cache /env
USER non-root-user

COPY --chown=non-root-user . /buildpack
WORKDIR /app

# Sanitize the environment seen by the buildpack, to prevent reliance on
# environment variables that won't be present when run on the platform.
RUN env -i PATH=$PATH HOME=$HOME STACK=$STACK /buildpack/bin/detect /app
RUN env -i PATH=$PATH HOME=$HOME STACK=$STACK /buildpack/bin/compile /app /cache /env


FROM $RUNTIME_IMAGE
RUN useradd -d /app non-root-user
USER non-root-user
COPY --from=builder --chown=non-root-user /app /app
WORKDIR /app
