# ext-auth-apikey

Configure API key authentication for service named `/auth`, but not required for service named `/noauth`.

Selection of services requiring API key auth is done for route named `httpbin`.

For

```
make setup-test-cluster TEST_CLUSTER_ARGS="--gloo-mesh --trust --httpbin"
```