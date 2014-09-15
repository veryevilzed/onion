defmodule Onion.Middlewares do
	defmacro __using__(_opts) do
		quote location: :keep do
			defmacro defmiddleware name, opts \\ [], code do
				quote do
					defmodule unquote(name) do

						def init(args \\ []), do: {unquote(name), args}

						unquote(code)

						def process(_, args), do: args
						def process(_, args, _), do: args
					end
				end
 			end
		end
	end
end