defmodule Onion.Routes do
	defmacro __using__(_options) do
		quote location: :keep do
			defmacro defhandler name, opts \\ [], code do
				quote do 
					defmodule unquote(name) do
						
                        require Logger

                        routes = []
                        
                        unquote(code)
						macro_get_routes(routes)

                        defp required(middleware) do
                            case middleware do
                                {middle, _} -> middle.required
                                middle -> middle.required
                            end
                        end

                        defp chain_type(middleware) do
                            case middleware do
                                {middle, _} -> middle.chain_type
                                middle -> middle.chain_type
                            end
                        end

                        defp in_middles(middle, []), do: false
                        defp in_middles(middle, [head|tail]) do
                            case head do
                                {^middle, _} -> true
                                ^middle -> true
                                _ -> in_middles(middle, tail)
                            end
                        end

                        defp filter_middlewares([], res), do: res |> Enum.reverse
                        defp filter_middlewares([m={middleware, args}|middlewares], res) do
                            case {in_middles(middleware, res), chain_type(middleware)}   do
                                {true, :only}    ->   filter_middlewares(middlewares, res)
                                {true, :only_args} ->   
                                    case in_middles(m, res) do
                                        true  ->     filter_middlewares(middlewares, res)
                                        false ->     filter_middlewares(middlewares, [m | res])
                                    end
                                {_, :all}  ->      filter_middlewares(middlewares, [m | res])
                                {false, _} ->      filter_middlewares(middlewares, [m | res])
                            end
                        end
                        defp filter_middlewares([middleware|middlewares], res) do
                            case {in_middles(middleware, res), chain_type(middleware)}   do
                                {true, :only} ->   filter_middlewares(middlewares, res)                                
                                {true, _} ->       filter_middlewares(middlewares, res)
                                {_, :all} ->       filter_middlewares(middlewares, [middleware | res])
                                {false, _} ->      filter_middlewares(middlewares, [middleware | res])
                            end
                        end


                        defp required_middlewares(middlewares) when is_list(middlewares) do
                            Enum.map(middlewares, fn(x) -> required_middlewares x end)
                        end

                        defp required_middlewares(middleware) do
                            req = required middleware
                            case req do
                                [] -> [middleware]
                                req -> Enum.map(req, fn(x) -> required_middlewares x end) ++ [middleware]
                            end
                        end

						def get_routes do
							Enum.map _routes, fn({path, route, extra})->
                                middlewares = (Dict.get(unquote(opts), :middlewares, []) ++ Dict.get(extra, :middlewares, []))
                                                 |> filter_middlewares []
                                
                                # Достроим Requireds
                                middlewares = Enum.map(middlewares, fn(x)-> required_middlewares x end) |> List.flatten |> filter_middlewares []
                                IO.puts "MIDDLEWARES: #{inspect middlewares}"
                                #middlewares = middlewares |> required_middlewares |> List.flatten
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
                #_middlewares = Dict.get(opts, :middlewares, [])
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
                            %Args{response: %{code: code, headers: headers, body: body, cookies: cookies} } = process_in(args)
                            req = Enum.reduce(cookies, req, 
                                fn({name, value}, acc_req) -> :cowboy_req.set_resp_cookie(name, value, [path: "/"], acc_req);
                                ({name, path, value}, acc_req) -> :cowboy_req.set_resp_cookie(name, value, [path: path], acc_req)
                                ({name, path, value, timeout}, acc_req) -> :cowboy_req.set_resp_cookie(name, value, [path: path, max_age: timeout], acc_req)
                            end)
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