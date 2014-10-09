import Onion

defmiddleware Out do
    def process(:in, state = %{response: %{code: 404}}, opts) do
        state |> reply(200, "Page not found !")
    end

end

defmiddleware Empty, required: [Out] do
end


defmiddleware Reply, required: [Out] do
    def process(:in, state, opts) do
        state |> reply(200, opts)
    end
end

defhandler Route1 do 

    route "/", middlewares: [ Reply.init("Hello World!") ]
    route "/[...]", middlewares: [ Empty ]
end

defserver Server1, port: 9000 do
    handler Route1
end

