from flask import Flask, render_template
import socket

app = Flask(__name__)


@app.route("/")
def home():
    return render_template("index.html")


@app.route("/health")
def health():
    return {
        "status": "healthy",
        "app": "Spark"
    }


@app.route("/api/info")
def info():
    return {
        "app": "Spark",
        "version": "1.0.0",
        "hostname": socket.gethostname()
    }


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)