
from flask import Flask, jsonify, request, Response
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import time

app = Flask(__name__)

orders = [
    {"id": 1, "user_id": 1, "product_id": 1, "quantity": 1, "status": "confirmed"},
    {"id": 2, "user_id": 2, "product_id": 2, "quantity": 2, "status": "pending"}
]

# Prometheus metrics
REQUEST_COUNT = Counter(
    "order_service_http_requests_total",
    "Total HTTP requests handled by Order Service",
    ["method", "endpoint", "status"]
)

REQUEST_LATENCY = Histogram(
    "order_service_http_request_duration_seconds",
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
    return jsonify({"service": "Order Service", "status": "running"})

@app.route("/health")
def health():
    return jsonify({"status": "healthy"}), 200

@app.route("/orders")
def get_orders():
    return jsonify(orders)

@app.route("/orders/<int:order_id>")
def get_order(order_id):
    order = next((o for o in orders if o["id"] == order_id), None)
    if order:
        return jsonify(order)
    return jsonify({"error": "Order not found"}), 404

@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
