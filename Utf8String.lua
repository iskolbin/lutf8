local concat, unpack, setmetatable, floor, char, tostring, rawequal = table.concat, table.unpack or _G.unpack, _G.setmetatable, math.floor, string.char, _G.tostring, _G.rawequal

local _cache = setmetatable( {}, {__mode = 'kv'} )
local _chars = setmetatable( {}, {__mode = 'k'} )
local _len = setmetatable( {}, {__mode = 'k'} )
local _string = setmetatable( {}, {__mode = 'k'} )

local POW256 = {[0] = 1, 256, 256^2, 256^3, 256^4, 256^5, 256^6, 256^7}

local Utf8String = {}

function Utf8String.new( s )
	if getmetatable( s ) == Utf8String then
		return s
	else
		s = tostring( s )
		local self = _cache[s]
		if not self then
			self = setmetatable( {}, Utf8String )
			local chars = {}
			_chars[self] = chars
			_string[self] = s

			local i = 0
			for uchar in s:gmatch( "([%z\1-\127\194-\244][\128-\191]*)" ) do
				i = i + 1
				chars[i] = uchar
			end

			_len[self] = i
			_cache[s] = self
		end

		return self
	end
end

function Utf8String._fromtable( t )
	local s = concat( t )
	local self = _cache[s] 
	if not self then
		self = setmetatable( {}, Utf8String )

		_string[self] = s
		_len[self] = #t
		_cache[self] = self
		_chars[self] = t
	end
	return self
end

function Utf8String.char( ... )
	local codes = {...}
	local chars = {}
	for i = 1, #codes do
		local tchar = {}
		local code = codes[i]
		local j = 0
		while code > 0 do
			j = j + 1
			tchar[j] = code % 256
			code = floor( code / 256 )  -- 1/256
		end
		chars[i] = char( unpack( tchar )):reverse()
	end

	return Utf8String._fromtable( chars )
end

function Utf8String:sub( i, j )
	if i == j then
		if i >= 0 then
			return _chars[self][i]
		else
			return _chars[self][_len[self] + i + 1]
		end
	end

	local i = (i >= 0) and i or (_len[self] + i + 1)
	local j = (j ~= nil) and (j >= 0 and j or (_len[self] + j + 1)) or nil

	return concat( _chars[self], '', i, j )
end
	
function Utf8String:byte( i, j )
	i = i or 1
	j = i or j
	local buffer, k = ( i ~= j ) and {}, 0
	local c = _chars[self][i]
	if c then
		local code = 0
		local len = #c
		for i = 0, len-1 do
			code = code + c:sub(len-i, len-i):byte() * POW256[i]
		end
		if buffer then
			k = k + 1
			buffer[k] = code
		else
			return code
		end
	end
	return unpack( buffer )
end
	
function Utf8String:reverse()
	local chars = {}
	local src = _chars[self]
	local len = _len[self]
	for i = 1, len do
		chars[i] = src[len-i+1]
	end
	return Utf8String._fromtable( chars )
end
	
function Utf8String:rep( count, sep )
	if not sep or sep == '' or count <= 1 or _G._VERSION >= 'Lua 5.2' or _G.jit then
		return Utf8String( _string[self]:rep( count, sep ))
	else
		local s = self .. sep 
		return Utf8String( _string[s]:rep( count )) .. s
	end
end
	
function Utf8String:format( ... )
	return Utf8String( _string[self]:format( ... ))
end

function Utf8String:concat( s )
	return Utf8String( _string[Utf8String(self)] .. _string[Utf8String(s)] )
end

function Utf8String:len()
	return _len[self]
end

function Utf8String:tostring()
	return _string[self]
end	

function Utf8String:eq( s ) 
	return rawequal( self, Utf8String( s ))
end

function Utf8String:lt( s )
	return _string[self] < _string[Utf8String(s)]
end

function Utf8String:le( s )
	return self:eq( s ) or self:lt( s )
end

Utf8String.__index = Utf8String
Utf8String.__len = Utf8String.len
Utf8String.__eq = Utf8String.eq
Utf8String.__lt = Utf8String.lt
Utf8String.__le = Utf8String.le
Utf8String.__tostring = Utf8String.tostring
Utf8String.__concat = Utf8String.concat

return setmetatable( Utf8String, { __call = function( _, s )
	return Utf8String.new( s )
end } )
