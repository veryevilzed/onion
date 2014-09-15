defmodule Onion.Middlewares do
	defmacro __using__(_opts) do
		quote location: :keep do
			defmacro defmiddleware name, opts \\ [], code do
				quote do
					defmodule unquote(name) do
						alias Onion.Args, as: Args

						defp break(args = %Args{middlewares: {a,b}}), do: %{ args | middlewares: {[], b} }
						defp break!(args = %Args{middlewares: {a,b}}), do: %{ args | middlewares: {[], []} }
						defp reply(args = %Args{ response: resp }, code, body), do: %{args | response: %{resp | code: code, body: body} }
						defp reply(args = %Args{ response: resp }, code, body, []), do: %{args | response: %{resp | code: code, body: body} }
						defp reply(args = %Args{ response: resp }, code, body, headers=[{_k,_v}|_t]), do: %{args | response: %{resp | code: code, body: body, headers: headers} }

						def init(args \\ []), do: {unquote(name), args}


						unquote(code)

						def process(_, state, _), do: state



					end
				end
 			end

 			
		end
	end
end