# ext-auth-apikey-complicated

Configure API key authentication for service named `/ratings` and `/httpbin-ratings`, but not required for others, 
including `/productpage`, `/static`, and `/reviews`.

Selection of services requiring API key auth is done for routes labeled `apikey: required`.

For

```
make setup-test-cluster TEST_CLUSTER_ARGS="--gloo-mesh --trust --httpbin"
```