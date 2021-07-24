-- fix for digging behind objects
ISFarmingMenu.canDigHere = function()
	if HCFarmingMenu.secondMenu then
		return false -- return false if this is called a 2nd time in SeasonalFarmingMenu.doFarmingMenu, otherwise "Dig" will show twice
	end

	local x = getMouseXScaled()
	local y = getMouseYScaled()
	local z = getPlayer():getZ()
	wx,wy = ISCoordConversion.ToWorld(x, y, z)
	local sq = getCell():getGridSquare(wx,wy,z)
	if not sq then return false end
	for i=0,sq:getObjects():size()-1 do
		local obj = sq:getObjects():get(i);
		if obj:getTextureName() and (luautils.stringStarts(obj:getTextureName(), "floors_exterior_natural") or luautils.stringStarts(obj:getTextureName(), "blends_natural_01")) then
			return true
		end
	end
	return false
end

--fix anim duration
ISFarmingMenu.onShovel = function(worldobjects, plant, player, sq)
    if not AdjacentFreeTileFinder.isTileOrAdjacent(player:getCurrentSquare(), sq) then
        local adjacent = AdjacentFreeTileFinder.Find(sq, player);
        if adjacent == nil then return end
        ISTimedActionQueue.add(ISWalkToTimedAction:new(player, adjacent));
    end
	local item = ISWorldObjectContextMenu.equip(player, player:getPrimaryHandItem(), ISFarmingMenu.getShovel(player), true);
	
	 --NEW: time
	local time = 50
	if not item then
		time = 1000
		--injure hands
	end
	if item:getType() == "HandShovel" or item:getType() == "HandFork" then
		time = 200
	elseif item:getType() == "GardenHoe" then
		time = 50
	elseif item:getType() == "PickAxe" then
		time = 300
	end
    -- ISTimedActionQueue.add(ISShovelAction:new(player, handItem, plant, 40)); --OLD
    ISTimedActionQueue.add(ISShovelAction:new(player, item, plant, time)); --NEW
end


ISFarmingMenu.doSeedMenu = function(context, plant, sq, playerObj)
	local seedOption = context:addOption(getText("ContextMenu_Sow_Seed"), nil, nil)
	local subMenu = context:getNew(context)
	context:addSubMenu(seedOption, subMenu)

	-- Sort seed types by display name.
	local typeOfSeedList = {}
	for typeOfSeed,props in pairs(farming_vegetableconf.props) do
		table.insert(typeOfSeedList, { typeOfSeed = typeOfSeed, props = props, text = getText("Farming_" .. typeOfSeed) })
	end
	table.sort(typeOfSeedList, function(a,b) return not string.sort(a.text, b.text) end)

	for _,tos in ipairs(typeOfSeedList) do
		local typeOfSeed = tos.typeOfSeed
		local plantWithFruit = farming_vegetableconf.props[typeOfSeed].plantWithFruit
		
		if plantWithFruit then plantWithFruit = farming_vegetableconf.props[typeOfSeed].vegetableName
		plantWithFruit = playerObj:getInventory():getCountTypeRecurse(plantWithFruit)
		end

		--local nbFruitPlant = playerObj:getInventory():getCountTypeRecurse(tos.props.seedName)		
		local option = subMenu:addActionsOption(tos.text, ISFarmingMenu.onSeed, typeOfSeed, plant, sq)
		local nbOfSeed = playerObj:getInventory():getCountTypeRecurse(tos.props.seedName)
		ISFarmingMenu.canPlow(nbOfSeed, typeOfSeed, plantWithFruit, option)
	end
end

