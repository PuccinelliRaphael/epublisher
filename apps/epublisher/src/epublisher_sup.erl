%%%-------------------------------------------------------------------
%% @doc epublisher top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(epublisher_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%====================================================================
%% API functions
%%====================================================================

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%====================================================================
%% Supervisor callbacks
%%====================================================================

%% Child :: {Id,StartFunc,Restart,Shutdown,Type,Modules}
init([]) ->
    process_flag(trap_exit, true),
    loop().

%%====================================================================
%% Internal functions
%%====================================================================

loop() ->
    Pid = spawn_link(fun() -> emqtt_server_manager:start_server_listener() end),
    receive
        {'EXIT', _From, shutdown} ->
            exit(shutdown); % will kill the child too
        {'EXIT', Pid, Reason} ->
            io:format("Process ~p exited for reason ~p~n",[Pid,Reason]),
            loop()
    end.