from flask import Flask, jsonify

app = Flask(__name__)

users = [
    {"id": 1, "name": "John", "email": "john@example.com"},
    {"id": 2, "name": "Sarah", "email": "sarah@example.com"}
]

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

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
