FROM nimlang/nim:alpine as base
RUN mkdir -p /usr/app
WORKDIR /usr/app
COPY . /usr/app
ENV LANG=ru
RUN nimble build -d:release -d:lang=$LANG -y

FROM postgres:alpine
RUN mkdir -p /usr/app
WORKDIR /usr/app
COPY --from=base /usr/app /usr/app
CMD ["/usr/app/fyi"]
