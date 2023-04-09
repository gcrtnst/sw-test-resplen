c_annouce_name = "[sw-test-resplen]"

g_active = false
g_port = nil
g_len = nil
g_req = nil

function onCustomCommand(full_message, user_peer_id, is_admin, is_auth, cmd, ...)
    if cmd ~= "?test" or user_peer_id < 0 then
        return
    end

    local args = {...}
    if #args ~= 1 then
        server.announce(c_annouce_name, "error: wrong number or arguments", user_peer_id)
        return
    end

    local port = tonumber(args[1], 10)
    if port == nil or port < 1 or 65535 < port then
        server.announce(c_annouce_name, "error: invalid port number", user_peer_id)
        return
    end

    if g_active then
        server.announce(c_annouce_name, "error: already running", user_peer_id)
        return
    end

    if not is_admin then
        server.announce(c_annouce_name, "error: permission denied", user_peer_id)
        return
    end

    g_active = true
    g_port = port
    g_len = 0
    httpGet()
end

function httpReply(port, req, resp)
    if not g_active or port ~= g_port or req ~= g_req then
        return
    end
    g_req = nil

    if #resp ~= g_len then
        local msg = string.format(
            (
                "error: response length mismatch\n" ..
                "expected_body_len=%d\n" ..
                "received_body_len=%d\n" ..
                "received_body=%q"
            ),
            g_len,
            #resp,
            resp
        )
        server.announce(c_annouce_name, msg)
        g_active = false
        g_port = nil
        g_len = nil
        return
    end

    g_len = g_len + 1
    httpGet()
end

function httpGet()
    if not g_active then
        return
    end

    local req = string.format("/?n=%d", g_len)
    server.httpGet(g_port, req)
    g_req = req

    server.announce(c_annouce_name, string.format("body_len=%d", g_len))
end