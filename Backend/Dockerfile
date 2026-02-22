# Build stage
FROM swift:5.9-jammy as build
WORKDIR /app
COPY Package.swift Package.resolved* ./
RUN swift package resolve
COPY Sources Sources
RUN swift build -c release

# Run stage
FROM swift:5.9-slim-jammy
WORKDIR /app
COPY --from=build /app/.build/release/App .
EXPOSE 8080
ENTRYPOINT ["./App"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
