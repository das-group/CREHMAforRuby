require './HashAlgorithm'
require './SHA256'
require './SignatureAlgorithm'
require './SimpleHMACSHA256'
require './CREHMARequest'
require './CREHMAResponse'
require 'time'
require "base64"

class CREHMA

	@@signature_header_template = "sig=%s,hash=%s,kid=%s,tvp=%s,addHeaders=%s,sv=%s"
	@@methods_with_empty_body = ["GET","HEAD","DELETE"]
	
	def initialize
		@tbs_response_headers = Array[
			"ETag",
			"Expires",
			"Cache-Control",
			"Content-Length",
			"Content-Type",
			"Last-Modified",
			"Transfer-Encoding"
		].sort

		@tbs_request_headers = Array[
			"Host",
			"Accept",
			"Content-Type",
			"Transfer-Encoding",
			"Content-Length"
		].sort

		@hashAlgorithm = SHA256.new
		@signatureAlgorithm = SimpleHMACSHA256.new
	end

	def hashAlgorithm(hashAlgorithm)
		@hashAlgorithm = hashAlgorithm
	end

	def signatureAlgorithm(signatureAlgorithm)
		@signatureAlgorithm = signatureAlgorithm
	end

	def hashAlgorithm
		@hashAlgorithm
	end

	def signatureAlgorithm
		@hashAlgorithm
	end

	def build_tbs_response(res,tvp,primary_cache_key,addHeaders="null")
		tbs = tvp + "\n"
		tbs = tbs + build_tbs_response_without_tvp(res,tbs,primary_cache_key,addHeaders="null")
		return tbs
	end

	def build_tbs_response_without_tvp(res,tbs,primary_cache_key,addHeaders="null")
		tbs = tbs + primary_cache_key + "\n"
		#tbs = tbs + cacheKey + "\n"
		tbs = tbs + "HTTP/#{res.version}" + "\n"
		tbs = tbs + response.code + "\n"
		$tbsResponseHeaders.each do |header|
			#puts header
			if res.headers[header] == nil
				tbs = tbs + "\n"
			else
				tbs = tbs + res.headers[header] + "\n"
			end
		end

		if res.body == nil
			tbs = tbs + @hashAlgorithm.hash_of_empty_body
		else
			tbs = tbs + @hashAlgorithm.generate_hash(res.body)
		end
	end

	def build_tbs_request(req,tvp,addHeaders="null")
		tbs = tvp + "\n"
		tbs = tbs +  req.method + "\n"
		tbs = tbs + req.target == "" ? "/" : req.target + "\n"
		tbs = tbs + "HTTP/#{req.version}" + "\n"

		@tbs_request_headers.each do |header|
			if req.headers[header] == nil
				tbs = tbs + "\n"
			else
					tbs = tbs + req.headers[header] + "\n"
			end
		end

		if @@methods_with_empty_body.include? req.method or req.body == nil
			tbs = tbs + @hashAlgorithm.hash_of_empty_body
		else
			tbs = tbs + @hashAlgorithm.generate_hash(req.body)
		end

		return tbs
	end

	def generate_signature_header_value(tbs,key,kid,tvp,addHeaders="null")
		sv = @signatureAlgorithm.sign(tbs,key)
		header_value = @@signature_header_template % [@signatureAlgorithm.name,@hashAlgorithm.name,kid,tvp,addHeaders,sv]
		return header_value
	end

	def verify_response(res,req)
		signature_header_params = parse_signature_header(res.headers["Signature"])
		tvp = signature_header_params["tvp"]
		sv = signature_header_params["sv"]
		kid = signature_header_params["kid"]
		addHeaders = signature_header_params["addHeaders"]
		primary_cache_key = req.method + req.target
		tbs = build_tbs_response(res,tvp,primary_cache_key,addHeaders)
		if !@signatureAlgorithm.verify(sv,kid,tbs)
			return false
		end

		if !verify_signature_freshness(req,tvp)
			return false
		end

		return true
		
	end

	def sign_request(req,key,kid,addHeaders="null")
		tvp = generate_tvp
		tbs = build_tbs_request(req,tvp,addHeaders)

		req.headers["Signature"] = generate_signature_header_value(tbs,key,kid,tvp,addHeaders)
		return req
	end

	def sign_response(res,req,key,kid,addHeaders="null")
		tvp = generate_tvp
		tbs = build_tbs_response(req,req,tvp,addHeaders)
		return generate_signature_header_value(tbs,key,kid,tvp,addHeaders)
	end

	def verify_request(req)
		signature_header_params = parse_signature_header(res.headers["Signature"])
		tvp = signature_header_params["tvp"]
		sv = signature_header_params["sv"]
		kid = signature_header_params["kid"]
		addHeaders signature_header_params["addHeaders"]
		tbs = build_tbs_request(req,tvp,addHeaders)
		if !@signatureAlgorithm.verify(sv,kid,tbs)
			return false
		end
	end

	def verify_tvp(tvp)
	end

	def verify_signature_freshness(req,tvp)
		# Check max-age or s-maxage first
		max_age = 0
		s_max_age = 0
		cache_control_header= req["Cache-Control"]
		cache_control_header_arams = cache_control_header_split(",")
		cache_control_header_arams.each do |param|
			if param.start_with?("max-age=")
				max_age = param.split("=")[1]
			elsif param.start_with?("s-maxage=")
				s_max_age = param.split("=")[1]
			end
		end
		if max_age > 0 || s_max_age > 0
			max_age_signature_freshness = verify_signature_freshness_max_age(max_age,tvp)
			s_max_age_signature_freshness = verify_signature_freshness_max_age(s_max_age,tvp)
			return max_age_signature_freshness || s_max_age_signature_freshness
		# If no max-age or s-maxage defined, check Expires header
		elsif req["Expires"]
			expires_date = Time.parse(req["Expires"]).to_i
			tvp_date = (Time.parse(tvp).to_f * 1000).to_i
			return tvp_date < expires_date ? true : false
		else
			return false
		end
	end

	def verify_signature_freshness_max_age(max_age,tvp)
		tvp_date = (Time.parse(tvp).to_f * 1000).to_i

		delta = 0
		now = (Time.now.to_f * 1000).to_i
		signature_expiration_date = tvp_date + 5000 + Integer(max_age) * 1000;
		if now < signature_expiration_date
			return true
		else 
			return false
		end
	end

	def parse_signature_header(signature_header_value)
		signature_header_params = Hash.new
		signature_header_value.split(",").each do |item|
			case item.split("=")[0]
				when "sig"
					signature_header_params["sig"] = item.split("=")[1]
				when "hash"
					signature_header_params["hash"] = item.split("=")[1]
				when "kid"
					signature_header_params["kid"] = item.split("=")[1]
				when "tvp"
					signature_header_params["tvp"] = item.split("=")[1]
				when "sv"
					signature_header_params["sv"] = item.split("=")[1]
				when "addHeaders"
					signature_header_params["addHeaders"] = item.split("=")[1]
			end
		end
		return signature_header_params
	end

	def generate_tvp
		return Time.now.iso8601
	end

end