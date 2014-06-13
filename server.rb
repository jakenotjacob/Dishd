#!/usr/bin/env ruby

require 'socket'

@serv = TCPServer.new 'localhost', 9999

def route(client, request, resource, params)
  case request
  when "GET"
    page_path = (Dir.pwd+resource)
    if File.exists? page_path
      page = File.open(page_path)
      print_header(client,"HTTP/1.1 200 OK")
      send_content_header(client, page)
      print_header(client, current_time)
      add_separator(client)
      send_page(client, page, page.size)
    else
      print_header(client, "HTTP/1.1 404 NOT FOUND")
      print_header(client, current_time)
      add_separator(client)
    end
    client.close
  #when "POST"
  #when "PUT"
  #when "DELETE"
  end
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

def print_header(client, str)
  client.print (str + "\r\n")
end

def add_separator(client)
  client.print "\r\n"
end

def send_content_header(client, page)
  content_type = mime_type(page.path)
  content_length = page.size
  print_header(client, "Content-Length: #{content_length}")
  print_header(client,"Content-Type: #{content_type}") if content_type != nil
end

def current_time
  d = Time.new.strftime("%a,%e %b %Y %H:%M:%S %Z")
  return "Date: #{d}"
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
