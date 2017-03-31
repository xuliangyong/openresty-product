local conf = require "config"

function query_slave_redis(host, port, password, cacheKey)

	local redis = require "resty.redis_iresty"
	local cfg = {timeout = 1000, host = host, port = port, password = password}
	local red = redis:new(cfg)	
				
	local resp, err = red:get(cacheKey)  
	if not resp then  
		ngx.log(ngx.ERR, err)
		return
	end 
						
	return resp;
end


--------------- 托底方案： 查询redis失败后，最后通过url动态查询 ----------------
function load_url(key)
	local http = require "resty.http"
	local httpc = http.new()  
	local resp_body = nil
	local path = string.format("/products/prodCommon_%010d.jhtml", key)
--	ngx.say(path)
	local resp, err = httpc:request_uri( conf.url, {
			method="GET",
			path = path,
			headers = {  
				["User-Agent"] = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.111 Safari/537.36"  
			} 
	})
	
	if not resp then  
		ngx.log(ngx.ERR, "request error :", err)  
		return  
	end 

	resp_body = resp.body
	
	httpc:close()
	
	return resp_body
end

----- 获取一致性hash后的server -----
function get_real_server(product_id)
	local consistent = require 'resty.consistent_hash'
	consistent.add_server(conf.redisList)
	
	local ser = consistent.get_upstream(product_id)
	return ser
end

---------  start  --------
--local zlib = require "zlib"

local id_str = string.match(ngx.var.uri, "%d+")
local product_id = tonumber(id_str)
local resp = nil

--local IfModifiedSince = ngx.req.get_headers()["If-Modified-Since"]
--ngx.log(ngx.ERR,  IfModifiedSince)

--local lrucache = require "resty.lrucache"
--idcache = lrucache.new(200)  -- 全局缓存 key:商品id，value:一致性hash后的redis

if product_id ~= nil then 

	--查询redis
	resp = query_slave_redis(conf.redis.host, conf.redis.port, conf.redis.password, product_id)
	
	if resp == nil then 
		--查询旧url
		resp = load_url(product_id)
	end	
end

ngx.header["Content-Type"] = "text/html;charset=utf-8"
--ngx.header["Last-Modified"] = "Thu, 16 Mar 2018 08:01:40 GMT"  --304缓存
if resp == nil then 
	ngx.exit(ngx.HTTP_NOT_FOUND)
else 
	ngx.say(resp)
end
	

					
