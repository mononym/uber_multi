defmodule UberMulti do
  @moduledoc """
  UberMulti is a simple wrapper/helper for 'Multi.run/3' and 'Multi.run/5'.

  There are two differences when using UberMulti compared to the normal Multi methods. The first is the addition of the 'keys' argument. The keys provided in this argument are used in two ways. First, each key is used to try and extract a result from the list of previous changes in the execution of the multi. If a result is not found, the key is instead used as-is as the parameter. In this way you can mix and match between providing your own arguments and automatically fetching them from previous multi results.

  The second difference is in the function that will be run by the multi. Given that the changes list is being preprocessed into a list of parameters to pass to the function, it will not need to take in the list of changes as normal, but simply take in the list of parameters it expects to perform its function.

  So an UberMulti which uses the following function:
  '''
  def uber_cool_things(thing1, thing2) do
    {:ok, thing1 + thing2}
  end
  '''

  Might look like:
  '''
  UberMulti.run(multi, :add_things, [:get_thing1, :get_thing2], &uber_cool_things/2)
  '''

  Obviously this is very contrived, but shows how you can easily combine non-multi functions together without having to wrap all the calls yourself and manually extract the results for the next one in the chain.

  Another change is that the 'run' methods will also automatically wrap the responses from any methods they call that do not conform to the two element tuple response pattern. If a method returns '{:ok, term()}' or '{:error, term()}' the response will be used as is. Otherwise the response will be wrapped in a tuple like so: '{:ok, <response goes here>}'
  """

  alias Ecto.Multi

  @typedoc "An '%Ecto.Multi{}' struct. See 'Ecto.Multi' for detailed specs."
  @type multi :: struct()

  @typedoc "A name to tag the multi function with. Must be unique within a single multi chain."
  @type name :: term()

  @typedoc "One or more keys, with a single key optionally being in a list."
  @type keys :: key | [key]

  @typedoc "The key to extract the parameters from using the changes map, or a value to pass directly to the callback."
  @type key :: name | term()

  @typedoc "A callback function to call with the parameters extracted from the changes map."
  @type run :: function()

  @typedoc "A module to call a callback function on."
  @type m :: atom()

  @typedoc "A callback function to call."
  @type f :: atom()

  @typedoc "An optionally empty list of arguments to append to the extracted parameters before calling the callback function."
  @type args :: [] | [arg]

  @typedoc "The argument."
  @type arg :: term()

  @doc """
  Adds a function to run as part of the multi.

  The function should return either '{:ok, value}' or '{:error, value}' and will receive whatever arguments are specified by the passed in keys in order, rather than the changes so far as with a normal 'Ecto.Multi.run/3' call.

  If one of the provided keys cannot be found in the list of changes, it is instead inserted as-is as one of the parameters to the callback function. In this way you can mix and match between providing your own arguments and automatically fetching them from previous multi results.

  ## Examples

      > UberMulti.run(multi, :send_email, [:get_hot_news_items, :get_top_forum_post_headlines], fn(news, posts) ->
        ...do stuff...
      end)
      #Ecto.Multi{}

      Multi.new()
      |> Multi.run(:list_stars, fn(_) -> Astronomy.list_stars("Milky Way") end)
      |> UberMulti.run(:reverse, [:list_stars], &Enum.reverse/1)
      |> UberMulti.run(:cannon, [:reverse], &Astronomy.classify_stars/1)
      |> Repo.transaction()
  """
  @spec run(multi, name, keys, run) :: multi
  def run(multi, name, keys, run) do
    Multi.run(multi, name, fn changes ->
      extracted_args = extract_args(keys, changes)

      apply(run, extracted_args)
      |> maybe_wrap_response()
    end)
  end

  @doc """
  Adds a function to run as part of the multi.

  The function should return either '{:ok, value}' or '{:error, value}' and will receive whatever arguments are specified by the passed in keys, in order, prepended to the args passed in as the final argument. It will not receive the changes so far as with a normal 'Ecto.Multi.run/5' call.

  ## Examples

      > UberMulti.run(multi, :send_welcome_email, [:get_account_email], Emails, :send_welcome_email)
      #Ecto.Multi{}

  """
  @spec run(multi, name, keys, m, f, args) :: multi
  def run(multi, name, keys, module, function, args \\ []) do
    Multi.run(multi, name, fn changes ->
      extracted_args = extract_args(keys, changes)

      apply(module, function, extracted_args ++ args)
      |> maybe_wrap_response()
    end)
  end

  @spec maybe_wrap_response(response :: term) :: {:ok, term()} | {:error, term()}
  defp maybe_wrap_response(response) do
    if is_tuple(response) and tuple_size(response) == 2 and elem(response, 0) in [:ok, :error] do
      response
    else
      {:ok, response}
    end
  end

  @spec extract_args(keys :: term() | [term()], changes :: map()) :: [term()]
  defp extract_args(keys, changes) do
    keys = List.wrap(keys) |> Enum.reverse()
    Enum.reduce(keys, [], fn key, args ->
      if Map.has_key?(changes, key) do
        [Map.get(changes, key) | args]
      else
        [key | args]
      end
    end)
  end
end
