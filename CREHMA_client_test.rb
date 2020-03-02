require 'net/http'
require "base64"
require "./CREHMARequest"
require "./CREHMA"

base64Key = "fJW7ebII2E4RU3fD4BjixIDnV++0mq8LUY5TMx2C/g5nRDDies4AFLZ939sU1uoMH+uey1xUMKVSFCd+VNXg+4yOS1M/DtM+9ObW108iNmlXZQsKgXLkRLrBkZ78y2r8Mml3WXe14ktXjCjhRXTx5lBsTKMEcBTxepe1aQ+0hLNOUDhsUKr31t9fS5/9nAQC7s9sPln54Oic1pnDOIfnBEku/vPl3zQCMtU2eRk9v+AfschSUGOvLV6Ctg0cGuSi/h8oKZuUYXrjoehUo1gBvZLVBpcCxZt1/ySGTInLic3QbfZwlT5sJKrYvfHXjANOEIM7JZMaSnfMdK2R9OJJpw=="
key = Base64.decode64(base64Key)
kid = "CREHMAKey"

uri = URI("http://www.ruby-lang.org/test")
req = Net::HTTP::Get.new(uri)
req_headers = Hash.new
req.each_header { |header| req_headers[header] = req[header] }
req.each_header do |header|
  req_headers[header] = req[header]
  puts header
end

crehma_req = CREHMARequest.new(req.method,req.uri.path,req_headers,req.body)
crehma = CREHMA.new
signed_crehma_req = crehma.sign_request(crehma_req,key,kid,"null")
puts signed_crehma_req.headers["Signature"]

# res = Net::HTTP.start(uri.hostname, uri.port) {|http|
#   	http.request(req)
# }