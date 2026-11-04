
from flask import Flask, jsonify, request, Response
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import time

app = Flask(__name__)

users = [
    {"id": 1, "name": "John", "email": "john@example.com"},
    {"id": 2, "name": "Sarah", "email": "sarah@example.com"}
]

# Prometheus metrics
REQUEST_COUNT = Counter(
    "user_service_http_requests_total",
    "Total HTTP requests handled by User Service",
    ["method", "endpoint", "status"]
)

REQUEST_LATENCY = Histogram(
    "user_service_http_request_duration_seconds",
    "HTTP request duration in seconds",
    ["method", "endpoint"]
)

@app.before_request
def start_timer():
    request.start_time = time.perf_counter()

@app.after_request
def record_metrics(response):
    if request.path != "/metrics":
        endpoint = request.url_rule.rule if request.url_rule else "unknown"

        REQUEST_COUNT.labels(
            method=request.method,
            endpoint=endpoint,
            status=str(response.status_code)
        ).inc()

        REQUEST_LATENCY.labels(
            method=request.method,
            endpoint=endpoint
        ).observe(time.perf_counter() - request.start_time)

    return response

@app.route("/")
def home():
    return jsonify({"service": "User Service", "status": "running"})

@app.route("/health")
def health():
    return jsonify({"status": "healthy"}), 200

@app.route("/users")
def get_users():
    return jsonify(users)

@app.route("/users/<int:user_id>")
def get_user(user_id):
    user = next((u for u in users if u["id"] == user_id), None)
    if user:
        return jsonify(user)
    return jsonify({"error": "User not found"}), 404

@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
