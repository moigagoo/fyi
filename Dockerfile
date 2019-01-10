FROM nimlang/nim:alpine as base
RUN mkdir -p /usr/app
WORKDIR /usr/app
COPY . /usr/app
ENV LANG=ru
RUN nimble build -d:release -d:lang=$LANG -y

FROM postgres:alpine
COPY --from=base /usr/app/fyi /bin/fyi
CMD ["/bin/fyi"]
