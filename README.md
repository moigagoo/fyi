# FYI

This is a backend for a Slack app that implements Etsy's immutable docs concept: https://codeascraft.com/2018/10/10/etsys-experiment-with-immutable-documentation/


# Build

```shell
$ nimble build
```

# Run

Set `PG_HOST`, `PG_USER`, `PG_PASSWORD`, and `PG_DB` env vars before running the app.

To run the app, execute the compiled binary:

```shell
$ ./fyi
```
