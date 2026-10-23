local node_mod = require("node")

function love.load()
	cam_x = 0
	cam_y = 0
	cam_zoom = 1
	node_mod.new(0, 0, nil)
	mainFont = love.graphics.newFont("roboto.ttf", 64)
	love.graphics.setFont(mainFont)
end

function pos_to_cam(x, y)
	x = x - cam_x
	y = y - cam_y
	return x * cam_zoom + screen_width / 2, y * cam_zoom + screen_height / 2
end

function cam_to_pos(x, y)
	return ((x - screen_width / 2) / cam_zoom + cam_x), ((y - screen_height / 2) / cam_zoom + cam_y)
end

function cam_to_pos_b(x, y)
	return ((x - screen_width / 2) / cam_zoom), ((y - screen_height / 2) / cam_zoom)
end

local step = 10
local dragging = false
local dragx, dragy = 0, 0

local typing = require("typing")
local name_obj = nil
local typing_obj = nil

local table_to_text = require("table_serializer")

function love.keypressed(key, scancode, isrepeat)
	if key == "escape" then
		love.event.quit()
	end
	if key == "delete" or key == "backspace" then
		get_closest():remove()
	end
	if key == "insert" or key == "i" then
		get_closest():make_child()
	end
	if key == "s" and love.keyboard.isDown("lctrl") then
		print("yea")
		typing_obj = typing.new()
		typing_obj:input(function(self)
			typing_obj = nil
			local text = table_to_text(node_mod.get_objects())
			local file_name = self.str
			local file, err = io.open(file_name, "w")
			if file then
				file:write(text)
				file:close()
			else
				print("error:", err)
			end
		end, function()
			typing_obj = nil
		end)
	end
	if key == "o" and love.keyboard.isDown("lctrl") then
		print("yeab")
		typing_obj = typing.new()
		typing_obj:input(function(self)
			load_nodes(self.str)
			typing_obj = nil
		end, function()
			typing_obj = nil
		end)
	end

	--if key == "a" and not name_obj then
	--	local node = get_closest()
	--	name_obj = node
	--	typing_obj = typing.new()
	--	typing_obj:input(function(self)
	--		name_obj.text = self.str
	--		name_obj = nil
	--		typing_obj = nil
	--	end, function(self)
	--		name_obj = nil
	--		typing_obj = nil
	--	end)
	--end
end

function load_nodes(filepath)
	local raw_nodes = loadfile(filepath, "t", {})()
	for _, node in pairs(raw_nodes) do
		setmetatable(node, node_mod)
	end
	node_mod.set_nodes(raw_nodes)
end

function draw_centered_text(rectX, rectY, rectWidth, rectHeight, text, scale)
	local wrap_length = 15
	local wrap = math.floor(text:len() / wrap_length)
	for i = 1, wrap do
		text = text:sub(1, i * wrap_length + (i - 1)) .. "\n" .. text:sub(i * wrap_length + i, -1)
	end

	local font = love.graphics.getFont()
	local text_width = font:getWidth(text)
	local text_height = font:getHeight() * (wrap + 1)
	love.graphics.print(
		text,
		rectX + rectWidth / 2,
		rectY + rectHeight / 2,
		0,
		scale,
		scale,
		text_width / 2,
		text_height / 2
	)
end

function love.draw()
	local dt = love.timer.getDelta()
	if dragging then
		local newx, newy = love.mouse.getPosition()
		newx, newy = cam_to_pos_b(newx, newy)
		cam_x, cam_y = dragx - newx, dragy - newy
	end
	if typing_obj then
		love.graphics.print(typing_obj:blinking(), 0, 0)
	end
	if grabbing then
		local xb, yb = love.mouse.getPosition()
		xb, yb = cam_to_pos(xb, yb)
		local to_mx, to_my = -(grabbing.x - xb), -(grabbing.y - yb)
		grabbing.vx = grabbing.vx + to_mx * dt * 10
		grabbing.vy = grabbing.vy + to_my * dt * 10
	end
	screen_width = love.graphics.getWidth()
	screen_height = love.graphics.getHeight()
	local nodes = node_mod.get_objects()
	for _, node in pairs(nodes) do
		if node.parent then
			local cam_x, cam_y = pos_to_cam(node.x, node.y)
			local cam_xb, cam_yb = pos_to_cam(node.parent.x, node.parent.y)
			love.graphics.line(cam_x, cam_y, cam_xb, cam_yb)
		end
	end
	for _, node in pairs(nodes) do
		for i = 1, 30 do
			node:simulate(dt * 1)
		end
		local cam_x, cam_y = pos_to_cam(node.x, node.y)
		love.graphics.circle("fill", cam_x, cam_y, 40 * cam_zoom, 50)
		love.graphics.setColor(0, 0, 0, 1)
		local rect_size = 30
		draw_centered_text(
			cam_x - (rect_size / 2) * cam_zoom,
			cam_y - (rect_size / 2) * cam_zoom,
			rect_size * cam_zoom,
			rect_size * cam_zoom,
			node.text,
			cam_zoom / 10
		)
		love.graphics.setColor(1, 1, 1, 1)
		--print(node.x, node.y)
	end
	--print(#nodes)
end

function get_closest()
	local x, y = love.mouse.getPosition()
	x, y = cam_to_pos(x, y)
	local nodes = node_mod.get_objects()
	local closest_node = nodes[1]
	local dist = math.huge
	for _, node in pairs(nodes) do
		local dist_b = node_mod.length(node.x - x, node.y - y)
		if dist_b < dist then
			closest_node = node
			dist = dist_b
		end
	end
	return closest_node
end

function love.mousepressed(x, y, button, istouch, presses)
	if button == 2 then
		dragging = true
		dragx, dragy = cam_to_pos(x, y)
	end
	if button == 1 then
		grabbing = get_closest()
		if presses == 2 and not name_obj then
			local node = get_closest()
			name_obj = node
			typing_obj = typing.new()
			typing_obj:input(function(self)
				name_obj.text = self.str
				name_obj = nil
				typing_obj = nil
			end, function(self)
				name_obj = nil
				typing_obj = nil
			end)
		end
	end
end
function love.mousereleased(x, y, button)
	if button == 2 then
		dragging = false
	end
	if button == 1 then
		grabbing = nil
	end
end

function love.wheelmoved(x, y)
	if y > 0 then
		cam_zoom = cam_zoom * 1.1
	elseif y < 0 then
		cam_zoom = cam_zoom / 1.1
	end
end
