--overrides server/farming/SFarmingSystem.lua


if isClient() then return end


function SFarmingSystem:initSystem()
	SGlobalObjectSystem.initSystem(self)

	-- Specify GlobalObjectSystem fields that should be saved.
	self.system:setModDataKeys({'hoursElapsed'})
	
	-- Specify GlobalObject fields that should be saved.
	self.system:setObjectModDataKeys({
		'state', 'nbOfGrow', 'typeOfSeed', 
		'health', 'waterLvl', 'fertilizer', 'mildewLvl', 'aphidLvl', 'fliesLvl',
		'waterNeeded', 'waterNeededMax', 'hasVegetable', 'hasSeed', --not really needed? 
		'lastWaterHour', 'badCare',  --not used in mod
		'nextGrowing', 
		'exterior', 'spriteName', 'objectName', 
		'hasWindow' --NEW: hasWindow. could use exterior instead?
	})
	-- self:convertOldModData()
end

function SFarmingSystem:EveryTenMinutes()
	local sec = math.floor(getGameTime():getTimeOfDay() * 3600)
	local currentHour = math.floor(sec / 3600)
	local day = getGameTime():getDay()
	-- an hour has passed
	if currentHour ~= self.previousHour then
		self.hoursElapsed = self.hoursElapsed + 1
		self.previousHour = currentHour
		self.hourElapsedForWater = self.hourElapsedForWater + 1
		-- every X hours, we lover the water lvl of all plant
		-- we also gonna up our disease lvl
		 --EDITED: all values here
		local hourForWater = 2 -- normal
		if SandboxVars.PlantResilience == 1 then hourForWater = 4  -- very high
		elseif SandboxVars.PlantResilience == 2 then hourForWater = 3 -- high
 		elseif SandboxVars.PlantResilience == 5 then hourForWater = 1 -- very low
		end
		if self.hourElapsedForWater >= hourForWater then
			self:lowerWaterLvlAndUpDisease()
			self.hourElapsedForWater = 0
		end
		-- change health of the plant every 2 hours
		self.previousHourHealth = self.previousHourHealth + 1
		if self.previousHourHealth == 2 then
			self:changeHealth()
			self.previousHourHealth = 0
		end
		self:sendCommand('hoursElapsed', { hoursElapsed = self.hoursElapsed })
	end
	self:checkPlant()
end
 
function SFarmingSystem:lowerWaterLvlAndUpDisease()
	local luaObject = nil
	for i=1,self:getLuaObjectCount() do
		luaObject = self:getLuaObjectByIndex(i)
		luaObject:lowerWaterLvl()
		luaObject:upDisease()
	end
end


function SFarmingSystem:changeHealth()

	---------------------------
	-- NEW: seasonal effects --
	---------------------------

local lightStrength = ClimateManager.getInstance():getDayLightStrength()
local rainStrength = ClimateManager.getInstance():getRainIntensity()
local windStrength = ClimateManager.getInstance():getWindIntensity()
local luaObject = nil
local props = nil
local minWater = 0
local maxWater = 0
local availableWater = 0
local waterbarrel = nil
local waterNeeded = 0 

local needs=0
local has=0

for i=1,self:getLuaObjectCount() do
	luaObject = self:getLuaObjectByIndex(i)
	local temperature = ClimateManager.getInstance():getAirTemperatureForSquare( luaObject:getSquare() ) --indoor temp is 22a

	if luaObject.state == "seeded" then
		props = farming_vegetableconf.props[luaObject.typeOfSeed]
		availableWater = luaObject.waterLvl
		minWater = props.waterLvl
		maxWater = props.waterLvlMax

waterbarrel=self:findbarrel(luaObject:getSquare())
if waterbarrel then 

--[[
raingutter=self:findRainGutter(waterbarrel:getSquare())
if raingutter then -- move water from raingutter to barrel
print ("raingutter has:" .. raingutter:getWaterMax() .. "max and contains: ".. raingutter:getWaterAmount())

needs=waterbarrel:getWaterMax() - waterbarrel:getWaterAmount()
has=raingutter:getWaterAmount()
print ("needs:".. needs .. "has:".. has)

if needs >= has then 
	raingutter:setWaterAmount(0)
	waterbarrel:setWaterAmount(waterbarrel:getWaterAmount()+needs)
else 
	raingutter:setWaterAmount(raingutter:getWaterAmount()-needs)
	waterbarrel:setWaterAmount(waterbarrel:getWaterMax())
end

end -- move water from raingutter to barrel
]]

