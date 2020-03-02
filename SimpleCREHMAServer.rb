# http_server.rb
require 'socket'
require 'rack'
require 'rack/utils'
require './CREHMA'
require './CREHMAResponse'

server = TCPServer.new 5678
crehma = CREHMA.new

base64Key = "fJW7ebII2E4RU3fD4BjixIDnV++0mq8LUY5TMx2C/g5nRDDies4AFLZ939sU1uoMH+uey1xUMKVSFCd+VNXg+4yOS1M/DtM+9ObW108iNmlXZQsKgXLkRLrBkZ78y2r8Mml3WXe14ktXjCjhRXTx5lBsTKMEcBTxepe1aQ+0hLNOUDhsUKr31t9fS5/9nAQC7s9sPln54Oic1pnDOIfnBEku/vPl3zQCMtU2eRk9v+AfschSUGOvLV6Ctg0cGuSi/h8oKZuUYXrjoehUo1gBvZLVBpcCxZt1/ySGTInLic3QbfZwlT5sJKrYvfHXjANOEIM7JZMaSnfMdK2R9OJJpw=="
key = Base64.decode64(base64Key)
kid = "CREHMAKey"

app = Proc.new do |env|
  req = Rack::Request.new(env)
  # case req.path
  # when "/"
  #   body = "Hello world!"
  #   [200, {'Content-Type' => 'text/html', "Content-Length" => body.length.to_s}, [body]]
  # when /^\/name\/(.*)/
  #   body = "Hello, #{$1}!"
  #   [200, {'Content-Type' => 'text/html', "Content-Length" => body.length.to_s}, [body]]
  # else 
  #   [404, {"Content-Type" => "text/html"}, ["Ah!!!"]]
  # end
end

while session = server.accept
  request = session.gets
  puts request
  puts session.inspect

  body = "Hello world! The time is #{Time.now}"
  headers = {"Content-Type" => "text/plain", "Content-Length" => body.size}
  crehma_res = CREHMAResponse.new(200)
  crehma_res.headers = headers
  #crehma.sign_response(crehma_res)
  
  session.print "HTTP/#{crehma_res.version} crehma_res.status_code\r\n" # 1
  crehma_res.headers.each do |key, value|
  	session.print "#{key}: #{value}\r\n" # 2
  end
  
  session.print "\r\n" # 3
  session.print body #4

  session.close
end