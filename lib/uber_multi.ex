defmodule UberMulti do
  @moduledoc """
  Documentation for UberMulti.
  """

  alias Ecto.Multi

  @doc """
  Adds a function to run as part of the multi.

  The function should return either '{:ok, value}' or '{:error, value}' and will receive whatever arguments are specified by the passed in keys in order, rather than the changes so far as with a normal 'Ecto.Multi.run/3' call.

  ## Examples

      > UberMulti.run(multi, :send_email, [:get_hot_news_items, :get_top_forum_post_headlines], fn(news, posts) ->
        ...do stuff...
      end)
      #Ecto.Multi{}

  """
  def run(multi, name, keys, run) do
    Multi.run(multi, name, fn changes ->
      args =
        Enum.reduce(keys, [], fn key, list ->
          [Map.get(changes, key)] ++ list
        end)
        |> Enum.reverse()

      apply(run, args)
    end)
  end

  @doc """
  Adds a function to run as part of the multi.

  The function should return either '{:ok, value}' or '{:error, value}' and will receive whatever arguments are specified by the passed in keys, in order, prepended to the args passed in as the final argument. It will not receive the changes so far as with a normal 'Ecto.Multi.run/5' call.

  ## Examples

      > UberMulti.run(multi, :send_welcome_email, [:get_account_email], Emails, :send_welcome_email)
      #Ecto.Multi{}

  """
  def run(multi, name, keys, module, function, args \\ []) do
    Multi.run(multi, name, fn changes ->
      extracted_args =
        Enum.reduce(keys, [], fn key, list ->
          [Map.get(changes, key)] ++ list
        end)
        |> Enum.reverse()

      apply(module, function, extracted_args ++ args)
    end)
  end
end
