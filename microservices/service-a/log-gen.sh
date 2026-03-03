#!/bin/sh

# Service-A: Lightweight Log Generator
SERVICE_B_URL=${SERVICE_B_URL:-"http://service-b:80"}

echo "$(date) - [INFO] - Service-A: Starting log generation and requests to Service-B"

while true; do
    # Generate random log levels
    RANDOM_VAL=$(awk 'BEGIN{srand(); print int(rand()*10)}')
    
    if [ "$RANDOM_VAL" -lt 7 ]; then
        echo "$(date) - [INFO] - Service-A: Sending request to Service-B"
    elif [ "$RANDOM_VAL" -lt 9 ]; then
        echo "$(date) - [WARN] - Service-A: Delayed request execution"
    else
        echo "$(date) - [ERROR] - Service-A: System pressure detected before request"
    fi

    # Perform request to Service-B
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$SERVICE_B_URL" --max-time 2)
    
    if [ "$RESPONSE" = "200" ]; then
        echo "$(date) - [INFO] - Service-A: Successfully received 200 from Service-B"
    else
        echo "$(date) - [ERROR] - Service-A: Failed request to Service-B, Status: $RESPONSE"
    fi

    # Wait for random interval
    SLEEP_TIME=$(awk 'BEGIN{srand(); print rand()*2 + 0.5}')
    sleep "$SLEEP_TIME"
done
