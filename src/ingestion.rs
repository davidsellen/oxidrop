use axum::Json;
use serde_json::{Value, json};

pub async fn ingest(Json(payload): Json<Value>) -> Json<Value> {
    let payload_type = match &payload {
        Value::Null => "null",
        Value::Bool(_) => "boolean",
        Value::Number(_) => "number",
        Value::String(_) => "string",
        Value::Array(_) => "array",
        Value::Object(_) => "object",
    };

    let stamp = match payload_type {
        "object" => "crate-delivered",
        "array" => "batch-landed",
        _ => "tiny-drop",
    };

    tracing::info!(payload_type, "JSON payload received");

    tracing::debug!(
        payload = %payload,
        "Ingestion payload content"
    );

    Json(json!({
        "status": "received",
        "payloadType": payload_type,
        "stamp": stamp
    }))
}
