from flask import Flask, jsonify

app = Flask(__name__)

products = [
    {"id": 1, "name": "Laptop", "price": 55000},
    {"id": 2, "name": "Mobile", "price": 25000},
    {"id": 3, "name": "Headphones", "price": 3000}
]

@app.route("/")
def home():
    return jsonify({"service": "Product Service", "status": "running"})

@app.route("/health")
def health():
    return jsonify({"status": "healthy"}), 200

@app.route("/products")
def get_products():
    return jsonify(products)

@app.route("/products/<int:product_id>")
def get_product(product_id):
    product = next((p for p in products if p["id"] == product_id), None)
    if product:
        return jsonify(product)
    return jsonify({"error": "Product not found"}), 404

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