print ("plant:" ..  availableWater ..   " barrel: ".. waterbarrel:getWaterAmount())

if availableWater < maxWater then
	waterNeeded = maxWater - availableWater 
	if waterNeeded < waterbarrel:getWaterAmount() then
	waterbarrel:setWaterAmount(waterbarrel:getWaterAmount()- (waterNeeded / 4))
	availableWater=100
	luaObject.waterLvl=100
	end
end
	--waterbarrel:setWaterAmount(300)
end


		print ("*******  Change Health for:" .. luaObject.typeOfSeed .. "  temp:" .. temperature .. "  Waterlevel:" .. availableWater)

		if not luaObject.exterior then -- ***indoors***
			if luaObject:getSquare() ~= nil then luaObject.hasWindow = self:checkWindowsAndGreenhouse( luaObject:getSquare() )
			end
			if luaObject.hasWindow then --indoors with greenhouse: no negative effects on weather
				print (luaObject.typeOfSeed .. "plant is indoors with greenhouse")
				luaObject.health = luaObject.health + (lightStrength*3) 
			else 
				print (luaObject.typeOfSeed .. "plant is indoors without a greenhouse")
				luaObject.health = luaObject.health - 10 -- no indoor growing without a greenhouse plant will die
			end -- greenhouse check

		else -- **** Outdoors ***	
		print (luaObject.typeOfSeed .. " is Outside - storm and frost handling")
			if temperature < 0 then  availableWater = 0 -- no available Water if outdoors and frozen
			end
			
			-- temp handling
			if temperature < props.bestTemp then luaObject.health = luaObject.health + 0.5 - (props.bestTemp - temperature) / (props.bestTemp - props.minTemp) * 1.5 -- +0.5 at best temp, -1 at min temp
			else luaObject.health = luaObject.health + 0.5 - (props.bestTemp - temperature) / (props.bestTemp - props.maxTemp)  -- -0.5 at max temp
			end

			-- storm handling
			if props.damageFromStorm and luaObject.nbOfGrow >= 3 and rainStrength > 0.5 and windStrength > 0.5 then luaObject.health = luaObject.health - (16 * rainStrength * windStrength -3) -- 1-13 damage
			end

 		end -- indoors/outdoors	


 		-- sunlight
		luaObject.health = luaObject.health + lightStrength / 5 -- only average ~0.1/h inside
	
		-- water levels
		if availableWater < minWater then luaObject.health = luaObject.health - 0.5 - (minWater - availableWater) / 50 -- min 0.5 - max ~1.4/2.1, depending on plant
		elseif availableWater > maxWater then luaObject.health = luaObject.health - (availableWater - maxWater) / 50 -- max ~0.3 damage for most plants
		else luaObject.health = luaObject.health + 1 - math.abs(minWater + (maxWater-minWater)/2 - availableWater)/(maxWater-minWater)/2 -- 0-1 gain
		end

		-- mildew disease
		if luaObject.mildewLvl > 0 then luaObject.health = luaObject.health - 0.2 - luaObject.mildewLvl/50 -- 0.2 - 2.2 damage
		end
		if luaObject.aphidLvl > 0 then luaObject.health = luaObject.health - 0.15 - luaObject.mildewLvl/75 -- 0.15 - 1.6 damage
		end
		if luaObject.fliesLvl > 0 then luaObject.health = luaObject.health - 0.1 - luaObject.mildewLvl/100 -- 0.1 - 1.1 damage
		end

		-- plant dies
		if luaObject.health <= 0 then
			if luaObject.exterior and rainStrength > 0.7 and windStrength > 0.7 then luaObject:destroyThis()
			elseif luaObject.exterior and temperature <= 0 then luaObject:dryThis()
			elseif luaObject.waterLvl <= 0 then luaObject:dryThis()
			elseif luaObject.mildewLvl > 0 then luaObject:rottenThis()
			else luaObject:dryThis()
			end
		end
			

end -- seeded?
end -- loop over getLuaObjectCount
end -- function

