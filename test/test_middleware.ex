# defmodule Test.MiddlewareTest do


# 	def process(_, state, opts=%{timeout: t}) when t > 100, do: error 

# 	def process(:in, state = %{request: %{args: a, headers: h} , response: resp, context: %{}, return: nil }, opts = %{ timeout: 30, access: :local}) do
# 		get_qs(state, :a, nil)
# 		state |> error 401, "Bad arguments"
# 	end


# 	def process(_, state), do: state
# end


# defmodule Test.Web, listen: "0.0.0.0", port: 9000 do
# 	webmodule Test.A
# 	webmodule Test.B
# 	webmodule Test.C, [access: :global]
# end

# defmodule Test.Web2, port: 9001, listen: "127.0.0.1" do
# 	webmodule Test.A
# 	webmodule Test.B
# 	webmodule Test.C, [access: :local]
# end


# defmodule Test.UrlsTest do
# 	defurl ["/a"], [ ] do
# 		def process(:in, state) do

# 		end
# 	end
 
#  	defchain "/", [Middleware1], Module2.Urls
# 	defurl "/a/[:chain]", Test.Modules.module, []
# 	defurl "/a/[:chain]/[:do]", Test.Modules.module, []

# 	defchain "/accounts/", [], Accounts.Urls

# end


# defmodule a do

# 	def a do
# 		def b do
# 		end
# 	end
# end
