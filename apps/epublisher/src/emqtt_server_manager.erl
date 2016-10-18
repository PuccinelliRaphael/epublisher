%%%-------------------------------------------------------------------
%%% @author raphael
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. Oct 2016 1:41 AM
%%%-------------------------------------------------------------------
-module(emqtt_server_manager).
-author("raphael").

%% API
-export([start_server_listener/0]).

%%
start_server_listener() ->
  Pid = self(),
  register(emqtt_server, Pid),
  server_listener().

%% Function
server_listener() ->
  receive
    {publish, Broker, Topic, Msg} -> spawn(fun() -> monitor_publisher(Broker, Topic, Msg, 2) end),
                                     server_listener()
  end.

%%
monitor_publisher(Hostname, Topic, Msg, N) ->
  io:format("connecting to the broker... ~n"),
  Pid = spawn(fun() -> init(Hostname, Topic, Msg) end),
  monitor(process, Pid),
  handle_notification(Pid, Hostname, Topic, Msg, N).

%%
handle_notification(_Pid, _Hostname, _Topic, _Msg, 0) -> io:format("Failed to Publish!");
handle_notification(Pid, Hostname, Topic, Msg, N) ->
  receive
    {'DOWN', _Ref, process, Pid, normal}  -> io:format("Published with Success!");
    {'DOWN', _Ref, process, Pid, crash}   -> monitor_publisher(Hostname, Topic, Msg, N-1);
    {'DOWN', _Ref, process, Pid, _Reason} -> io:format("Failed to Publish!")
    after 3000                            -> io:format("Time out!")
  end.

%% Function to initiate the module connecting to the broker and publishing to it
init(Host, Topic, Msg) ->
  try
      {ok, ClientID} = application:get_env(mqtt_conf, client_id),
      Pid = connect(Host, ClientID),
      io:format("connected to the broker ~n"),
      timer:sleep(100),
      publish(Pid, Topic, Msg),
      timer:sleep(100),
      disconnect(Pid)
  catch
      E:R  -> io:format("Reason for the crash: ~p~n", [{E,R}]), exit(crash)
  end .

%% Function to disconnect from the broker
disconnect(Pid) ->
  emqttc:disconnect(Pid).

%% Function to connect to the broker
connect(Host, ClientId) ->
  Id = list_to_binary(ClientId),
  {ok, Pid} = emqttc:start_link([{host, Host},
                                 {client_id, Id},
                                 {reconnect, 3},
                                 {logger, {console, info}}]),
  Pid.

%% Function to publish to the broker
publish(Pid, Topic, Msg) ->
  T = list_to_binary(Topic),
  M = list_to_binary(Msg),
  emqttc:publish(Pid, T, M).