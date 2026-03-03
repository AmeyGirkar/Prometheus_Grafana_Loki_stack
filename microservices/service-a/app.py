from flask import Flask
import requests
import random
import time
import logging
import os

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("service-a")

SERVICE_B_URL = os.getenv("SERVICE_B_URL", "http://service-b:5000/process")

@app.route('/')
def index():
    logger.info("Service-A: Received request at root")
    return "Service-A is running"

@app.route('/start')
def start_requests():
    logger.info("Service-A: Starting random requests to Service-B")
    for i in range(10):
        try:
            # Simulate random log levels
            log_level = random.choice([logging.INFO, logging.WARNING, logging.ERROR])
            if log_level == logging.INFO:
                logger.info(f"Service-A: Sending request #{i}")
            elif log_level == logging.WARNING:
                logger.warning(f"Service-A: Delay in sending request #{i}")
            else:
                logger.error(f"Service-A: Potential issue before sending request #{i}")

            resp = requests.get(SERVICE_B_URL, timeout=2)
            logger.info(f"Service-A: Received response from Service-B: {resp.status_code} - {resp.text}")
        except Exception as e:
            logger.error(f"Service-A: Error communicating with Service-B: {e}")
        
        time.sleep(random.uniform(0.5, 2.0))
    
    return "Batch of requests completed"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
