use axum::{
    Router,
    routing::{get, post},
};
use tower_http::trace::{DefaultMakeSpan, DefaultOnRequest, DefaultOnResponse, TraceLayer};
use tracing::Level;
use tracing_subscriber::EnvFilter;
mod ingestion;

#[tokio::main]
async fn main() -> std::io::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .init();

    let app = Router::new()
        .route("/health", get(health))
        .route("/ingest", post(ingestion::ingest))
        .layer(
            TraceLayer::new_for_http()
                .make_span_with(DefaultMakeSpan::new().level(Level::INFO))
                .on_request(DefaultOnRequest::new().level(Level::INFO))
                .on_response(DefaultOnResponse::new().level(Level::INFO)),
        );

    let address = std::env::var("BIND_ADDRESS").unwrap_or_else(|_| "127.0.0.1:8080".to_string());

    let listener = tokio::net::TcpListener::bind(&address).await?;

    tracing::info!(
        address = %address,
        "Oxidrop started"
    );

    axum::serve(listener, app).await
}

async fn health() -> &'static str {
    "Healthy"
}
