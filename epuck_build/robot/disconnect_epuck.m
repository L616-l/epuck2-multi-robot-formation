function disconnect_epuck(port)
if isvalid(port)
    delete(port);
end
end
