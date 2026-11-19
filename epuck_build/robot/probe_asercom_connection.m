function probe_asercom_connection(port)
protocol = asercom_protocol();
asercom_exchange(port,protocol.probe,protocol.proximityReply);
end