function SFarmingSystem:checkPlant()

	for i=1,self:getLuaObjectCount() do
		local luaObject = self:getLuaObjectByIndex(i)
		if luaObject:getSquare() then luaObject.exterior = luaObject:getSquare():isOutside() end
		-- we may destroy our plant if someone walk onto it
		self:destroyOnWalk(luaObject)

		--EDITED: based on rain intensity
		if RainManager.isRaining() and luaObject.exterior then
			luaObject.waterLvl = luaObject.waterLvl + ClimateManager.getInstance():getRainIntensity() * 15
			if luaObject.waterLvl > 100 then
				luaObject.waterLvl = 100
			end
			luaObject.lastWaterHour = self.hoursElapsed
		end
		--END

		-- Something can grow up !
		if luaObject.nextGrowing ~= nil and self.hoursElapsed >= luaObject.nextGrowing then
			if luaObject:isAlive() then
				if luaObject:getSquare() then luaObject.hasWindow = self:checkWindowsAndGreenhouse(square) end				
				self:growPlant(luaObject)
			else
				luaObject:destroyPlow()
			end
		end
		-- add the icon if we have the required farming xp and if we're close enough of the plant
		luaObject:addIcon()
		luaObject:checkStat()
		luaObject:saveData()
	end
end


function SFarmingSystem:growPlant(luaObject)
	-- NEW: removed hardcoded stuff, now supports custom plants
	luaObject = farming_vegetableconf.growPlant(luaObject)
end



----------------------------
--NEW: GREENHOUSE CHECKING--
----------------------------

function SFarmingSystem:checkWindows(sq)
return true

--[[
	if sq:testVisionAdjacent(0,-1,0, false,false) ~= "Blocked" then --N
		if sq:getN() == nil or sq:getN():isOutside() then
			return true
		end
	end
	if sq:testVisionAdjacent(-1,0,0, false,false) ~= "Blocked" then --W
		if sq:getW() == nil or sq:getW():isOutside() then
			return true
		end
	end
	if sq:testVisionAdjacent(0,1,0, false,false) ~= "Blocked" then --S
		if sq:getS() == nil or sq:getS():isOutside() then
			return true
		end
	end
	if sq:testVisionAdjacent(1,0,0, false,false) ~= "Blocked"  then --E
		if sq:getE() == nil or sq:getE():isOutside() then
			return true
		end
	end
	if SFarmingSystem:checkRoof(sq) > 0 then
		return true
	end
	return false

--]]

end

function SFarmingSystem:checkRoof(sq)
	-- sq:testVisionAdjacent(0,0,1, false,false) --not working, roofs don't block vision!
	-- objs:get(0):getProperties():Is(IsoFlagType.trans) ) --not working either, looks like roofs don't really exist ;P
	
	-- resort to counting glass roof sprites...
	sq = getCell():getGridSquare(sq:getX(),sq:getY(),sq:getZ()+1)
	if sq == nil then return 0 end

	local objs = sq:getObjects()
	if objs:size() > 0 then
		if objs:get(0):getSprite() then
			--all:		32-79
			--doubles:	32-47
			--singles: 	50-61,78,79
			local id = objs:get(0):getSprite():getID()
			if id >= 220032 and id <= 220079 then --220055 is the HC glass roof
				if id >= 220032 and id <= 220047 then return 2 --slopes probably exist twice, but the 2nd one is hidden because of iso perspective
				elseif id >= 220050 and id <= 220061 then return 1
				elseif id == 220078 or id == 220079 then return 1
				end
			end
		end
	end
	return 0
end


function SFarmingSystem:findbarrel(sq)
if sq then

local x=sq:getX()
local y=sq:getY()
local z=sq:getZ()
print ("****************************find -A- barrel***************************".. x .. " ".. y .. " ".. z )
local objs = nil
local barrel = nil
for x = x-1,x+1 do
for y = y-1,y+1 do

aaa = getCell():getGridSquare(x,y,z)
objs = aaa:getObjects()

if objs:size() > 1 then
	for i = 0, objs:size()-1 do
  		barrel = objs:get(i)
  		print (i .. ":" .. barrel:getWaterAmount())
  		if barrel:getWaterAmount() > 0 then return barrel
  	end -- tile loop
end -- obj has water
end -- obj size
end -- loopy
end -- loopx
end -- sq is valid?
return nil
end -- function 


function SFarmingSystem:findRainGutter(sq)
if sq then

local x=sq:getX()
local y=sq:getY()
local z=sq:getZ()+1
print ("****************************find -A- RainGutter***************************" .. x .. " ".. y .. " ".. z )

