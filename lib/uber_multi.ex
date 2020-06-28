defmodule UberMulti do
  @moduledoc """
  Provides the wrapper function for `Ecto.Multi`.

  There are two differences when using UberMulti compared to the normal Multi methods. The first is the addition of the
  'keys' argument. The keys provided in this argument are used in two ways. First, each key is used to try and extract
  a result from the list of previous changes in the execution of the Multi. If a result is not found, the key is
  instead used as-is as the parameter. In this way you can mix and match between providing your own arguments and
  automatically fetching them from previous Multi results.

  The second difference is in the function that will be run when the Multi is executed. Given that the changes list is
  being preprocessed into a list of parameters to pass to the function, it will not need to take in the list of changes
  as normal, but simply take in the parameters it expects to perform its function.

  So an UberMulti call which uses the following function:
  '''
  def add_things(thing1, thing2) do
    {:ok, thing1 + thing2}
  end
  '''

  Might look like:
  '''
  UberMulti.run(multi, :add_things, [:get_thing1, :get_thing2], &add_things/2)
  '''

  Obviously this is very contrived, but shows how you can easily combine non-multi and multi-designed functions without
  having to wrap all the calls yourself and manually extract the results for the next one in the chain.

  Another change is that the 'run' method will also automatically wrap the responses from any methods called that
  do not conform to the two element tuple response pattern. If a method returns '{:ok, term()}' or '{:error, term()}'
  the response will be used as is. By default any non-conforming response will be wrapped in a success tuple, see
  `run/4` for configuration options.
  """

  alias Ecto.Multi

  @typedoc "An '%Ecto.Multi{}' struct. See 'Ecto.Multi' for detailed specs."
  @type multi :: Ecto.Multi.t()

  @typedoc "A name to tag the multi function with. Must be unique within a single multi chain."
  @type name :: any()

  @typedoc "One or more keys, with a single key optionally being in a list."
  @type keys :: key | [key]

  @typedoc "The key to extract the parameters from using the changes map, or a value to pass directly to the callback."
  @type key :: any()

  @typedoc "A callback function to call with the parameters extracted from the changes map."
  @type run :: function()

  @typedoc "Whether or not to trust the result by default if it does not come wrapped in a result tuple."
  @type trust_result :: boolean() | fun()

  @doc """
  Adds a function to run as part of the Multi.

  By default, functions which do not wrap their results in success tuples have their results returned as a successful
  call. By providing `false` as the last argument this behaviour is changed and results will be wrapped in an error
  tuple instead. Optionally, for finer grained control, a function which takes the result and returns a tagged value
  can be passed in as the last parameter instead of a boolean value.

  ## Examples

      UberMulti.run(multi, :send_email, [:get_hot_news_items, :get_top_forum_post_headlines], fn(news, posts) ->
        ...do stuff...
      end)
      #Ecto.Multi{}

      Multi.new()
      |> UberMulti.run(:list_stars, ["Milky Way"], &Astronomy.list_stars/1)
      |> UberMulti.run(:reverse, [:list_stars], &Enum.reverse/1)
      |> UberMulti.run(:classify,
        [:reverse],
        &Astronomy.classify_stars/1,
        # Assume result is ok for previty
        & {:ok, Enum.all?(&1, fn star -> star.class in ~w"O B A F G K M")})
      |> Repo.transaction()
  """
  @spec run(multi, name, keys, run, trust_result) :: multi
  def run(multi, name, keys, run, trust_result \\ false) do
    Multi.run(multi, name, fn _, changes ->
      extracted_args = extract_args(keys, changes)

      apply(run, extracted_args)
      |> maybe_wrap_response(trust_result)
    end)
  end

  @spec maybe_wrap_response(response :: term, trust_result) ::
          {:ok, term()} | {:error, term()}
  defp maybe_wrap_response(response, fun) when is_function(fun), do: fun.(response)
  defp maybe_wrap_response({:ok, _} = response, _), do: response
  defp maybe_wrap_response({:error, _} = response, _), do: response
  defp maybe_wrap_response(response, true), do: {:ok, response}
  defp maybe_wrap_response(response, false), do: {:error, response}

  @spec extract_args(keys :: term() | [term()], changes :: map()) :: [term()]
  defp extract_args(keys, changes) do
    keys
    |> List.wrap()
    |> Enum.map(fn key ->
      Map.get(changes, key, key)
    end)
  end
end
