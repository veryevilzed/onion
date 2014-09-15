defmodule Onion.Routes do
	defmacro __using__(_options) do
		quote location: :keep do
			defmacro defhandler name, opts \\ [], code do
				quote do 
					defmodule unquote(name) do
						
                        routes = []
                        
                        unquote(code)
						macro_get_routes(routes)

						def get_routes do
							Enum.map _routes, fn({path, route, extra})->
                                middlewares = Dict.get(unquote(opts), :middlewares, []) ++ Dict.get(extra, :middlewares, []) |> List.flatten
                                extra = %{(extra |> Enum.into(%{})) | middlewares: middlewares} 
                                myname = case {Atom.to_string(route), Atom.to_string(unquote(name))} do
                                    {"Elixir." <> sname, "Elixir." <> rname} -> {path, :"Elixir.#{rname}.#{sname}", extra}
                                    {sname, _}-> {path, :"#{sname}", extra}
                                end
							end
						end
					end
				end
			end


			defmacro route path, opts do
                name = Dict.get(opts, :name, :"#{U.uuid}")
                #middlewares = Dict.get(opts, :middlewares, [])
				quote do

					routes = [{unquote(path), unquote(name), Enum.into(unquote(opts), %{})} | routes]
					defmodule unquote(name) do
						alias Onion.Args, as: Args
                        require Logger

                        def init({:tcp, :http}, req, extra) do
                            a = %Args{middlewares: {Dict.get(extra, :middlewares, []),[]}, cowboy: req} 
                                |> put_in([:request, :extra], extra)
                            {:ok, req, a}
                        end

                        defp take_request_middleware(args=%Args{ middlewares: {[],_} }), do: {:empty, args}
                        defp take_request_middleware(args=%Args{ middlewares: {[head|tail], m} }), do: {:ok, head, %{args | middlewares: {tail, [head|m]}}}

                        defp process_out(args=%Args{ middlewares: {_, []} }), do: args
                        defp process_out(args=%Args{ middlewares: {inm, [middleware|tail]} }) do
                            args = %{ args | middlewares: {inm, tail} }
                            args = case middleware do
                                {middleware, opts} -> apply(middleware, :process, [:out, args, opts])
                                middleware -> apply(middleware, :process, [:out, args, []])
                            end
                            process_out(args)
                        end
                        defp process_in(args) do
                            case take_request_middleware(args) do
                                {:ok, middleware, args} -> 
                                    args = case middleware do
                                        {middleware, opts} -> process_in(apply(middleware, :process, [:in, args, opts]))
                                        middleware ->         process_in(apply(middleware, :process, [:in, args, []]  ))
                                    end
                                {:empty, args} ->
                                  process_out(args)
                            end                       
                        end

                        def handle(req, args = %Args{middlewares: {a, b}} ) do
                            %Args{response: %{code: code, headers: headers, body: body} } = process_in(args)
                            {:ok, req} = :cowboy_req.reply(code, headers, body, req)
                            {:ok, req, args}
                        end

                        def terminate(_, _, _), do: :ok
					end
				end
			end #defmacro


            defmacro macro_get_routes(routes) do
                quote unquote: false do
                    defp _routes do
                        unquote(Macro.escape routes)
                    end 
                end
            end

		end #quote
	end #__using__
end