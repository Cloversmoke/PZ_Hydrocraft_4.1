--overrides server/farming/SPlantGlobalObject.lua


if isClient() then return end


function SPlantGlobalObject.initModData(modData)
	modData.state = "plow"
	modData.nbOfGrow = -1
	modData.typeOfSeed = "none"
	modData.fertilizer = 0
	modData.mildewLvl = 0
	modData.aphidLvl = 0
	modData.fliesLvl = 0
	modData.waterLvl = 0
	modData.waterNeeded = 0
	modData.waterNeededMax = nil
	modData.lastWaterHour = 0
	modData.hasSeed = false
	modData.hasVegetable = false
	modData.health = SFarmingSystem.instance:getHealth()
	modData.badCare = false--not used in mod
	modData.exterior = true
	modData.hasWindow = false --NEW
	modData.spriteName = "vegetation_farming_01_1"
	modData.objectName = getText("Farming_Plowed_Land");
end

--every 2h
function SPlantGlobalObject:lowerWaterLvl()
	local temperature = ClimateManager.getInstance():getAirTemperatureForSquare( self:getSquare() )
	if temperature > 0 then
		if self.state == "seeded" then
			self.waterLvl = self.waterLvl - 0.5 -- some water gets absorbed by the plant, 0.75/h, -18/day
		else
			self.waterLvl = self.waterLvl - 0.25
		end
	end
	if temperature > 25 then
		self.waterLvl = self.waterLvl - (temperature-25) / 10 -- -1/h, -24/day at 35C
	end
	-- flies make water dry more quickly
	self.waterLvl = self.waterLvl - self.fliesLvl / 70 -- -1/h, -24/day at max flies
	if self.waterLvl < 0 then
		self.waterLvl = 0
	end

	self:setObjectName(farming_vegetableconf.getObjectName(self))
	self:saveData()

end


-- fertilize the plant, more than 4 doses and your plant die ! (no mercy !)
function SPlantGlobalObject:fertilize(fertilizer)
	if self.state == "seeded" then
		if self.fertilizer < 4  then
			self.fertilizer = self.fertilizer + 1
			-- self.nextGrowing = self.nextGrowing - 20 --OLD
			self.nextGrowing = CFarmingSystem.instance.hoursElapsed + (self.nextGrowing-CFarmingSystem.instance.hoursElapsed) * (0.89+self.fertilizer/100) --NEW: no fixed value
			if self.nextGrowing < 1 then
				self.nextGrowing = 1
			end
		else -- too much fertilizer and our plant die !
			self:rottenThis()
		end
		self:saveData()
	end
end

-- EDITED: removed instant death
function SPlantGlobalObject:checkStat()
	if self.waterLvl < 0 then
		self.waterLvl = 0
	elseif self.waterLvl > 100 then
		self.waterLvl = 100
	end
	if self.health < 0 then
		self.health = 0
	elseif self.health > 100 then
		self.health = 100
	end
end


--EDITED: not hardcoded
function SPlantGlobalObject:rottenThis()
	self.state = "rotten"
	self.nextGrowing = SFarmingSystem.instance.hoursElapsed + 60
	self:setObjectName(farming_vegetableconf.getObjectName(self))
	self:setSpriteName(farming_vegetableconf.getSpriteName(self))
	self.nbOfGrow = -1 --TODO: wont work on reload, fixme
	self:deadPlant()
	self:saveData()

end

--EDITED: not hardcoded
function SPlantGlobalObject:dryThis()
	self.state = "dry"
	self.nextGrowing = SFarmingSystem.instance.hoursElapsed + 60
	self:setObjectName(farming_vegetableconf.getObjectName(self))
	self:setSpriteName(farming_vegetableconf.getSpriteName(self))
	self.nbOfGrow = -1
	self:deadPlant()
	self:saveData()
end

--EDITED: not hardcoded
function SPlantGlobalObject:destroyThis()
	self.state = "destroy"
	self.nextGrowing = SFarmingSystem.instance.hoursElapsed + 60
	self:setObjectName(farming_vegetableconf.getObjectName(self))
	self:setSpriteName(farming_vegetableconf.getSpriteName(self))
	self.nbOfGrow = -1
	self:deadPlant()
	self:saveData()
end

--NEW
--similar to the original :deadPlant()
--dead plants "grow" to this stage
--heavy rain can destroy plows
--destroyed plows will eventually get removed by rain/snow
function SPlantGlobalObject:destroyPlow()
	self.state = "destroyedPlow"
	self.nbOfGrow = -2
	self.nextGrowing = nil
	self.waterLvl = 0
	self.mildewLvl =0
	self.aphidLvl = 0
	self.fliesLvl = 0
	self.health = 0
	self:setObjectName(farming_vegetableconf.getObjectName(self))
	self:setSpriteName(farming_vegetableconf.getSpriteName(self))
	self:deadPlant()
	self:saveData()
end

function SPlantGlobalObject:isAlive()
	return self.nbOfGrow >= 0
end



function SPlantGlobalObject:fromModData(modData)
	self.state = modData.state
	self.nbOfGrow = modData.nbOfGrow
	self.typeOfSeed = modData.typeOfSeed
	self.fertilizer = modData.fertilizer
	self.mildewLvl = modData.mildewLvl
	self.aphidLvl = modData.aphidLvl
	self.fliesLvl = modData.fliesLvl
	self.waterLvl = modData.waterLvl
	self.waterNeeded = modData.waterNeeded
	self.waterNeededMax = modData.waterNeededMax
	self.lastWaterHour = modData.lastWaterHour
	self.nextGrowing = modData.nextGrowing
	self.hasSeed = modData.hasSeed == "true" or modData.hasSeed == true
	self.hasVegetable = modData.hasVegetable == "true" or modData.hasVegetable == true
	self.health = modData.health
	self.badCare = modData.badCare == "true" or modData.badCare == true
	self.exterior = modData.exterior == true or modData.exterior == nil
	self.hasWindow = modData.hasWindow == true
	self.spriteName = modData.spriteName
	self.objectName = modData.objectName
end

function SPlantGlobalObject:toModData(modData)
	modData.state = self.state
	modData.nbOfGrow = self.nbOfGrow
	modData.typeOfSeed = self.typeOfSeed
	modData.fertilizer = self.fertilizer
	modData.mildewLvl = self.mildewLvl
	modData.aphidLvl = self.aphidLvl
	modData.fliesLvl = self.fliesLvl
	modData.waterLvl = self.waterLvl
	modData.waterNeeded = self.waterNeeded
	modData.waterNeededMax = self.waterNeededMax
	modData.lastWaterHour = self.lastWaterHour
	modData.nextGrowing = self.nextGrowing
	modData.hasSeed = self.hasSeed
	modData.hasVegetable = self.hasVegetable
	modData.health = self.health
	modData.badCare = self.badCare
	modData.exterior = self.exterior
	modData.hasWindow = self.hasWindow
	modData.spriteName = self.spriteName
	modData.objectName = self.objectName
end
