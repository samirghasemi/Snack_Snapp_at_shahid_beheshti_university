defmodule Snack.Repo do
  use Ecto.Repo,
    otp_app: :snack,
    adapter: ArangoXEcto.Adapter
end
