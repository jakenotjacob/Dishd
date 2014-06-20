#!/usr/bin/env ruby

require 'socket'

@serv = TCPServer.new 'localhost', 9999

def route(client, request, resource, params)
  case request
  when "GET"
    if File.exists? (Dir.pwd+resource)
      page = File.open(Dir.pwd+resource)
      headers = get_headers(page)
      send_headers(client, headers)
      send_page(client, page, page.size)
    else
      send_status(404, client)
    end
    client.close
  #when "POST"
  #when "PUT"
  #when "DELETE"
  end
end

def send_status(code, client)
  case code
  when 200
    client.print "HTTP/1.1 200 OK\r\n"
  when 404
    client.print "HTTP/1.1 404 NOT FOUND\r\n"
    client.print "Date: #{current_time}\r\n"
    client.print "\r\n"
  end
end

def get_headers(page)
  headers = {
    "Date" => current_time,
    "Content Type" => mime_type(page.path),
    "Content Length" => page.size
  }
  return headers
end

def send_headers(client, headers)
  send_status(200, client)
  headers.each { |type, value|
    client.print "#{type}: #{value}\r\n"
  }
  client.print "\r\n"
end

def listen(serv)
  loop do
    Thread.fork(serv.accept) { |client|
      request, resource, version = client.readline.split(" ")
      params = []
      until params.last == "\r\n"
        line = client.gets
        params << line
      end
      route(client, request, resource, params)
      client.close
    }
  end
end

def current_time
  Time.new.strftime("%a, %e %b %Y %H:%M:%S %Z")
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
