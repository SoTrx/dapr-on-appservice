# ------------------------------------------------------------
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# ------------------------------------------------------------

import time
import requests
import os

dapr_port = os.getenv("MPROC_DAPR_HTTP_PORT", 3500)
dapr_host = os.getenv("MPROC_DAPR_HTTP_HOST", "localhost")
node_app_id = os.getenv("NODE_APP_ID", "nodeapp")
dapr_url = "http://{}:{}/v1.0/invoke/{}/method/neworder".format(dapr_host, dapr_port, node_app_id)

n = 0
while True:
    n += 1
    print("SENDING MESSGAGE \n")
    message = {"data": {"orderId": n}}

    try:
        response = requests.post(dapr_url, json=message)
        print("MESSAGE SENT \n")
    except Exception as e:
        print(e)

    time.sleep(1)
