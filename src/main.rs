use axum::{
    Json, Router,
    routing::{get, post},
};
use serde::Deserialize;
use serde_json::{Value, json};
use tower_http::trace::{DefaultMakeSpan, DefaultOnRequest, DefaultOnResponse, TraceLayer};
use tracing::Level;
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() -> std::io::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .init();

    let app = Router::new()
        .route("/health", get(health))
        .route("/ingest", post(ingest))
        .layer(
            TraceLayer::new_for_http()
                .make_span_with(DefaultMakeSpan::new().level(Level::INFO))
                .on_request(DefaultOnRequest::new().level(Level::INFO))
                .on_response(DefaultOnResponse::new().level(Level::INFO)),
        );

    let listener = tokio::net::TcpListener::bind("127.0.0.1:8080").await?;

    tracing::info!(address = "127.0.0.1:8080", "Oxidrop started");

    axum::serve(listener, app).await
}

async fn health() -> &'static str {
    "Healthy"
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct IngestionRequest {
    event_type: String,
    order_id: u64,
}

async fn ingest(Json(payload): Json<IngestionRequest>) -> Json<Value> {
    tracing::info!(
        event_type = %payload.event_type,
        order_id = payload.order_id,
        "Ingestion payload received"
    );

    Json(json!({
        "status": "received"
    }))
}
