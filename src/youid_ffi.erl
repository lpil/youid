-module(youid_ffi).
-export([mac_address/0]).

mac_address() ->
    case inet:getifaddrs() of
        {ok, Ifs} -> mac_address(Ifs);
        _ -> {error, nil}
    end.

mac_address(Ifs) ->
    case Ifs of
        [] -> {error, nil};
        [{_Name, Props} | Rest] ->
            case proplists:get_value(hwaddr, Props) of
                undefined -> mac_address(Rest);
                [] -> mac_address(Rest);
                Ints ->
                    case lists:all(fun(X) -> X =/= 0 end, Ints) of
                        true -> erlang:list_to_binary(Ints);
                        false -> mac_address(Rest)
                    end
            end
    end.
