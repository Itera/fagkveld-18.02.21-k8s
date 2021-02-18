FROM hayd/alpine-deno:1.7.2

EXPOSE 8090

WORKDIR /app

USER deno

COPY . .

ENV SECRET=""

CMD ["run", "--allow-net", "--allow-read", "--allow-env", "main.ts"]