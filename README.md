# EXPLO HIVE Service

This repository holds EXPLO's utility libraries + functions for HIVE. This
includes the `HiveService` module, which holds functions for sending,
receiving, and searching HIVE atoms against a HIVE server, and the `HiveAtom`
module, which holds convenience functions and a struct definition of a Hive
Atom.

## Installation

The package can be installed by adding `hive_service` to your list of dependencies in
`mix.exs`:

```elixir
def deps do
  [
    {:hive_service, git: "bitbucket.org:explo/hive-service.git"},
  ]
end
```

## Setup

If you're using `HiveService`, you'll very likely want to set the following config var in your application:

    config :explo,
      hive_api_token: "your token",

These configuration variables can alternatively be set as environment variables in all-caps eg `export HIVE_API_TOKEN="mytoken"` .

