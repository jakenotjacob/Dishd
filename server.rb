#!/usr/bin/env ruby

require 'socket'

@serv = TCPServer.new 'localhost', 9999

def route(client, request, resource, params)
  case request
  when "GET"
    if File.exists? (Dir.pwd+resource)
      client.print "HTTP/1.1 200 OK"
      client.print "\r\n"
      client.puts File.read("#{Dir.pwd}#{resource}")
    else
      client.puts"HTTP/1.1 404 NOT FOUND\r\n"
      client.print "\r\n"
    end
    client.close
  #when "POST"
  #when "PUT"
  #when "DELETE"
  end
end

def listen(serv)
  loop do
    client = serv.accept
    request, resource, version = client.readline.split(" ")
    params = []
    until params.last == "\r\n"
      line = client.gets
      params << line
    end
    route(client, request, resource, params)
  end
end

listen(@serv)
