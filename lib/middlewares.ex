defmodule Onion.Middlewares do
	defmacro __using__(_opts) do
		quote location: :keep do
			defmacro defmiddleware name, opts \\ [], code do
				required = Dict.get opts, :required, []
				chain_type = case Dict.get opts, :chain_type, :only do
					:only_args -> :only_args
					1 -> :only_args
					:all -> :all
					2 -> :all
					_ -> :only
				end
				quote do
					defmodule unquote(name) do
						alias Onion.Args, as: Args

						defp break(args = %Args{middlewares: {a,b}}), do: %{ args | middlewares: {[], b} }
						defp break!(args = %Args{middlewares: {a,b}}), do: %{ args | middlewares: {[], []} }
						defp reply(args = %Args{ response: resp }, code, body), do: %{args | response: %{resp | code: code, body: body} }
						defp reply(args = %Args{ response: resp }, code, body, []), do: %{args | response: %{resp | code: code, body: body} }
						defp reply(args = %Args{ response: resp }, code, body, headers=[{_k,_v}|_t]), do: %{args | response: %{resp | code: code, body: body, headers: headers} }

						def init(args \\ []), do: {unquote(name), args}

						def required, do: unquote(required)
						def chain_type, do: unquote(chain_type)

						unquote(code)

						def process(_, state, _), do: state

						defoverridable [init: 1]
					end
				end
 			end

 			
		end
	end
end