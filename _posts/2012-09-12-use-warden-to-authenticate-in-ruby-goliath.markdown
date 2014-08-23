---
layout: post
title: " Goliath Authenticate with Warden"
date:   2012-09-12 02:17:24
---

[Goliath](https://github.com/postrank-labs/goliath) is a high performance asynchronous concurrent Rack server, based on Ruby EventMachine, with WebSocket support built in. I've tried to use Goliath to build a chat room, absolutely with user authentication, so [Warden](http://wiki.github.com/hassox/warden) comes.

Warden strategy
---------------

Warden is a brilliant gem, with simple but detailed documents. Follow the [wiki](https://github.com/hassox/warden/wiki/Strategies) I defined the basic password strategy as below.

```ruby
Warden::Strategies.add(:password) do
  def authenticate!
    user = User.authenticate(env.params['email'], env.params['password'])
    user.nil? ? fail!('FAIL TO AUTHENTICATE!') : success!(user)
  end
end
```
    
Then I can choose when to authenticate the user by the `REQUEST_PATH` with a custom middleware named Authentication. 

```ruby
class Authentication
  def initialize(app)
    @app = app
  end

  def call(env)
    case env['REQUEST_PATH']
    when '/signout'
      env['warden'].logout
      [200, {}, 'Logged out']
    when '/signin'
      if env['REQUEST_METHOD'] == 'POST'
        env['user'] = env['warden'].authenticate!
        return [302, {'location' => '/'}, self] if env['user']
      end
      @app.call(env)
    else
      env['user'] = env['warden'].authenticate!
      @app.call(env)
    end
  end
end
```

At last, it's time to use the Authentication in my Goliath WebSocket chat room.

```ruby
class Chat < Goliath::WebSocket
  use Goliath::Rack::Params
  use Rack::Session::Cookie, :key => '_chat_goliath',
    :secret => BCrypt::Password.create(Time.now)
  use Warden::Manager, default_strategies: :password,
    failure_app: Proc.new { |env| [302, {'location' => '/signin'}, self] }
  use Authentication
end 
```

Thanks to Ruby's beautiful syntax, the code is just self explained.


Troubleshooting
---------------

Nothing will be so lucky. 

At first, I found [Goliath::WebSocket can't handle POST requests](https://github.com/postrank-labs/goliath/issues/199). If I want to sign in with a form to post email and password, I got an error: 

	undefined method `handler' for #<Goliath::Env:0x0000000229e350>
    
Then I tried to create two different Goliath API, one for HTTP and one for WebSocket. Guess what? [Goliath 1.0 will not have a router](https://groups.google.com/forum/#!msg/goliath-io/SZxl78BNhUM/WaCoM-U3GFIJ), so I can't do anything like `map '/signin', Authentication`.

No road leads to Rome, I can build my own one. Just override the `on_body` method of `Goliath::WebSocket`

```ruby
class Chat < Goliath::WebSocket
  def on_body(env, data)
    if env.respond_to?(:handler)
      env.handler.receive_data(data)
    else
      env['params'] = Rack::Utils.parse_query(data)
    end
  end
end
```

Finally, I got the Goliath to work. It's a bit harder to handle Goliath than Sinatra or Cramp, because it's an app server more than an app framework. But it deserved.
