FROM nimlang/nim:alpine as base
RUN mkdir -p /usr/app
WORKDIR /usr/app
COPY . /usr/app
RUN nimble install -y

FROM postgres:alpine
COPY --from=base /usr/app/fyi /bin/fyi
CMD ["/bin/fyi"]
