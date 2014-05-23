#!/usr/bin/env ruby

require 'socket'

@serv = TCPServer.new 'localhost', 9999

def route(client, request, resource, params)
  case request
  when "GET"
    if File.exists? (Dir.pwd+resource)
      page = File.read(Dir.pwd+resource)
      content_type = mime_type(resource)
      content_length = page.size
      client.print "HTTP/1.1 200 OK\r\n"
      client.print "Content-Length: #{content_length}\r\n"
      client.print "Content-Type: #{content_type}\r\n"
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

@mimes = {}
def load_mimes
  f = File.open("/etc/mime.types", "r").readlines
  f.each {|mime|
    mime_type, *extensions = mime.split
    extensions.each { |ext|
      @mimes[ext] = mime_type
    }
  }
  f.close
end

def mime_type(resource)
  extension = resource.split(".").last
  if @mimes[extension] != nil
    return @mimes[extension]
  else
    return "Unable to detect MIME type."
  end
end

load_mimes    
listen(@serv)
