import Onion

defmiddleware Error do
	def process(:out, state, opts) do
		state |> reply 500, "ERROR" 
	end	
end

defmiddleware Non404 do
	def process(:out, state, opts) do
		state |> put_in([:response, :code], 500)	
	end

end

defmiddleware Text do
	def process(:in, state, opts) do
		#state |> put_in([:response, :body], "Text [#{inspect opts}]")
		state |> reply(200, opts) |> break!
	end
end

defmiddleware Out do
	def process(:in, state, opts) do
		state |> reply(200, opts) |> break!
	end
end


defhandler Route1, middlewares: [Error] do
	route "/", middlewares: [Text.init("hh")]
	route "/bb", middlewares: [Out.init("Wortkd!")]
end

defserver Server1 do
	handler Route1
end


