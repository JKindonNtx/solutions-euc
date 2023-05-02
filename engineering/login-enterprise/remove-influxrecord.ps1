curl --request POST http://influx.wsperf.nutanix.com:8086/api/v2/delete?org=Nutanix&bucket=Regression \
  --header 'b4yxMiQGOAlR3JftuLHuqssnwo-SOisbC2O6-7od7noAE5W1MLsZxLF7e63RzvUoiOHObc9G8_YOk1rnCLNblA==' \
  --header 'Content-Type: application/json' \
  --data '{
    "start": "2022-12-30T00:00:00Z",
    "stop": "2023-01-14T00:00:00Z",
    "predicate": "_measurement=\"173033_1n_A6.5.1.8_AHV_230V_230U_OW\""
  }'