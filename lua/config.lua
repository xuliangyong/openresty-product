
local _M = {}

_M["redis"] = {
	["host"] = "10.1.102.169",
	["port"] = "6379",
	["password"] = "foobared"
}


_M["url"] = "http://www.gxyj.com"   --redis如果挂了，从这个url取

return _M