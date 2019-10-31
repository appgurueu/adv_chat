

local socket = require("socket")
function set_socket(sock)
    socket=sock
    build_bridge = (socket and build_socket_bridge) or build_file_bridge
    set_socket=nil
end

local os_execute = os.execute
function set_os_execute(os_exec)
    os_execute = os_exec
    set_os_execute = nil
end

local ping_timeout = 5

function build_socket_bridge(name, logs)
    local server = socket.tcp()
    server:bind("*", 0)
    server:settimeout(5)
    local ip, port = server:getsockname()
    local logs=logs or minetest.get_worldpath().."/bridges/"..name.."/logs.txt"
    minetest.mkdir(minetest.get_worldpath().."/bridges/"..name)
    file_ext.create_if_not_exists(logs, "")
    minetest.register_on_shutdown(function()
        server:close()
    end)

    local self = {
        info={name=name, server=server, ip=ip, port=port},
        serve=function() end
    }

    function self.start(process)
        os_execute(process:format("", tostring(port), logs))
        self.client = server:accept()
        self.start=nil
    end
        
    function self.write(line)
        self.client:send(line.."\n")
    end

    function self.listen(line_consumer)
        local status, err_msg=server:listen()
        if status ~= 1 then
            minetest.request_shutdown("adv_chat: "..name..": socket error: "..err_msg)
        end
        minetest.register_globalstep(function()
            local available = socket.select({self.client}, nil, 0)
            if next(available) then
                local line, error = self.client:receive("*l")
                if not error then
                    if string_ext.starts_with(line, "[KIL]") then
                        minetest.request_shutdown("adv_chat: "..name..": process terminated: "..line:sub(6))
                    else
                        line_consumer(line)
                    end
                elseif error=="closed" then
                    minetest.request_shutdown("adv_chat: "..name..": socket closed")
                end
            end
        end)
    end
    
    return self
end

function build_file_bridge(name, input, output, logs)
    file_ext.process_bridge_build(name, input, output, logs)
    local self = {
        info={name=name, ref=file_ext.process_bridges[name]},
        serve=function()
            return file_ext.process_bridge_serve(name)
        end,
        write=function(line)
            return file_ext.process_bridge_write(name, line)
        end,
        listen=function(line_consumer)
            function consumer(line)
                if string_ext.starts_with(line, "[PIN]") then
                    self.last_ping = minetest.get_gametime()
                elseif string_ext.starts_with(line, "[KIL]") then
                    minetest.request_shutdown("adv_chat: "..name..": process terminated: "..line:sub(6))
                else
                    return line_consumer(line)
                end
            end
            return file_ext.process_bridge_listen(name, consumer)
        end
    }
    self.start=function(process)
        file_ext.process_bridge_start(name, process, os_execute)
        self.last_ping = minetest.get_gametime()
        minetest.register_globalstep(function()
            if minetest.get_gametime()-self.last_ping > ping_timeout then
                minetest.request_shutdown("adv_chat: "..name..": process crashed (no ping during last "..ping_timeout.."s)")
            end
        end)
        self.start = nil
    end
    return self
end

build_bridge = (socket and build_socket_bridge) or build_file_bridge