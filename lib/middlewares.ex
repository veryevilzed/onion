defmodule Onion.Middlewares do
	defmacro __using__(_opts) do
		quote location: :keep do
			defmacro defmiddleware name, opts \\ [], code do
				quote do
					defmodule unquote(name) do
						
						unquote(code)

						def process(_, args), do: args
					end
				end
 			end
		end
	end
end