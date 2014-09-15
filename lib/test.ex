import Onion


defhandler Route1, middlewares: [Test] do
	route "/", middlewares: [
		Non404.init(a: 5)
	]
end

defserver Server1 do
	handler Route1
end

defmiddleware Non404 do
	def process(:out, state, opts \\ []) do
		IO.puts "HELLO"
		state
			|> put_in([:response, :code], 200)
			|> put_in([:response, :body], "HELP: #{inspect opts}" )
	end
end

defmiddleware Text do
	def process(:out, state, opts \\ []) do
		IO.puts "Text"
		state |> put_in([:response, :body], "Text")
	end
end