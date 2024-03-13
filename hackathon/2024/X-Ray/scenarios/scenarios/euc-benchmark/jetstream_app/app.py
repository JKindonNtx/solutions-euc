from flask import Flask, request
from werkzeug.middleware.dispatcher import DispatcherMiddleware
from prometheus_client import make_asgi_app, Gauge, Counter, make_wsgi_app
import json
import logging
import sys

#
# Having a class for this is probably not necessary
# as it's basically acting as a collection for the Gauge()
# objects, but it could be useful in the future?
#
class JSResultCollector:
    def __init__(self, JSTestName: str):
        self.first = Gauge(f"{JSTestName}_first_score", f"First value published by JetStream Test {JSTestName}")
        self.worst = Gauge(f"{JSTestName}_worst_score", f"Worst value published by JetStream Test {JSTestName}")
        self.average = Gauge(f"{JSTestName}_average_score", f"Average value published by JetStream Test {JSTestName}")
        self.browser = Gauge(f"{JSTestName}_browser_score", f"This is the score JetStream displays on the browser while running {JSTestName}")


"""
Example of JSON JetStream2 is POSTing

{"run_id":null,"created":"2023-04-10T19:23:42.251213Z","data":{"JetStream2.0":{"metrics":{"Score":["Geometric"]},
"tests":{"cdjs":{"metrics":{"Score":{"current":[157.0371844853835]},"Time":["Geometric"]},
"tests":{"First":{"metrics":{"Time":{"current":[64]}}},"Worst":{"metrics":{"Time":{"current":[28.666666666666668]}}},
"Average":{"metrics":{"Time":{"current":[17.593220338983052]}}}}}}}},"ip_addr":"10.24.28.166"}

"""
def parse_metrics_from_post (post_data: str) -> dict:
    metric_keys = ['First', 'Worst', 'Average']
    ret = dict()

    for metric in metric_keys:
        #
        # in an ideal world, jetstream would always send First, Worst, Average in the JSON
        # but for some reason I have seen it not always do this correctly?
        # Try accessing the metric in the JSON blob sent over, if we get None then I guess
        # JetStream hosed us and we just submit NaN?
        #

        metric_value = post_data['data']['JetStream2.0']['tests']['cdjs']['tests'].get(metric)
        if metric_value:
            metric_value = metric_value['metrics']['Score']['current'][0]
            #
            # If we got a value out of the JSON blob, let's make sure it's not a "null"
            # JetStream has sent "null" in its JSON blob many times - in the case it's null
            # let's set the gauge to NaN
            #
            if not isinstance(metric_value, (bool, str)) and metric_value:
                ret[metric] = metric_value
            else:
                ret[metric] = "NaN"
        else:
            ret[metric] = "NaN"

    metric_value = post_data['data']['JetStream2.0']['tests']['cdjs']['metrics']['Score']['current'][0]
    if not isinstance(metric_value, (bool, str)) and metric_value:
        ret['browser'] = metric_value
    else:
        ret['browser'] = "NaN"
    return ret

def main() -> None:
    FLASK_PORT = 5555
    FLASK_IP_ADDR = "0.0.0.0"
    DEBUG = True
    SCRAPE_ENDPOINT = "/metrics"
    RESULTS_ENDPOINT = "/api/results"
    RESULT_COUNTER = Counter("js_result_count", "Overall count of results received from JetStream")

    logging.basicConfig(filename='jetstreamexporter.log', level=logging.DEBUG, format=f'%(asctime)s %(levelname)s %(name)s %(threadName)s : %(message)s')
    logging.getLogger().addHandler(logging.StreamHandler(sys.stdout))
    app = Flask(__name__)
    #https://github.com/prometheus/client_python#flask
    app.wsgi_app = DispatcherMiddleware(app.wsgi_app, {SCRAPE_ENDPOINT: make_wsgi_app()})

    cdjs_collectors = JSResultCollector("cdjs")

    @app.route(RESULTS_ENDPOINT, methods=['POST'])
    def add_result() -> str:
        post_data = request.json
        app.logger.info(f"Received POST: {post_data}")

        try:
            metrics = parse_metrics_from_post(post_data)
        except Exception as e:
            app.logger.exception(e)

        app.logger.info(f"Parsed POST: {metrics}")
        RESULT_COUNTER.inc()
        #
        # We're relying on the checks in parse_metrics_from_post
        # to ensure the below keys exist in the dictionary
        # but we might want to add error handling in the event
        # they do not...
        #
        if metrics.get('First'):
            cdjs_collectors.first.set(metrics['First'])

        if metrics.get('Worst'):
            cdjs_collectors.worst.set(metrics['Worst'])

        if metrics.get('Average'):
            cdjs_collectors.average.set(metrics['Average'])

        if metrics.get('browser'):
            cdjs_collectors.browser.set(metrics['browser'])

        return json.dumps({}), 200

    app.run(debug=DEBUG, host=FLASK_IP_ADDR, port=FLASK_PORT)


if __name__ == "__main__":
    main()

