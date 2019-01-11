# FYI

This is a backend for a Slack app that implements Etsy's immutable docs concept: https://codeascraft.com/2018/10/10/etsys-experiment-with-immutable-documentation/


## Build

```shell
$ nimble build
```


## Run

Set `PG_HOST`, `PG_USER`, `PG_PASSWORD`, and `PG_DB` env vars before running the app.

To run the app, execute the compiled binary:

```shell
$ ./fyi
```


## Docker

```shell
$ docker build -t fyi .
$ docker run -it --rm -e PG_HOST=host -e PG_USER=user -e PG_PASSWORD=password -e PG_DB=db -p 5000:5000 -v `pwd`/frontend/build:/usr/app/public fyi
$ docker run -it --rm -e PG_HOST=host -e PG_USER=user -e PG_PASSWORD=password -e PG_DB=db -p 5000:5000 -v ${PWD}/frontend/build:/usr/app/public fyi # pwsh
```
