# ------------------------------------------------------------
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# ------------------------------------------------------------

import time
import requests
import os

dapr_port = os.getenv("DAPR_HTTP_PORT", 3500)
dapr_host = os.getenv("DAPR_HTTP_HOST", "eeeeeeee")
dapr_url = "http://{}:{}/v1.0/invoke/nodeapp/method/neworder".format(dapr_host, dapr_port)

n = 0
while True:
    n += 1
    message = {"data": {"orderId": n}}

    try:
        response = requests.post(dapr_url, json=message)
    except Exception as e:
        print(e)

    time.sleep(1)
