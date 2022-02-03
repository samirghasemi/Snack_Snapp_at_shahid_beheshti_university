FROM bitwalker/alpine-elixir-phoenix:latest
WORKDIR /app
COPY ./mix.exs /app/
RUN mix deps.get
RUN mix compile
RUN mix do local.hex --force, local.rebar --force
COPY . /app
RUN mix deps.get
RUN mix compile
EXPOSE 4000
CMD ["mix","phx.server"]




