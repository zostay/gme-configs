# ext-auth-oidc

## These instructions are probably apocrphyal...

1. Go to <https://oauth.com/> and register an OIDC client.
2. Create a file named oidc-client.yaml like the following:

```yaml
client_id: CLIENT_ID
client_secret: CLIENT_SECRET

login: USERNAME
passowrd: PASSWORD
```

Then run `go run ext-auth-oidc/main.go`, which will create a `load-c1.yaml` file.
