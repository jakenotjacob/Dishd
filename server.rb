#!/usr/bin/env ruby

require 'socket'

@serv = TCPServer.new 'localhost', 9999

def route(client, request, resource, params)
  case request
  when "GET"
    if File.exists? (Dir.pwd+resource)
      page = File.open(Dir.pwd+resource)
      content_type = mime_type(resource)
      content_length = page.size
      client.print "HTTP/1.1 200 OK\r\n"
      client.print "Content-Length: #{content_length}\r\n"
      client.print "Content-Type: #{content_type}\r\n" if content_type != nil
      client.print "\r\n"
      send_page(client, page, content_length)
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
  f = File.open("/etc/mime.types", "r")
  mimes = f.readlines
  mimes.each {|mime|
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
    return nil
  end
end

def send_page(cli, page, page_length)
  #TODO Modify for Jumbo Frames(4096][page size]-8192) and test
  if page_length <= 1400 #Ethernet MTU
    cli.print page.read
  else
    until page.eof?
      cli.print page.readpartial(1400)
    end
  end
end

load_mimes    
listen(@serv)
