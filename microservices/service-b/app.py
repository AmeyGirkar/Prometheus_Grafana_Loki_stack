from flask import Flask, jsonify
import random
import logging

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("service-b")

@app.route('/process')
def process():
    # Simulate random outcomes and logs
    outcome = random.random()
    if outcome < 0.7:
        logger.info("Service-B: Successfully processed request")
        return jsonify({"status": "ok", "message": "Processed successfully"}), 200
    elif outcome < 0.9:
        logger.warning("Service-B: High latency detected during processing")
        return jsonify({"status": "slow", "message": "Processed with delay"}), 200
    else:
        logger.error("Service-B: Database connection failed during processing")
        return jsonify({"status": "error", "message": "Internal Server Error"}), 500

@app.route('/')
def index():
    logger.info("Service-B: Received request at root")
    return "Service-B is running"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
