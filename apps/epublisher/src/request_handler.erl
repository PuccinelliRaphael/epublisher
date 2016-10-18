%% Feel free to use, reuse and abuse the code in this file.

%% @doc GET echo handler.
-module(request_handler).

-export([init/2]).

init(Req0, Opts) ->
	Method = cowboy_req:method(Req0),
	#{broker := Broker, topic := Topic, msg := Msg} = cowboy_req:match_qs([{broker, [], undefined},{topic, [], undefined},
							     {msg, [], undefined}], Req0),
	Req = publish(Method, Broker, Topic, Msg, Req0),
	{ok, Req, Opts}.

publish(<<"GET">>, undefined, _, _, Req) ->
	cowboy_req:reply(400, #{}, <<"Missing broker parameter.">>, Req);
publish(<<"GET">>, _, _, undefined, Req) ->
	cowboy_req:reply(400, #{}, <<"Missing msg parameter.">>, Req);
publish(<<"GET">>, _, undefined, _, Req) ->
	cowboy_req:reply(400, #{}, <<"Missing topic parameter.">>, Req);
publish(<<"GET">>, Broker, Topic, Msg, Req) ->
	emqttt_server ! {publish, Broker, Topic, Msg},
	cowboy_req:reply(200, #{
	<<"content-type">> => <<"text/html; charset=utf-8">>}, gen_html(Broker, Topic, Msg), Req);
publish(_, _, _, _, Req) ->
	%% Method not allowed.
	cowboy_req:reply(405, Req).

gen_html(Broker, Topic, Msg) ->
	[<<"
	  <html>
	  <head>
	  <title>Message sent!</title>
	  </head>
	  <body>
	  Topic: <br />
	">>,
		Broker,
		<<"
	  <br />
	  Message: <br />
	">>,
	 Topic,
	 <<"
	  <br />
	  Message: <br />
	">>,
	 Msg,
	<<"
	  </body>
	  </html>
	">>].
