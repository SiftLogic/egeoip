%% @author Bob Ippolito <bob@redivi.com>
%% @copyright 2006 Bob Ippolito

-module(egeoip_sup).
-author('bob@redivi.com').

-behaviour(supervisor).

-define(DEFAULT_WORKERS, 20).

-export([start_link/0]).
-export([init/1]).
-export([worker/2, worker_names/0]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    File = case application:get_env(egeoip, dbfile) of
               {ok, Other} ->
                   Other;
               _ ->
                   city
           end,
    Processes = worker(tuple_to_list(worker_names()), File),
    {ok, {{one_for_one, 5, 300}, Processes}}.

worker_names() ->
    erlang:list_to_tuple(
      [erlang:list_to_atom("egeoip_"
                               ++ (erlang:integer_to_list(X - 1)))
         || X <- lists:seq(1,
                           case application:get_env(num_workers) of
                               {ok, Num} ->
                                   Num + 1;
                               _ ->
                                   ?DEFAULT_WORKERS + 1
                           end)]).

worker([], _File) ->
    [];
worker([Name | T], File) ->
    [{Name,
      {egeoip, start_link, [Name, File]},
      permanent, 5000, worker, [egeoip]} | worker(T, File)].
