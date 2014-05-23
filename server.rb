#!/usr/bin/env ruby

require 'socket'

@serv = TCPServer.new 'localhost', 9999

def route(client, request, resource, params)
  case request
  when "GET"
    if File.exists? (Dir.pwd+resource)
      page = File.read(Dir.pwd+resource)
      content_length = page.size
      client.print "HTTP/1.1 200 OK\r\n"
      client.print "Content-Length: #{content_length}\r\n"
      client.print "\r\n"
      client.print page
    else
      client.print"HTTP/1.1 404 NOT FOUND\r\n"
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
