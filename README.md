Onion
=====

Basic usage
-----------

Import Onion

```
import Onion
```

Create Server:

```
defserver Server1, port: 9000 do
	...
end

```

Create handler

```
defhandler Route1 do 
	...
end
```

Add handler into server
```
defserver Server1, port: 9000 do
	handler Route1
end
```

Add route to handler
```
defhandler Route1 do 
	route "/", middlewares: [ ... ]
end
	
```

Create simple out middleware (put middleware upper Route1)
```
defmiddleware Out do
	def process(:in, state, opts) do
		state |> reply(200, opts)
	end
end
```

Set middleware to route in Route1
```
defhandler Route1 do 
	route "/", middlewares: [ Out.init("Hello World!") ]
end
	
```

All code (hello_world.ex):

```
import Onion

defmiddleware Out do
	def process(:in, state, opts) do
		state |> reply(200, opts)
	end
end

defhandler Route1 do 
	route "/", middlewares: [ Out.init("Hello World!") ]
end

defserver Server1, port: 9000 do
	handler Route1
end
```


Run server
```
Server1.run 
```


Try this
```
curl http://localhost:9000/
```

Enjoy!