ISFarmingMenu.canPlow = function(seedAvailable, typeOfSeed, plantWithFruit, option)
	local tooltip = ISToolTip:new();
	tooltip:initialise();
	tooltip:setVisible(false);
	option.toolTip = tooltip;
	tooltip:setName(getText("Farming_" .. typeOfSeed));
	local result = true;
	tooltip.description = getText("Farming_Tooltip_MinWater") .. farming_vegetableconf.props[typeOfSeed].waterLvl .. "";
	if farming_vegetableconf.props[typeOfSeed].waterLvlMax then
		tooltip.description = tooltip.description .. " <LINE> " .. getText("Farming_Tooltip_MaxWater") ..  farming_vegetableconf.props[typeOfSeed].waterLvlMax;
	end
	tooltip.description = tooltip.description .. " <LINE> " .. getText("Farming_Tooltip_TimeOfGrow") .. math.floor((farming_vegetableconf.props[typeOfSeed].timeToGrow * 7) / 24) .. " " .. getText("IGUI_Gametime_days");
    local waterPlus = "";
    if farming_vegetableconf.props[typeOfSeed].waterLvlMax then
        waterPlus = "-" .. farming_vegetableconf.props[typeOfSeed].waterLvlMax;
    end
    tooltip.description = tooltip.description .. " <LINE> " .. getText("Farming_Tooltip_AverageWater") .. farming_vegetableconf.props[typeOfSeed].waterLvl .. waterPlus;
	local rgb = "";

	if seedAvailable < farming_vegetableconf.props[typeOfSeed].seedsRequired then
		result = false;
		rgb = "<RGB:1,0,0>";
	end
	tooltip.description = tooltip.description .. " <LINE> " .. rgb .. getText("Farming_Tooltip_RequiredSeeds") .. seedAvailable .. "/" .. farming_vegetableconf.props[typeOfSeed].seedsRequired;
	tooltip:setTexture(farming_vegetableconf.props[typeOfSeed].texture);

	if plantWithFruit then 
		if plantWithFruit > 0 then 
			result = true;
			tooltip.description = tooltip.description .. " <LINE> <RGB:1,1,1>" .. getText("Farming_Fruitasseed")
		end
	end

	if not result then
		option.onSelect = nil;
		option.notAvailable = true;
    end
    tooltip:setWidth(170);
end



function ISFarmingMenu.onSeed(playerObj, typeOfSeed, plant, sq)
	if not ISFarmingMenu.isValidPlant(plant) then return end
	if not ISFarmingMenu.walkToPlant(playerObj, sq) then return end


	local playerInv = playerObj:getInventory()
	local props = farming_vegetableconf.props[typeOfSeed]
	local items = playerInv:getSomeTypeRecurse(props.seedName, props.seedsRequired)
	local seeds = {}


	if items:size() >= props.seedsRequired then --plant with seeds
		ISInventoryPaneContextMenu.transferIfNeeded(playerObj, items)
		for i=1,items:size() do
			local item = items:get(i-1)
			table.insert(seeds, items:get(i-1))
		end
		ISTimedActionQueue.add(ISSeedAction:new(playerObj, seeds, props.seedsRequired, typeOfSeed, plant, 40))

	else if props.plantWithFruit then -- plant with fruits
		print ("try plant with:" .. props.vegetableName)
		items = playerInv:getSomeTypeRecurse(props.vegetableName, 1)
		table.insert(seeds, items:get(0))
		ISTimedActionQueue.add(ISSeedAction:new(playerObj, seeds, 1, typeOfSeed, plant, 40))

	end

end
end


--fix anim duration
ISFarmingMenu.onWater = function(worldobjects, uses, handItem, sq, player)
	if player:getPrimaryHandItem() ~= handItem then
		ISTimedActionQueue.add(ISEquipWeaponAction:new(player, handItem, 50, true));
	end
	if not AdjacentFreeTileFinder.isTileOrAdjacent(player:getCurrentSquare(), sq) then
		local adjacent = AdjacentFreeTileFinder.Find(sq, player);
		if adjacent ~= nil then
			ISTimedActionQueue.add(ISWalkToTimedAction:new(player, adjacent));
			ISTimedActionQueue.add(ISWaterPlantAction:new(player, handItem, uses, sq, 30 + 3 * uses));
		end
 	else
		-- ISTimedActionQueue.add(ISWaterPlantAction:new(player, handItem, uses, sq, 20 + (6 * uses))); --OLD
		ISTimedActionQueue.add(ISWaterPlantAction:new(player, handItem, uses, sq, 30 + 3 * uses)); --NEW
	end
end
