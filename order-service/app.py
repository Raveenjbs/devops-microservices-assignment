from flask import Flask, jsonify

app = Flask(__name__)

orders = [
    {"id": 1, "user_id": 1, "product_id": 1, "quantity": 1, "status": "confirmed"},
    {"id": 2, "user_id": 2, "product_id": 2, "quantity": 2, "status": "pending"}
]

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

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
