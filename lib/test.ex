import Onion


defhandler Route1 do
	route "/", middlewares: [Non404]
end

defserver Server1 do
	handler Route1
end

defmiddleware Non404 do
	def process(:out, args) do
		IO.puts "HELLO"
		args 
			|> put_in([:response, :code], 200)
			|> put_in([:response, :body], "HELP")
	end
end