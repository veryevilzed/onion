defmodule Onion.Requireds do
    defmacro __using__(_option) do
        quote location: :keep do

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
            
        end
    end
end