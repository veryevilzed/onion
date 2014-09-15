defmodule Onion do
	use Onion.Core
	use Onion.Routes
	use Onion.Middlewares
end

defmodule Onion.Args do
	@derive [Access]
	defstruct [ 
		cowboy: nil, 
		middlewares: {[],[]},
		request: %{ 
			extra: %{}  
		}, 
		response: %{
			code: 404, 
			type: :error, 
			body: "not implemented", 
			headers: [{"content-type", "text/plain"}], 
			extra: %{}
		}, 
		context: %{}, 
		extra: %{}]
end
