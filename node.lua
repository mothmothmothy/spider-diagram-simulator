local class = {}
class.__index = class
local objects = {}

function class.new(x, y, parent)
	local obj = {}
	obj.x = x
	obj.y = y
	obj.vx = 0
	obj.vy = 0
	obj.parent = parent
	obj.children = {}
	obj.text = "nothing"
	if parent then
		table.insert(parent.children, obj)
	end
	table.insert(objects, obj)
	setmetatable(obj, class)
	return obj
end

function class.get_objects()
	return objects
end

local node_seperation_distance = 100

function class:remove()
	for i, obj in pairs(objects) do
		if obj == self then
			table.remove(objects, i)
		end
	end
end

function class:simulate(dt)
	if self.parent then
		self.x = self.x + self.vx * dt
		self.y = self.y + self.vy * dt
		self:add_spring_force(self.parent, 0.5, node_seperation_distance, dt, _, _, true)
		for _, obj in pairs(objects) do
			if obj ~= self.parent and obj ~= self then
				self:add_repel_force(obj, 90, 25, dt)
			end
		end
		self.vx = self.vx * math.pow(0.7, dt)
		self.vy = self.vy * math.pow(0.7, dt)
	end
end
function class.div(x, y, b)
	return x / b, y / b
end
function class:add_repel_force(other, strength, dist_before_sqrt, dt)
	local x, y = self:difference_to(other)
	local repel_force = strength / (class.length(class.div(x, y, dist_before_sqrt)) ^ 2 + 1)
	local dx, dy = class.unit(self:difference_to(other))
	self.vx = self.vx - dx * repel_force * dt
	self.vy = self.vy - dy * repel_force * dt
	other.vx = other.vx + dx * repel_force * dt
	other.vy = other.vy + dy * repel_force * dt
end
function class:add_spring_force(other, strength, length, dt, attract, repel, reaction)
	local dx, dy = self:difference_to(other)
	local x, y = class.unit(dx, dy)
	local position = class.length(dx, dy) - length
	if position > 0 and attract == false then
		return
	end
	if position < 0 and repel == false then
		return
	end
	self.vx = self.vx + x * dt * strength * position
	self.vy = self.vy + y * dt * strength * position
	if not reaction then
		return
	end
	other.vx = other.vx + -x * dt * strength * position
	other.vy = other.vy + -y * dt * strength * position
end
function class.length(x, y)
	if not y then
		x = x.x
		y = x.y
	end
	local result = math.sqrt(x ^ 2 + y ^ 2)
	if result == result then
		return result
	else
		return 1
	end
end
function class.unit(x, y)
	if not y then
		x = x.x
		y = x.y
	end
	local length = class.length(x, y)
	x = x / length
	y = y / length
	if not x == x then
		x = math.random() - 0.5
		y = math.random() - 0.5
		return class.unit(x, y)
	end
	return x, y
end
function class.set_nodes(nodes)
	objects = nodes
end
function class:difference_to(other)
	return other.x - self.x, other.y - self.y
end
function class:make_child()
	class.new(self.x + math.random() - 0.5, self.y + math.random() - 0.5, self)
end

return class
