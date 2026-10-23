local module = {}
module.__index = module

function module.new()
	local self = {}
	self.str = ""
	setmetatable(self, module)
	return self
end

function module:input(return_func, nothing_func)
	self.return_func = return_func
	self.nothing_func = nothing_func
	love.keyboard.setTextInput(true)
	self.old_key = love.keypressed
	self.old_text = love.textinput
	love.keypressed = function(key)
		if self then
			self.capture_raw_input(self, key)
		end
	end
	love.textinput = function(key)
		if self then
			self.capture_input(self, key)
		end
	end
end

function module:capture_input(key)
	self.str = self.str .. key
end
function module:capture_raw_input(key)
	--print(key)
	if key == "return" then
		--print("brah")
		love.keyboard.setTextInput(false)
		love.textinput = self.old_text
		love.keypressed = self.old_key
		self.return_func(self)
	elseif key == "backspace" then
		self.str = string.sub(self.str, 1, -2)
	elseif key == "escape" then
		love.keyboard.setTextInput(false)
		love.textinput = self.old_text
		love.keypressed = self.old_key
		self.nothing_func(self)
	end
end

function module:blinking()
	if love.timer.getTime() % 0.5 < 0.25 then
		return self.str .. "_"
	else
		return self.str
	end
end

function module:contains_newline()
	for i = -1, -self.str:len(), -1 do
		local char = self.str:sub(i, i)
		if char == "\n" then
			return true
		end
	end
	return false
end

function module:clear()
	self.str = ""
end

return module
