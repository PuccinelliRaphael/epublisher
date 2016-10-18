%%%-------------------------------------------------------------------
%% @doc epublisher public API
%% @end
%%%-------------------------------------------------------------------

-module(epublisher_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

-define(C_ACCEPTORS,  100).
%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
    Routes    = routes(),
    Dispatch  = cowboy_router:compile(Routes),
    Port      = port(),
    TransOpts = [{port, Port}],
    ProtoOpts = #{env => #{dispatch => Dispatch}},
    {ok, _}   = cowboy:start_clear(http, ?C_ACCEPTORS, TransOpts, ProtoOpts),
    epublisher_sup:start_link().

%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================
routes() ->
    [
        {'_', [
            {"/", request_handler, []}
        ]}].

port() ->
    case os:getenv("PORT") of
        false ->
            {ok, Port} = application:get_env(cowboy_conf, port),
            Port;
        Other ->
            list_to_integer(Other)
    end.