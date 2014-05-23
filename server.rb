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

def mime_type(resource)
  extension = resource.split(".").last
  mimes = {
    "image" => %w[jpg jpeg jpe pjpeg gif png bmp svg raw tga tif tiff],
    "application" => %w[json pdf xml zip gzip js],
    "text" => %w[html css csv rtf txt],
    "audio" => %w[mp3 mp4 mpeg wav m4a aac ogg wma flac],
    "video" => %w[mpeg mp4 avi ogg]
  }

  mimes.keys.each { |key|
    if mimes[key].include? extension
      return "#{key}/#{extension}"
    end
  }
end
    
listen(@serv)
