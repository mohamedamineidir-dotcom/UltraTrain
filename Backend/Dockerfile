# Build stage
FROM swift:5.9-jammy as build
WORKDIR /app
COPY Package.swift Package.resolved* ./
RUN swift package resolve
COPY Sources Sources
RUN swift build -c release --static-swift-stdlib

# Run stage
FROM ubuntu:jammy
RUN apt-get update && apt-get install -y \
    libcurl4 \
    libxml2 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /app/.build/release/App .
ENV SWIFT_BACKTRACE=enable=yes,sanitize=yes,threads=all
EXPOSE 8080
ENTRYPOINT ["./App"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
