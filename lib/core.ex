defmodule Onion.Core do
	defmacro __using__(_option) do
		quote location: :keep do
			defmacro defserver name, args \\ [], code do				

                config_name = Dict.get args, :config, :onion 
                config = Application.get_all_env config_name
                port = Dict.get args, :port, Dict.get(config, :port, 8080)
                listener_name = Dict.get args, :listener_name, Dict.get(config, :listener_name, :"listener_#{U.uuid}")
                max_acceptors = Dict.get args, :max_acceptors, Dict.get(config, :max_acceptor, 5000)
                max_connections = Dict.get args, :max_connections, Dict.get(config, :max_connection, 8192)
                max_keepalive = Dict.get args, :max_keepalive, Dict.get(config, :max_keepalive, 4096)
                backlog =  Dict.get args, :backlog, Dict.get(config, :backlog, 4096)
                middlewares = Dict.get args, :middlewares, []
                extra = Dict.get args, :extra, []

				quote do
					defmodule unquote(name) do						
						require Logger
						routes = []
						unquote(code)

						macro_get_compiled_routes(routes)

						def start do
                            Logger.metadata([name: unquote(listener_name)])
                            Logger.debug "Trying to HTTP Server #{unquote(listener_name)} started at port #{unquote(port)}..."
                            case :cowboy.start_http unquote(listener_name), unquote(max_acceptors), [
                                    {:port, unquote(port)}, 
                                    {:backlog, unquote(backlog)}, 
                                    {:max_connections, unquote(max_connections)}
                                ], [
                                {:env, 
                                    [
                                        {:dispatch, get_compiled_routes},
                                        {:max_keepalive, unquote(max_keepalive)}
                                    ]
                                }
                            ] do
                                res = {:ok, _} -> 
                                    Logger.info "HTTP Server #{unquote(listener_name)} started at port #{unquote(port)}"
                                    res
                                {_,reason} ->
                                    Logger.info "Failed to start http server #{unquote(listener_name)} at port #{unquote(port)}: reason is #{reason}"
                                    receive do after 1000 -> :ok end
                                    :erlang.halt
                            end
                        end
					end
				end
			end

			defmacro handler module, opts \\ [] do
				quote do
					routes = [unquote(module) | routes]
				end
			end

	        defmacro macro_get_compiled_routes(routes) do
	            quote unquote: false do
	                def get_compiled_routes do
	                	_routes = Enum.map unquote(Macro.escape routes), fn(route) ->
	                		apply(route, :get_routes, [])
	                	end
	                	IO.puts("Routes.2 #{inspect _routes |> List.flatten}")
	                    :cowboy_router.compile([_: _routes |> List.flatten ])
	                end 
	            end
	        end

	    end
	end
end