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
		state |> reply(200, opts) |> break!
	end
end

defmiddleware Out do
	def process(:in, state, opts) do
		state |> reply(200, opts) |> break!
	end
end



defhandler Route1, middlewares: [Error] do

	alls = [Out.init("Wortkd!")]

	route "/", middlewares: [Text.init("hh"), alls]
	route "/bb", middlewares: [Out.init("Wortkd!"), alls]
end

defserver Server1 do
	handler Route1
end


