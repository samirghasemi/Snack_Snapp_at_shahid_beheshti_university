defmodule Snack.Accounts.AuthPipeline do
    use Guardian.Plug.Pipeline,
      otp_app: :snack,
      error_handler: Snack.Accounts.ErrorHandler,
      module: Snack.Accounts.Guardian
#
#    # If there is a test_web.templates.session token, restrict it to an access token and validate it
#    plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
#    # If there is an authorization header, restrict it to an access token and validate it
#    plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
#    # Load the user if either of the verifications worked
#    plug Guardian.Plug.LoadResource, allow_blank: truex

    plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
    plug Guardian.Plug.EnsureAuthenticated
    plug Guardian.Plug.LoadResource
  end