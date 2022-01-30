defmodule Snack.Repo do
  use Arango.Repo,
  otp_app: :snack,
  collections: ["urls" , "alerts" , "logs" , "users"]
end