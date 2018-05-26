# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :photoshare,
  ecto_repos: [Photoshare.Repo]

# Configures the endpoint
config :photoshare, Photoshare.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "pKkSEhMamyTw1QtrS/gmzL4JvlibKfIU1JDwbu1gwuUEDwCPaBme/0o3K5Qhhx98",
  render_errors: [view: Photoshare.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Photoshare.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :ex_aws, 
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role],
  region: "us-west-2"
  # s3: [ 
  #  scheme: "https://", 
  #  host: "vphotoshare.s3.amazonaws.com", 
  #  region: "us-west-2" 
  # ]

config :ex_aws, :hackney_opts,
  follow_redirect: true,
  recv_timeout: 30_000

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
