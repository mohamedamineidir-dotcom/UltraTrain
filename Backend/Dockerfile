# Build stage
FROM swift:5.9-jammy AS build
WORKDIR /build
COPY Package.swift Package.resolved* ./
RUN swift package resolve
COPY Sources Sources
RUN swift build -c release

# Run stage
FROM ubuntu:jammy
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get -q install -y \
      ca-certificates \
      tzdata \
      libcurl4 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /usr/lib/swift/linux/lib*.so* /usr/lib/swift/linux/
COPY --from=build /build/.build/release/App .
ENV LD_LIBRARY_PATH=/usr/lib/swift/linux
EXPOSE 8080
CMD ["./App", "serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
