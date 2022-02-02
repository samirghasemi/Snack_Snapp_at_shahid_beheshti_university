FROM bitwalker/alpine-elixir-phoenix:latest as builder
WORKDIR /app
RUN mix do local.hex --force, local.rebar --force
COPY . /app/
RUN mix deps.get
CMD ['mix','phx.server']




