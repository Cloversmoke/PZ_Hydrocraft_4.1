---------------
-- OVERRIDES -- Seasonal farming
---------------


-- if we have at least 1 farming, display red if you don't have water your plant since more than 60hours
function ISFarmingInfo.getNoWateredSinceColor(plant, lastWatedHour, farmingLevel)
    return nowateredsince_rgb -- EDITED: always display white, this doesn't matter in mod
end


function ISFarmingInfo:render()
	if not self:isPlantValid() then return end
	ISFarmingInfo.temperature = ClimateManager.getInstance():getAirTemperatureForSquare( self.plant:getSquare() )

	local farmingLevel = CFarmingSystem.instance:getXp(self.character)
	ISFarmingInfo.getFertilizerColor(self);
	ISFarmingInfo.getWaterLvlColor(self.plant, farmingLevel);
	-- local lastWatedHour = ISFarmingInfo.getLastWatedHour(self.plant);
	ISFarmingInfo.getTitleColor(self.plant);
	ISFarmingInfo.getHealthColor(self, farmingLevel);
	-- ISFarmingInfo.getNoWateredSinceColor(self, lastWatedHour, farmingLevel);
	local disease = ISFarmingInfo.getDiseaseName(self);
	ISFarmingInfo.getWaterLvlBarColor(self, farmingLevel);
	local top = 69
	local y = top;
	-- icon of the plant
	self:drawTextureScaled(self.vegetable, 20,20,25,25,1,1,1,1);
	-- title of the plant
	if self.plant:getObject() then
		self:drawText(self.plant:getObject():getObjectName(), 60, 25, title_rgb["r"], title_rgb["g"], title_rgb["b"], 1, UIFont.Normal);
	else
		self:drawText("Dead " .. getText("Farming_" .. self.plant.typeOfSeed), 60, 25, title_rgb["r"], title_rgb["g"], title_rgb["b"], 1, UIFont.Normal);
	end
	local fontHgt = getTextManager():getFontFromEnum(UIFont.Normal):getLineHeight()
	local pady = 1
	local lineHgt = fontHgt + pady * 2
	-- background for current growing phase
	self:drawRect(13, y, self.width - 25, lineHgt, 0.1, 1.0, 1.0, 1.0);
	-- text for current growing phase
	self:drawText(getText("Farming_Current_growing_phase") .. " : ", 20, y + pady, 1, 1, 1, 1, UIFont.Normal);
	-- stat (next growing state) on the right
	self:drawTextRight(ISFarmingInfo.getCurrentGrowingPhase(self, farmingLevel), self.width - 17, y + pady, 1, 1, 1, 1, UIFont.Normal);
	y = y + lineHgt;
	self:drawRect(13, y, self.width - 25, lineHgt, 0.05, 1.0, 1.0, 1.0);
	self:drawText(getText("Farming_Next_growing_phase") .. " : ", 20, y + pady, 1, 1, 1, 1, UIFont.Normal);
	self:drawTextRight(ISFarmingInfo.getNextGrowingPhase(self), self.width - 17, y + pady, 1, 1, 1, 1, UIFont.Normal);
	y = y + lineHgt;

	-- EDITED: removed, only water level matters
	-- self:drawRect(13, y, self.width - 25, lineHgt, 0.1, 1.0, 1.0, 1.0);
	-- self:drawText(getText("Farming_Last_time_watered") .. " : ", 20, y + pady, 1, 1, 1, 1, UIFont.Normal);
	-- lastWatedHour = lastWatedHour .. " " .. getText("Farming_Hours");
	-- self:drawTextRight(lastWatedHour, self.width - 17, y + pady, nowateredsince_rgb["r"], nowateredsince_rgb["g"], nowateredsince_rgb["b"], 1, UIFont.Normal);
	-- y = y + lineHgt;
	--NEW: replaced with sunlight info
	self:drawRect(13, y, self.width - 25, lineHgt, 0.1, 1.0, 1.0, 1.0);
	self:drawText("Sunlight: ", 20, y + pady, 1, 1, 1, 1, UIFont.Normal);
	local hasSunlight = ""
	if self.plant.exterior or self.plant.hasWindow then hasSunlight = "Yes" else hasSunlight = "No" end
		self:drawTextRight(hasSunlight, self.width - 17, y + pady, 1,1,1,1, UIFont.Normal);
	y = y + lineHgt;
	------------------------------
	self:drawRect(13, y, self.width - 25, lineHgt, 0.05, 1.0, 1.0, 1.0);
	self:drawText(getText("Farming_Fertilized") .. " : ", 20, y + pady, 1.0, 1.0, 1.0, 1, UIFont.Normal);
	self:drawTextRight(self.plant.fertilizer .. "", self.width - 17, y + pady, fertilizer_rgb["r"], fertilizer_rgb["g"], fertilizer_rgb["b"], 1, UIFont.Normal);
	y = y + lineHgt;
	self:drawRect(13, y, self.width - 25, lineHgt, 0.1, 1.0, 1.0, 1.0);
	self:drawText(getText("Farming_Health") .. " : ", 20, y + pady, 1.0, 1.0, 1.0, 1, UIFont.Normal);
	self:drawTextRight(ISFarmingInfo.getHealth(self, farmingLevel), self.width - 17, y + pady, health_rgb["r"], health_rgb["g"], health_rgb["b"], 1, UIFont.Normal);
	y = y + lineHgt;
	if(disease[1]) then
		self:drawRect(13, y, self.width - 25, lineHgt, 0.05, 1.0, 1.0, 1.0);
		self:drawText(getText("Farming_Disease") .. " : ", 20, y + pady, 1, 1, 1, 1);
		self:drawTextRight(disease[1], self.width - 17, y + pady, disease_rgb["1r"], disease_rgb["1g"], disease_rgb["1b"], 1);
		y = y + lineHgt;
	end
	if(disease[2]) then
		self:drawRect(13, y, self.width - 25, lineHgt, 0.05, 1.0, 1.0, 1.0);
		self:drawTextRight(disease[2], self.width - 17, y + pady, disease_rgb["2r"], disease_rgb["2g"], disease_rgb["2b"], 1);
		y = y + lineHgt;
	end
	if(disease[3]) then
	self:drawRect(13, y, self.width - 25, lineHgt, 0.05, 1.0, 1.0, 1.0);
		self:drawTextRight(disease[3], self.width - 17, y + pady, disease_rgb["3r"], disease_rgb["3g"], disease_rgb["3b"], 1);
		y = y + lineHgt;
	end
	-- rect for all info
	self:drawRectBorder(13, top - 1, self.width - 25, y - top + 2, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
	y = y + 5;
	self:drawText(getText("Farming_Water_levels"), 13, y, 1, 1, 1, 1);
	self:drawTextRight(ISFarmingInfo.getWaterLvl(self.plant, farmingLevel), self.width - 12, y, water_rgb["r"], water_rgb["g"], water_rgb["b"], 1, UIFont.normal);
	y = y + fontHgt + 2;
	-- show the water bar with at least 4 farming skill
	if farmingLevel >= 4 then
		self:drawRect(13, y, self.width - 25, 12, 0.05, 1.0, 1.0, 1.0);
		self:drawRectBorder(13, y, self.width - 25, 12, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
		self:drawRect(14, y + 1, ISFarmingInfo.getWaterBarWidth(self), 10, 1, waterbar_rgb["r"], waterbar_rgb["g"], waterbar_rgb["b"]);
		y = y + 12
	end
	self.parent:setHeight(self.y + y + 8)
end


-- show nothing with 0 farming
-- show text with 2 farming
-- show numbers with 4
function ISFarmingInfo.getCurrentGrowingPhase(info, farmingLevel)
	if farmingLevel >= 2 and farmingLevel <= 4 then
		if info.plant.nbOfGrow < 0 then --EDITED: dead
			return "-";
		elseif info.plant.nbOfGrow <= 2 then
			return getText("Farming_Seedling");
		elseif info.plant.nbOfGrow <= 5 then
			return getText("Farming_Young");
		elseif info.plant.nbOfGrow <= 6 then
			return getText("Farming_Fully_grown");
		else
			return getText("Farming_Ready_to_harvest");
		end
	elseif farmingLevel >= 4 then
		if info.plant.nbOfGrow < 0 then --EDITED: no nbOfGrow if dead
			return "-";
		elseif(info.plant.nbOfGrow > 7) then
			return "7/7";
		end
		return info.plant.nbOfGrow .. "/7";
	end
	return getText("UI_FriendState_Unknown");
end

-- display the hour of the next growing phase if with have at least 6 farmings pts
function ISFarmingInfo.getNextGrowingPhase(info)
	if info.plant.nbOfGrow >= 0 then --EDITED: alive
		if CFarmingSystem.instance:getXp(info.character) >= 6 then
			if info.plant.nextGrowing == 0 then
				return "0 " .. getText("Farming_Hours");
			else
                if(info.plant.nextGrowing - CFarmingSystem.instance.hoursElapsed < 0) then
                    return "0 " .. getText("Farming_Hours");
            end
				return round2((info.plant.nextGrowing - CFarmingSystem.instance.hoursElapsed)) .. " " .. getText("Farming_Hours");
			end
		end
		return getText("UI_FriendState_Unknown");
	end
	return getText("-");
end


-- show the right number with 4 farming skill
function ISFarmingInfo.getWaterLvl(plant, farmingLevel)
	ISFarmingInfo.temperature = ClimateManager.getInstance():getAirTemperatureForSquare( plant:getSquare() )
	if farmingLevel >= 4 then
		if ISFarmingInfo.temperature >= 0 or plant.hasWindow then -- EDITED: info if frozen
			return round2(plant.waterLvl, 2) .. "/100";
		else
			return getText("Farming_Frozen");
		end
	else
		if ISFarmingInfo.temperature < 0 and not plant.hasWindow then -- EDITED: info if frozen
			return getText("Farming_Frozen");
		elseif plant.waterLvl > 80 then
			return getText("Farming_Well_watered");
		elseif plant.waterLvl > 60 then
			return getText("Farming_Fine");
		elseif plant.waterLvl > 40 then
			return getText("Farming_Thirsty");
		elseif plant.waterLvl > 20 then
			return getText("Farming_Dry");
		else
			return getText("Farming_Parched");
		end
	end
end

function ISFarmingInfo.getHealthColor(info, farmingLevel)
	if(info.plant.health >= 60) then
		ISFarmingInfo:getGreen(health_rgb, nil);
	elseif(info.plant.health >= 40) then
		ISFarmingInfo:getOrange(health_rgb, nil);
	else
		ISFarmingInfo:getRed(health_rgb, nil);
	end
end

-- if we have at least 4 farming, display water lvl in color, to help the player
function ISFarmingInfo.getWaterLvlColor(plant, farmingLevel)
	if farmingLevel >= 4 and plant.nbOfGrow >= 0 then
		ISFarmingInfo.temperature = ClimateManager.getInstance():getAirTemperatureForSquare( plant:getSquare() )
		if ISFarmingInfo.temperature < 0 and not plant.hasWindow then -- EDITED: info if frozen
			ISFarmingInfo:getIce(water_rgb);
		else
			local water = farming_vegetableconf.calcWater(plant.waterNeeded, plant.waterLvl);
			local waterMax = farming_vegetableconf.calcWater(plant.waterLvl, plant.waterNeededMax);
			if water >= 0 and waterMax >= 0 then -- green
				ISFarmingInfo:getGreen(water_rgb, nil);
			elseif water == -1 or waterMax == -1 then -- orange
				ISFarmingInfo:getOrange(water_rgb, nil);
			else -- red
				ISFarmingInfo:getRed(water_rgb, nil);
			end
		end
	else
		ISFarmingInfo:getWhite(water_rgb, nil);
    end
    return water_rgb;
end

-- if we have at least 4 farming, display water lvl in color, to help the player
function ISFarmingInfo.getWaterLvlBarColor(info, farmingLevel)
	ISFarmingInfo:getBlueBar(waterbar_rgb);
	if farmingLevel >= 4 then
		ISFarmingInfo.temperature = ClimateManager.getInstance():getAirTemperatureForSquare( info.plant:getSquare() )
		if ISFarmingInfo.temperature < 0 and not info.plant.hasWindow then -- EDITED: info if frozen
			ISFarmingInfo:getIce(waterbar_rgb);
		elseif info.plant.nbOfGrow >= 0 then
			local water = farming_vegetableconf.calcWater(info.plant.waterNeeded, info.plant.waterLvl);
			local waterMax = farming_vegetableconf.calcWater(info.plant.waterLvl, info.plant.waterNeededMax);
			if(water >= 0 and waterMax >= 0) then -- green
				ISFarmingInfo:getBlueBar(waterbar_rgb);
			elseif(water == -1 or waterMax == -1) then -- orange
				ISFarmingInfo:getOrangeBar(waterbar_rgb);
			else -- red
				ISFarmingInfo:getRedBar(waterbar_rgb);
			end
		end
	end
end

--NEW
function ISFarmingInfo:getIce(list)
	list["r"] = 0.5;
	list["g"] = 0.9;
	list["b"] = 1.0;
end