local objs = nil
local barrel = nil
aaa = getCell():getGridSquare(x,y,z)
objs = aaa:getObjects()
if objs:size() > 1 then
	print ("Anzahl Obj größer null:" .. objs:size());
	if objs:get(1):getSprite() then
		barrel = objs:get(1)
		if barrel:getWaterAmount() > 0 then return barrel
		end


end -- are there objs?
end -- can i get a sprite on obj 1?

end -- sq is valid?
return nil
end -- function 








function SFarmingSystem:checkIfGreenhouse(sq)

	print ("check if greenhouse..")
	local windowCounter = sq:getRoom():getWindows():size()
	local squares = sq:getRoom():getSquares()
	local length = squares:size()-1
	for i = 0,length do
		windowCounter = windowCounter + SFarmingSystem:checkRoof( squares:get(i) )
	end
	print("Greenhouse: "..windowCounter.."/"..length)
 	return windowCounter >= length --> greenhousey enough. A 10x10 room would have a max windowCounter of 140
end



function SFarmingSystem:checkWindowsAndGreenhouse(sq)
	print ("check if windows and greenhouse..")
	if sq == nil then 
		print ("sq ist nil - gebe nil zurück")
		return nil 

	end
	--if sq:getRoom() == nil then -- handling already  build houses from the map
	--	print ("cant get a room for this plant")
	--	return false 
	--end


	if self:checkRoof(sq) > 0 then
		print ("It has a glass roof")
		return true
	end


	--[[if self:checkWindows(sq) == true then
		print ("It has Windows")
		return true
	end
	if self:checkIfGreenhouse(sq) == true then
		print ("it has a roof")
		return true
	end
	]]--
	return false
end

----------------------------



function SFarmingSystem:harvest(luaObject, player)

	local props = farming_vegetableconf.props[luaObject.typeOfSeed]
	local numberOfVeg = farming_vegetableconf.getVegetablesNumber(luaObject) 


if player then
	player:sendObjectChange('addItemOfType', { type = props.vegetableName, count = numberOfVeg })
	if luaObject.hasSeed  then 
		player:sendObjectChange('addItemOfType', { type = props.seedName, count = (props.seedPerVeg * numberOfVeg) })
	end
	if props.vegetableName2 and luaObject.nbOfGrow == 7 then 
	player:sendObjectChange('addItemOfType', { type = props.vegetableName2, count = props.numberOfVegetables2 })
	end
end



	luaObject.hasVegetable = false
	luaObject.hasSeed = false


	if props.multiHarvest then
		luaObject.fertilizer = 0;
		luaObject.nbOfGrow = 2
		self:growPlant(luaObject, nil, true)
		luaObject:saveData()
	else
		local sq = luaObject:getSquare()
		self:removePlant(luaObject)
		self:plow(sq)--NEW
	end
end


function SFarmingSystem:getHealth()
	--OLD:
	-- it's better to plant seed during ascending phase of the moon
--	if season.moonCycle >= 4 and season.moonCycle < 18 then -- ascending moon health between 47 and 53
--		return ZombRand(47, 54)
--	elseif season.moonCycle >= 18 and season.moonCycle <= 21 then -- full moon, the best ! health between 57 and 64
--		return ZombRand(57, 64)
--	else -- descending moon, the worst, health between 37 and 44
--		return ZombRand(37, 44)
--	end

	-- NEW: changed because season is deprecated
	return ZombRand(50+CFarmingSystem:getXp()*2, 70)+CFarmingSystem:getXp()*3
end


-- plow the land
function SFarmingSystem:plow(square)
	self:removeTallGrass(square)
	local luaObject = self:newLuaObjectOnSquare(square)
	luaObject:initNew()
	luaObject.exterior = square:isOutside()
	luaObject.hasWindow = self:checkWindowsAndGreenhouse(square) --NEW
	luaObject:addObject()
	self:noise('plowed '..luaObject.x..','..luaObject.y)
	self:noise("#plants="..self:getLuaObjectCount())
end


--new: update custom sprites OnGameStart
function SFarmingSystem:updateSprites()
	local spName="nichts"
	print ("update custom sprites in game start init")
	if not self.system or not farming_vegetableconf then return
	end
	for i=1,self:getLuaObjectCount() do
		local luaObject = self:getLuaObjectByIndex(i)
		if luaObject.typeOfSeed ~= "none" then
			spName=luaObject.typeOfSeed
			print ("update custom sprite:".. spName )
			luaObject:setSpriteName( farming_vegetableconf.getSpriteName(luaObject) )
		end
	end
end

