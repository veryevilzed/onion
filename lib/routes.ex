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

                        use Onion.Requireds

                        def get_routes do
                            Enum.map(_routes, fn({path, route, extra})->
                                middlewares = (Dict.get(unquote(opts), :middlewares, []) ++ Dict.get(extra, :middlewares, []))
                                
                                # Достроим Requireds
                                middlewares = Enum.map(middlewares, fn(x)-> required_middlewares x end) |> List.flatten |> filter_middlewares []
                                extra = %{(extra |> Enum.into(%{})) | middlewares: middlewares} 
                                myname = case {Atom.to_string(route), Atom.to_string(unquote(name))} do
                                    {"Elixir." <> sname, "Elixir." <> rname} -> {path, :"Elixir.#{rname}.#{sname}", extra}
                                    {sname, _}-> {path, :"#{sname}", extra}
                                end
                            end) |> Enum.reverse
                        end
                    end
                end
            end


            defmacro route path, opts do
                name = Dict.get(opts, :name, :"#{Onion.Utils.uuid4()}")
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

            defmacro polling path, opts do
                name = Dict.get(opts, :name, :"#{Onion.Utils.uuid4()}")
                timeout = Dict.get(opts, :timeout, 5000)
                chunked = Dict.get(opts, :chunked, false)
                chunked_headers = Dict.get(opts, :chunked_headers, [])
                module = Dict.get(opts, :loop, nil)
                quote do

                    routes = [{unquote(path), unquote(name), Enum.into(unquote(opts), %{})} | routes]
                    defmodule unquote(name) do
                        alias Onion.Args, as: Args
                        require Logger

                        def init({:tcp, :http}, req, args) do
                            pid = elem(req, 4)
                            state = %Args{request: %{extra: Dict.put(args, :pid, pid)}, cowboy: req,
                                middlewares: {Dict.get(args, :middlewares, []),[]}} 
                                |> process_in
                            {:ok, req} = case unquote(chunked) do
                                true -> :cowboy_req.chunked_reply(200, unquote(chunked_headers), req)
                                _ -> {:ok, req}
                            end
                            task = spawn fn -> 
                                Keyword.has_key?(unquote(module).__info__(:functions), :begin) && apply(unquote(module), :begin, [state])
                                apply(unquote(module), :loop, [state, nil])
                            end
                            state = put_in(state, [:response, :extra, :pid], task)
                            {:loop, req, state, unquote(timeout), :hibernate}
                        end

                        def info({:done, _state}, req, state) when unquote(chunked) == false do
                            %Args{response: %{code: code, headers: headers, body: body}} = process_out(_state)
                            {:ok, req} = :cowboy_req.reply(code, headers, body, req)
                            {:ok, req, state}
                        end
                        def info({:done, _}, req, state), do: {:ok, req, state}
                        def info({:chunk, _state}, req, state) when unquote(chunked) == true do
                            %Args{response: %{body: body}} = process_out(_state)
                            :ok = :cowboy_req.chunk(body, req)
                            {:loop, req, state, :hibernate}
                        end
                        def info({:chunk, _}, req, state), do: {:loop, req, state, :hibernate}

                        defp take_request_middleware(args=%Args{ middlewares: {[],_} }), do: {:empty, args}
                        defp take_request_middleware(args=%Args{ middlewares: {[head|tail], m} }), do: {:ok, head, %{args | middlewares: {tail, [head|m]}}}

                        defp process_in(args) do
                            case take_request_middleware(args) do
                                {:ok, middleware, args} ->
                                    args = case middleware do
                                        {middleware, opts} -> process_in(apply(middleware, :process, [:in, args, opts]))
                                        middleware ->         process_in(apply(middleware, :process, [:in, args, []]  ))
                                    end
                                {:empty, args} -> args
                            end
                        end
                        defp process_out(args=%Args{ middlewares: {_, []} }), do: args
                        defp process_out(args=%Args{ middlewares: {inm, [middleware|tail]} }) do
                            args = %{ args | middlewares: {inm, tail} }
                            args = case middleware do
                                {middleware, opts} -> apply(middleware, :process, [:out, args, opts])
                                middleware -> apply(middleware, :process, [:out, args, []])
                            end
                            process_out(args)
                        end

                        def terminate(_, _, state = %{response: %{extra: %{pid: task}}}) do 
                            if Keyword.has_key?(unquote(module).__info__(:functions), :done), do: 
                                apply(unquote(module), :done, [state, task])
                            Process.exit(task, :kill)
                            :ok
                        end
                        def terminate(_, _, state) do 
                            if Keyword.has_key?(unquote(module).__info__(:functions), :done), do: 
                                apply(unquote(module), :done, [state, nil])
                            :ok
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