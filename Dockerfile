# Stage 1: Compile the application
FROM rust:1-slim-bookworm AS build

WORKDIR /app

COPY Cargo.toml Cargo.lock ./
COPY src ./src

RUN cargo build --release --locked

# Stage 2: Run the application
FROM debian:bookworm-slim AS runtime

WORKDIR /app

COPY --from=build /app/target/release/oxidrop /app/oxidrop

ENV BIND_ADDRESS=0.0.0.0:8080
ENV RUST_LOG=info

USER 10001:10001

EXPOSE 8080

ENTRYPOINT ["/app/oxidrop"]