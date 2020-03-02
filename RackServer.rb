require 'socket'
require 'time'
require 'rack'
require 'rack/utils'

# app = Rack::Lobster.new
server = TCPServer.open('0.0.0.0', 5678)

app = Proc.new do |env|
  req = Rack::Request.new(env)
  puts req.inspect
  case req.path[0]
  when "/"
    body = "Hello world!"
    [200, {'Content-Type' => 'text/html', "Content-Length" => body.length.to_s}, [body]]
  when /^\/name\/(.*)/
    body = "Hello, #{$1}!"
    [200, {'Content-Type' => 'text/html', "Content-Length" => body.length.to_s}, [body]]
  else 
    [404, {"Content-Type" => "text/html"}, ["Ah!!!"]]
  end
end

while connection = server.accept
  request = connection.gets
  # 1
  method, full_path = request.split(' ')
  # 2
  path = full_path.split('?')

  # 1
  status, headers, body = app.call({
    'REQUEST_METHOD' => method,
    'PATH_INFO' => path
  })

  head = "HTTP/1.1 200\r\n" \
  "Date: #{Time.now.httpdate}\r\n" \
  "Status: #{Rack::Utils::HTTP_STATUS_CODES[status]}\r\n" 

  # 1
  headers.each do |k,v|
    head << "#{k}: #{v}\r\n"
  end

  connection.write "#{head}\r\n"

  body.each do |part| 
    connection.write part
  end

  body.close if body.respond_to?(:close)

  connection.close 
end