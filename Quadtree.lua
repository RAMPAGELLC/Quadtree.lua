--[[
	Quadtree.lua
	© 2023 RAMPAGE Interactive, All rights reserved.
	License: MIT
	
	This module provides a Quadtree data structure for optimizing spatial queries
	
    Example Usage:

    local Quadtree = require(path.to.Quadtree)

    -- Create a new Quadtree with a specified region and parameters
    local quad = Quadtree.new(0, 0, 1000, 1000, 10, 5)

    -- Insert objects into the Quadtree
    local object1 = { Position = Vector3.new(50, 50), Size = Vector2.new(20, 20) }
    local object2 = { Position = Vector3.new(200, 200), Size = Vector2.new(30, 30) }
    quad:insert(object1)
    quad:insert(object2)

    -- Retrieve objects within a specified region
    local queryRect = { x = 0, y = 0, width = 100, height = 100 }
    local resultObjects = {}
    quad:retrieve(resultObjects, queryRect)

    -- Clear the Quadtree
    quad:clear()
]]

local Quadtree = {}
Quadtree.__index = Quadtree

function Quadtree.new(x, y, width, height, maxObjects, maxLevels, level)
	local self = setmetatable({}, Quadtree)
	self.x = x
	self.y = y
	self.width = width or 0
	self.height = height or 0
	self.maxObjects = maxObjects or 10
	self.maxLevels = maxLevels or 5
	self.level = level or 0
	self.objects = {}
	self.nodes = {}
	return self
end

function Quadtree:retrieve(returnObjects, queryRect)
	local index = self:getIndex(queryRect)
	if index ~= 0 and #self.nodes > 0 then
		self.nodes[index]:retrieve(returnObjects, queryRect)
	end

	for _, obj in pairs(self.objects) do
		table.insert(returnObjects, obj)
	end

	return returnObjects
end

function Quadtree:clear()
	self.objects = {}
	for _, node in pairs(self.nodes) do
		node:clear()
	end
	self.nodes = {}
end

function Quadtree:split()
	local subWidth = self.width / 2
	local subHeight = self.height / 2
	local x = self.x
	local y = self.y

	self.nodes[1] = Quadtree.new(x + subWidth, y, subWidth, subHeight, self.maxObjects, self.maxLevels, self.level + 1)
	self.nodes[2] = Quadtree.new(x, y, subWidth, subHeight, self.maxObjects, self.maxLevels, self.level + 1)
	self.nodes[3] = Quadtree.new(x, y + subHeight, subWidth, subHeight, self.maxObjects, self.maxLevels, self.level + 1)
	self.nodes[4] = Quadtree.new(x + subWidth, y + subHeight, subWidth, subHeight, self.maxObjects, self.maxLevels, self.level + 1)
end

function Quadtree:getIndex(object)
	local index = 0
	local verticalMidpoint = self.x + self.width / 2
	local horizontalMidpoint = self.y + self.height / 2

	local objectX = object.Position.X
	local objectY = object.Position.Y

	local topQuadrant = objectY < horizontalMidpoint and objectY + object.Size.Y < horizontalMidpoint
	local bottomQuadrant = objectY > horizontalMidpoint

	if objectX < verticalMidpoint and objectX + object.Size.X < verticalMidpoint then
		if topQuadrant then
			index = 2
		elseif bottomQuadrant then
			index = 1
		end
	elseif objectX > verticalMidpoint then
		if topQuadrant then
			index = 3
		elseif bottomQuadrant then
			index = 4
		end
	end

	return index
end

function Quadtree:insert(object)
	if #self.nodes > 0 then
		local index = self:getIndex(object)
		if index ~= 0 then
			self.nodes[index]:insert(object)
			return
		end
	end

	table.insert(self.objects, object)

	if #self.objects > 5 and #self.nodes == 0 then
		self:split()
		local i = 1
		while i <= #self.objects do
			local index = self:getIndex(self.objects[i])
			if index ~= 0 then
				self.nodes[index]:insert(table.remove(self.objects, i))
			else
				i = i + 1
			end
		end
	end
end

return Quadtree
