FROM bitwalker/alpine-elixir-phoenix:latest
WORKDIR /app
RUN mix do local.hex --force, local.rebar --force
COPY . /app/
RUN mix deps.get
RUN mix compile
CMD ['mix','phx.server']




