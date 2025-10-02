FROM debian:bullseye-slim AS flutter-build

ENV FLUTTER_ALLOW_ROOT="true"

# Install dependencies for Flutter
RUN apt-get update && \
    apt-get install -y curl git xz-utils && \
    curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.7.12-stable.tar.xz && \
    tar xf flutter_linux_3.7.12-stable.tar.xz && \
    git config --global --add safe.directory /flutter && \
    export PATH="$PATH:/flutter/bin" && \
    flutter --version

WORKDIR /app
COPY web /app

# Get dependencies and build web
RUN export PATH="$PATH:/flutter/bin" && \
    flutter pub get && \
    flutter build web

FROM python:3.12

# install dependencies
COPY requirements.txt /requirements.txt
COPY requirements_dev.txt /requirements_dev.txt

ENV OPENCV_VERSION="4.5.1"
ENV FLASK_ENV=development

# Install nginx and Python dependencies
RUN apt-get update && \
    apt-get install -y nginx && \
    rm -rf /var/lib/apt/lists/*

RUN pip install -r requirements.txt

# build swatch frontend
WORKDIR /opt/swatch/

COPY swatch swatch/
COPY --from=flutter-build /app/build/web frontend/
COPY migrations migrations/

COPY docker/rootfs /

# general docker

EXPOSE 4500

CMD ["python3", "-u", "-m", "swatch"]
