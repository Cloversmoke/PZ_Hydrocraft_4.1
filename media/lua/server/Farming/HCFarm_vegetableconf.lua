--overwrites server/Farming/farming_vegetableconf.lua  

farming_vegetableconf = {}

farming_vegetableconf.growthMultiplier = 2 
if SandboxVars.Farming == 1 then farming_vegetableconf.growthMultiplier = 4; -- very fast
elseif SandboxVars.Farming == 2 then farming_vegetableconf.growthMultiplier = 3; -- fast
elseif SandboxVars.Farming == 4 then farming_vegetableconf.growthMultiplier = 1.5; -- slow
elseif SandboxVars.Farming == 5 then farming_vegetableconf.growthMultiplier = 1; -- very slow
end

farming_vegetableconf.harvestMultiplier = 1
if SandboxVars.PlantAbundance == 1 then farming_vegetableconf.harvestMultiplier = 0.5; -- very poor
elseif SandboxVars.PlantAbundance == 2 then farming_vegetableconf.harvestMultiplier = 0.75; -- poor
elseif SandboxVars.PlantAbundance == 4 then farming_vegetableconf.harvestMultiplier = 1.5; -- abundant
elseif SandboxVars.PlantAbundance == 5 then farming_vegetableconf.harvestMultiplier = 2; -- very abundant
end

farming_vegetableconf.growPlant = function(luaObject)
	luaObject.nbOfGrow = luaObject.nbOfGrow + 1
	local nbOfGrow = luaObject.nbOfGrow;
	local props = farming_vegetableconf.props[luaObject.typeOfSeed]

	if nbOfGrow <= 7 then -- keep growing
		luaObject = growNext(luaObject);
		if nbOfGrow == 1 then -- start
			luaObject.waterNeeded = props.waterLvl
			luaObject.waterNeededMax = 100
		elseif (nbOfGrow <= 5) then luaObject.waterNeededMax = props.waterLvlMax -- young
		elseif (nbOfGrow == 6) then luaObject.hasVegetable = true; -- mature
		elseif (nbOfGrow == 7) then -- mature with seed
		    luaObject.hasVegetable = true;
            luaObject.hasSeed = true;	
		end
	
	elseif (luaObject.state ~= "rotten") then luaObject:rottenThis(); -- rot at stage 7
	end

	return luaObject;
end

function growNext(luaObject)
	local props = farming_vegetableconf.props[luaObject.typeOfSeed]
	local timeToGrow = ZombRand(props.timeToGrow*0.95, props.timeToGrow*1.05)
	timeToGrow = timeToGrow + timeToGrow * (1-luaObject.health/100) * 0.3 -- unhealthy plants take up to 30% longer to grow
	for i=1,luaObject.fertilizer do -- -10% -9% -8% -7% growth time
		timeToGrow = timeToGrow * (0.89+luaObject.fertilizer/100)
	end
	luaObject.nextGrowing = SFarmingSystem.instance.hoursElapsed + timeToGrow / farming_vegetableconf.growthMultiplier

	luaObject:setObjectName( farming_vegetableconf.getObjectName(luaObject) )
	luaObject:setSpriteName( farming_vegetableconf.getSpriteName(luaObject) )

	return luaObject
end

-- return the number of vegtables you harvest
farming_vegetableconf.getVegetablesNumber = function(luaObject)

	local healthMultiplier = 1
	if luaObject.health < 50 then -- low health lowers harvest
		healthMultiplier = 0.5 + luaObject.health/100 -- 50% at 0 health 
	end

	local sicknessMultiplier = 1
	sicknessMultiplier = sicknessMultiplier * (1 - luaObject.aphidLvl/50) -- aphid lowers harvest, 50% at max aphid
	sicknessMultiplier = sicknessMultiplier * (1 - luaObject.mildewLvl/50) -- mildrew lowers harvest, 50% at max aphid
	
	local props = farming_vegetableconf.props[luaObject.typeOfSeed]

	local nbOfVegetable = props.numberOfVegetables
	if luaObject.nbOfGrow == 7 then nbOfVegetable = props.seedBearingVegetables
	end

	nbOfVegetable = ZombRand(nbOfVegetable*0.8, nbOfVegetable*1.2)
	nbOfVegetable = nbOfVegetable * farming_vegetableconf.harvestMultiplier -- Sandbox setting
	nbOfVegetable = nbOfVegetable * healthMultiplier -- up to 50% less veggies total
	local nbOfVegetableRotten = nbOfVegetable * (1-sicknessMultiplier); -- up to 75% rotten veggies

	nbOfVegetable = nbOfVegetable - nbOfVegetableRotten
	if nbOfVegetable < 0 then nbOfVegetable = 0 end

	nbOfVegetable = math.floor(nbOfVegetable+0.5) -- no math.round T.T

	return nbOfVegetable
	
end


function getVegetablesNumber(luaObject) farming_vegetableconf.getVegetablesNumber(luaObject) end -- for compatibility


-- fetch our item in the container, if it's the vegetable we want, we add seeds to it
function getNbOfSeed(nbOfSeed, typeOfPlant, container)
	local result = 0;
	for i = 0, container:getItems():size() - 1 do
		local item = container:getItems():get(i);
		if item:getType() == typeOfPlant then
			result = result + nbOfSeed;
		end
	end
	return result;
end

-- get sprite
farming_vegetableconf.getSpriteName = function(luaObject)

	if luaObject.state == "plow" then return "vegetation_farming_01_1"
	elseif luaObject.state == "seeded" then return farming_vegetableconf.sprite[luaObject.typeOfSeed][luaObject.nbOfGrow] 
	elseif luaObject.state == "rotten" then 
		if luaObject.nbOfGrow >= 4 then return farming_vegetableconf.sprite[luaObject.typeOfSeed][8] or "vegetation_farming_01_13"
		else return farming_vegetableconf.sprite[luaObject.typeOfSeed][11] or "vegetation_farming_01_5"
		end
	elseif luaObject.state == "dry" then
		if luaObject.nbOfGrow >= 4 then return farming_vegetableconf.sprite[luaObject.typeOfSeed][9] or "vegetation_farming_01_5"
		else return farming_vegetableconf.sprite[luaObject.typeOfSeed][11] or "vegetation_farming_01_5"
		end
	elseif luaObject.state == "destroy" then
		if luaObject.nbOfGrow >= 4 then return farming_vegetableconf.sprite[luaObject.typeOfSeed][10] or "vegetation_farming_01_13"
		else return farming_vegetableconf.sprite[luaObject.typeOfSeed][11] or "vegetation_farming_01_13"
		end
	elseif luaObject.state == "destroyedPlow" then
		return "vegetation_farming_01_13"
	end
	return "ERROR"
end

-- get the object name depending on his current phase
farming_vegetableconf.getObjectName = function(luaObject)
	local props = farming_vegetableconf.props[luaObject.typeOfSeed]

	if luaObject.state == "plow" then 			return getText("Farming_Plowed_Land") end
	if luaObject.state == "rotten" then 		return getText("Farming_Rotten") .. " " .. getText("Farming_" .. luaObject.typeOfSeed) end
	if luaObject.state == "dry" then 			return getText("Farming_Receding") .. " " .. getText("Farming_" .. luaObject.typeOfSeed) end
	if luaObject.state == "destroy" then 		return getText("Farming_Destroyed") .. " " .. getText("Farming_" .. luaObject.typeOfSeed) end
	if luaObject.state == "destroyedPlow" then 	return getText("Farming_Destroyed") .. " " .. getText("Farming_" .. luaObject.typeOfSeed) end

		print ("setting custom status name for crop")
		if luaObject.nbOfGrow <= 2 then return getText("Farming_Seedling").. " ".. getText("Farming_" .. luaObject.typeOfSeed) end
		if luaObject.nbOfGrow <= 5 then return getText("Farming_Young").." ".. 	   getText("Farming_" .. luaObject.typeOfSeed) end
		if luaObject.nbOfGrow == 6 then
			if props.seedPerVeg > 0 then return getText("Farming_In_bloom").." ".. getText("Farming_" ..luaObject.typeOfSeed) 
			else return getText("Farming_Ready_for_Harvest").." "..	getText("Farming_" ..luaObject.typeOfSeed)
			end
		end
		if luaObject.nbOfGrow == 7 then
			if props.seedPerVeg > 0 then return getText("Farming_Seed-bearing").." ".. getText("Farming_" ..luaObject.typeOfSeed) 
			else return getText("Farming_Fully_grown").." ".. getText("Farming_" ..luaObject.typeOfSeed) 
			end
		end
	return "Mystery Plant" -- this shouldn't happen, only 7 growth stages
end


-- now only used to calc color in menu
farming_vegetableconf.calcWater = function(waterMin, waterLvl)
	if waterLvl >= waterMin then -- water lvl is > of our waterMin, it's ok, your plant can grow !
		return 0;
	elseif waterLvl >= waterMin * 0.7 then -- waterLvl is < 30% less than required waterLvl
		return -1; -- waterLvl is > 30% less than requiredLvl
	else 
		return -2;
	end
end
-- now only used to calc color in menu
farming_vegetableconf.calcDisease = function(diseaseLvl)
	if diseaseLvl < 10 then -- < 10 it's ok
		return 0;
	elseif diseaseLvl < 30 then
		return diseaseLvl;
	elseif diseaseLvl < 60 then
		return -1;
	else
		return -2;
	end
end
-- not used anymore 
function badPlant(water, waterMax, diseaseLvl, plant, nextGrowing, updateNbOfGrow) end




--TODO: get masks for mouseover
local function loadSprites(spriteManager)
	for k,cropSprites in pairs(farming_vegetableconf.sprite) do
		for i,cropSprite in pairs(cropSprites) do
			if cropSprite then
				local path = "media/textures/farming/"..cropSprite..".png"
				if spriteManager:getSprite(path) then
					farming_vegetableconf.sprite[k][i] = spriteManager:getSprite(path)
					farming_vegetableconf.sprite[k][i] = cropSprite
				end
			end
		end
	end
	-- SFarmingSystem.instance:updateSprites()
end
Events.OnLoadedTileDefinitions.Add(loadSprites)

--custom sprites aren't displayed at first, so update everthing manually onGameStart
local function OnGameStart()
	SFarmingSystem.instance:updateSprites()
end
Events.OnGameStart.Add(OnGameStart)


farming_vegetableconf.icons = {}
farming_vegetableconf.icons["Carrots"] = "Item_Carrots"
farming_vegetableconf.icons["Broccoli"] = "Item_Broccoli"
farming_vegetableconf.icons["Radishes"] = "Item_TZ_LRRadish"
farming_vegetableconf.icons["Strawberry plant"] = "Item_TZ_Strewberry"
farming_vegetableconf.icons["Tomato"] = "Item_TZ_Tomato"
farming_vegetableconf.icons["Potatoes"] = "Item_TZ_Potato"
farming_vegetableconf.icons["Cabbages"] = "Item_TZ_CabbageLettuce"
farming_vegetableconf.icons["Onion"] = "Item_Onion"
farming_vegetableconf.icons["Hemp"] = "media/textures/Item_HCHempbudfresh.png"
farming_vegetableconf.icons["Grapes"] = "Item_Grapes"
farming_vegetableconf.icons["Lettuce"] = "Item_Lettuce"
farming_vegetableconf.icons["Corn"] = "Item_Corn"
farming_vegetableconf.icons["Wheat"] = "media/textures/Item_HCWheatBundle.png"
farming_vegetableconf.icons["Peanut"] = "Item_Peanut"
farming_vegetableconf.icons["Flax"] = "media/textures/Item_HCFlaxflower.png"
farming_vegetableconf.icons["CoffeeBeans"] = "media/textures/Item_HCBeans.png"
farming_vegetableconf.icons["Sunflower"] = "Item_SunflowerSeeds"
farming_vegetableconf.icons["SoyBeans"] = "media/textures/Item_HCBeanseeds.png"
farming_vegetableconf.icons["Mulberries"] = "media/textures/Item_HCMulberry.png"

farming_vegetableconf.props = {}

-- Carrots
farming_vegetableconf.props["Carrots"] = {
	id = "Carrot",
	vegetableName = "Base.Carrots",
	vegetableName2 = "",
	numberOfVegetables2 = 0,
	seedName = "farming.CarrotSeed",
	seedsRequired = 5,
	plantWithFruit = true,
	texture = "vegetation_farming_01_38",
	waterLvl = 70,
	waterLvlMax = 100,
	timeToGrow = 72,
	numberOfVegetables = 10,
	seedBearingVegetables = 5,
	seedPerVeg = 10,
	seedCollect = 0,
	minTemp = 10,
	bestTemp = 20,
	maxTemp = 35,
	damageFromStorm = false
}
-- Broccoli
farming_vegetableconf.props["Broccoli"] = {
	id = "Broccoli",
	vegetableName = "Base.Broccoli",
	vegetableName2 = "",
	numberOfVegetables2 = 0,
	seedName = "farming.BroccoliSeed",
	seedsRequired = 5,
	plantWithFruit = false,
	waterLvl = 70,
	waterLvlMax = 100,
	texture = "vegetation_farming_01_30",
	timeToGrow = 144,
	numberOfVegetables = 12,
	seedBearingVegetables = 3,
	multiHarvest = false,
	seedPerVeg = 15,
	seedCollect = 0,
	minTemp = 0,
	bestTemp = 15,
	maxTemp = 35,
	damageFromStorm = false
}
-- Radishes
farming_vegetableconf.props["Radishes"] = {
	id = "RedRadish",
	vegetableName = "farming.RedRadish",
	vegetableName2 = "",
	numberOfVegetables2 = 0,
	seedName = "farming.RedRadishSeed",
	seedsRequired = 5,
	plantWithFruit = true,
	texture = "vegetation_farming_01_54",
	waterLvl = 70,
	waterLvlMax = 100,
	timeToGrow = 90,
	numberOfVegetables = 15,
	seedBearingVegetables = 5,
	multiHarvest = false,
	seedPerVeg = 10,
	seedCollect = 0,
	minTemp = 0,
	bestTemp = 15,
	maxTemp = 35,
	damageFromStorm = false
}
-- Strawberry
farming_vegetableconf.props["Strawberry plant"] = {
	id = "Strewberrie",
	vegetableName = "farming.Strewberrie",
	vegetableName2 = "",
	numberOfVegetables2 = 0,
	seedName = "farming.StrewberrieSeed",
	seedsRequired = 5,
	plantWithFruit = true,
	texture = "vegetation_farming_01_62",
	waterLvl = 100,
	waterLvlMax = 100,
	timeToGrow = 200,
	numberOfVegetables = 10,
	seedBearingVegetables = 15,
	multiHarvest = true,
	seedPerVeg = 0,
	seedCollect = 15,
	minTemp = 10,
	bestTemp = 20,
	maxTemp = 30,
	damageFromStorm = true
}
-- Tomatos
farming_vegetableconf.props["Tomato"] = {
	id = "Tomato",
	vegetableName = "farming.Tomato",
	vegetableName2 = "",
	numberOfVegetables2 = 0,
	seedName = "farming.TomatoSeed",
	seedsRequired = 5,
	plantWithFruit = true,
	texture = "vegetation_farming_01_70",
	waterLvl = 45,
	waterLvlMax = 100,
	timeToGrow = 200,
	numberOfVegetables = 10,
	seedBearingVegetables = 15,
	multiHarvest = true,
	seedPerVeg = 0,
	seedCollect = 25,
	minTemp = 10,
	bestTemp = 25,
	maxTemp = 35,
	damageFromStorm = true
}
-- Potatoes
farming_vegetableconf.props["Potatoes"] = {
	id = "Potato",
	vegetableName = "farming.Potato",
	vegetableName2 = "",
	numberOfVegetables2 = 0,
	seedName = "farming.PotatoSeed",
	seedsRequired = 5,
	plantWithFruit = true,
	texture = "vegetation_farming_01_46",
	waterLvl = 45,
	waterLvlMax = 100,
	timeToGrow = 150,
	numberOfVegetables = 10,
	seedBearingVegetables = 8,
	multiHarvest = false,
	seedPerVeg = 5,
	seedCollect = 0,
	minTemp = 5,
	bestTemp = 20,
	maxTemp = 35,
	damageFromStorm = false
}
-- Cabbage Lettuce
farming_vegetableconf.props["Cabbages"] = {
	id = "Cabbage",
	vegetableName = "farming.Cabbage",
	vegetableName2 = "",
	numberOfVegetables2 = 0,
	seedName = "farming.CabbageSeed",
	seedsRequired = 5,
	plantWithFruit = false,
	texture = "vegetation_farming_01_21",
	waterLvl = 70,
	waterLvlMax = 100,
	timeToGrow = 180,
	numberOfVegetables = 10,
	seedBearingVegetables = 5,
	multiHarvest = true,
	seedPerVeg = 10,
	seedCollect = 0,
	minTemp = 3,
	bestTemp = 15,
	maxTemp = 25,
	damageFromStorm = true
}
-- Onion
farming_vegetableconf.props["Onion"] = {
	id = "Onion",
	vegetableName = "Base.Onion",
	vegetableName2 = "",
	numberOfVegetables2 = 0,
	seedName = "Hydrocraft.HCOnionseeds",
	seedsRequired = 5,
	plantWithFruit = true,
	texture = "hcFarmingOnion06_0",
	waterLvl = 45,
	waterLvlMax = 100,
	timeToGrow = 90,
	numberOfVegetables = 15,
	seedBearingVegetables = 5,
	multiHarvest = false,
	seedPerVeg = 15,
	seedCollect = 0,
	minTemp = 5,
	bestTemp = 20,
	maxTemp = 35,
	damageFromStorm = true
}
farming_vegetableconf.props["Corn"] = {
	id = "Corn", 
	vegetableName = "Base.Corn",
	vegetableName2 = "",
	numberOfVegetables2 = 0,
	seedName = "Hydrocraft.HCCornseeds",
	seedsRequired = 10,
	plantWithFruit = true,
	texture = "vegetation_farming_01_77",
	waterLvl = 70,
	waterLvlMax = 100,
	timeToGrow = 250,
	numberOfVegetables = 10,
	seedBearingVegetables = 15,
	multiHarvest = false,
	seedPerVeg = 0,
	seedCollect = 0,
	minTemp = 10,
	bestTemp = 25,
	maxTemp = 35,
	damageFromStorm = true
}
-- Wheat
farming_vegetableconf.props["Wheat"] = {
	id = "Wheat",
	vegetableName = "Hydrocraft.HCWheatBundle",
	vegetableName2 = "",
	numberOfVegetables2 = 0,
	seedName = "Hydrocraft.HCWheat",
	seedsRequired = 2,
	plantWithFruit = false,
	texture = "hcFarmingWheat06_0",
	waterLvl = 45,
	waterLvlMax = 100,
	timeToGrow = 250,
	numberOfVegetables = 10,
	seedBearingVegetables = 15,
	multiHarvest = false,
	seedPerVeg = 0,
	seedCollect = 0,
	minTemp = 10,
	bestTemp = 20,
	maxTemp = 35,
	damageFromStorm = true
}
-- Hemp
farming_vegetableconf.props["Hemp"] = {
	id = "Hemp",
	vegetableName = "Hydrocraft.HCHempbudfresh",
	vegetableName2 = "",
	numberOfVegetables2 = 0,
	seedName = "Hydrocraft.HCHempseeds",
	seedsRequired = 5,
	plantWithFruit = false,
	texture = "media/textures/farming/hemp6.png",
	waterLvl = 45,
	waterLvlMax = 100,
	timeToGrow = 300,
	numberOfVegetables = 10,
	seedBearingVegetables = 2,
	multiHarvest = false,
	seedPerVeg = 20,
	seedCollect = 1,
	minTemp = 10,
	bestTemp = 25,
	maxTemp = 35,
	damageFromStorm = true
} -- 250
-- Grapes (red)
farming_vegetableconf.props["Grapes"] = {
	id = "Grapes",
	vegetableName = "Base.Grapes",
	vegetableName2 = "Base.GrapeLeaves",
	numberOfVegetables2 = 10,
	seedName = "Hydrocraft.HCGrapeseeds",
	seedsRequired = 2,
	plantWithFruit = true,
	texture = "hcFarmingGrapes06_0",
	waterLvl = 45,
	waterLvlMax = 100,
	timeToGrow = 250,
	numberOfVegetables = 10,
	seedBearingVegetables = 15,
	multiHarvest = true,
	seedPerVeg = 0,
	seedCollect = 3,
	minTemp = 10,
	bestTemp = 25,
	maxTemp = 35,
	damageFromStorm = true
}
-- Lettuce 
farming_vegetableconf.props["Lettuce"] = {
	id = "Lettuce",
	vegetableName = "Base.Lettuce",
	vegetableName2 = "",
	numberOfVegetables2 = 0,
	seedName = "Hydrocraft.HCLettuceseeds",
	seedsRequired = 2,
	plantWithFruit = false,	
	texture = "hcFarmingLettuce06_0",
	waterLvl = 45,
	waterLvlMax = 100,
	timeToGrow = 144,
	numberOfVegetables = 10,
	seedBearingVegetables = 3,
	multiHarvest = false,
	seedPerVeg = 10,
	seedCollect = 0,
	minTemp = 5,
	bestTemp = 20,
	maxTemp = 35,
	damageFromStorm = true
}
-- Peanut 
farming_vegetableconf.props["Peanut"] = {
	id = "Peanut",
	vegetableName = "Base.Peanuts",
	vegetableName2 = "",
	numberOfVegetables2 = 0,
	seedName = "Hydrocraft.HCPeanutseeds",
	seedsRequired = 5,
	plantWithFruit = true,
	texture = "hcFarmingPeanut06_0",
	waterLvl = 45,
	waterLvlMax = 100,
	timeToGrow = 144,
	numberOfVegetables = 8,
	seedBearingVegetables = 13,
	multiHarvest = false,
	seedPerVeg = 0,
	seedCollect = 0,
	minTemp = 15,
	bestTemp = 20,
	maxTemp = 35,
	damageFromStorm = true
}
-- Flax 
farming_vegetableconf.props["Flax"] = {
	id = "Flax",
	vegetableName = "Hydrocraft.HCFlaxflower",
	vegetableName2 = "",
	numberOfVegetables2 = 0,
	seedName = "Hydrocraft.HCFlaxseeds",
	seedsRequired = 5,
	plantWithFruit = true,
	texture = "hcFarmingFlax06_0",
	waterLvl = 45,
	waterLvlMax = 100,
	timeToGrow = 144,
	numberOfVegetables = 10,
	seedBearingVegetables = 11,
	multiHarvest = false,
	seedPerVeg = 15,
	seedCollect = 0,
	minTemp = 10,
	bestTemp = 25,
	maxTemp = 35,
	damageFromStorm = true
}


-- CoffeeBeans 
farming_vegetableconf.props["CoffeeBeans"] = {
	id = "CoffeeBeans",
	vegetableName = "Hydrocraft.HCCoffeeBeans",
	vegetableName2 = "",
	numberOfVegetables2 = 0,
	seedName = "Hydrocraft.HCCoffeeBeans",
	seedsRequired = 1,
	plantWithFruit = true,
	texture = "hcFarmingCoffebean06_0",
	waterLvl = 45,
	waterLvlMax = 100,
	timeToGrow = 200,
	numberOfVegetables = 8,
	seedBearingVegetables = 13,
	multiHarvest = false,
	seedPerVeg = 0,
	seedCollect = 0,
	minTemp = 15,
	bestTemp = 25,
	maxTemp = 35,
	damageFromStorm = true
}


-- Sunflower 
farming_vegetableconf.props["Sunflower"] = {
	id = "Sunflower",
	vegetableName = "Hydrocraft.HCSunflower",
	vegetableName2 = "",
	numberOfVegetables2 = 0,
	seedName = "Base.SunflowerSeeds",
	seedsRequired = 5,
	plantWithFruit = true,
	texture = "hcFarmingSunflower06_0",
	waterLvl = 45,
	waterLvlMax = 100,
	timeToGrow = 180,
	numberOfVegetables = 4,
	seedBearingVegetables = 5,
	multiHarvest = true,
	seedPerVeg = 0,
	seedCollect = 15,
	minTemp = 15,
	bestTemp = 20,
	maxTemp = 35,
	damageFromStorm = true
}

-- SoyBeans 
farming_vegetableconf.props["SoyBeans"] = {
	id = "SoyBeans",
	vegetableName = "Hydrocraft.HCSoyBeans",
	vegetableName2 = "",
	numberOfVegetables2 = 0,
	seedName = "Hydrocraft.HCSoyBeans",
	seedsRequired = 2,
	plantWithFruit = true,
	texture = "hcFarmingSoyBeans06_0",
	waterLvl = 45,
	timeToGrow = 180,
	timeToGrow = 0,
	numberOfVegetables = 10,
	seedBearingVegetables = 15,
	multiHarvest = false,
	seedPerVeg = 0,
	seedCollect = 0,
	minTemp = 17,
	bestTemp = 26,
	maxTemp = 35,
	damageFromStorm = true
}


-- Mulberries 
farming_vegetableconf.props["Mulberries"] = {
	id = "Mulberries",
	vegetableName = "Hydrocraft.HCMulberry",
	vegetableName2 = "Hydrocraft.HCMulberryleaf",
	numberOfVegetables2 = 5,
	seedName = "Hydrocraft.HCPottedmulberrysmall",
	seedsRequired = 1,
	plantWithFruit = false,
	texture = "hcFarmingMulberries06_0",
	waterLvl = 45,
	waterLvlMax = 100,
	timeToGrow = 180,
	numberOfVegetables = 8,
	seedBearingVegetables = 10,
	multiHarvest = true,
	seedPerVeg = 0,
	seedCollect = 10,
	minTemp = 3,
	bestTemp = 25,
	maxTemp = 35,
	damageFromStorm = false
}




farming_vegetableconf.sprite = {}
farming_vegetableconf.sprite["Carrots"] = {
"vegetation_farming_01_32",
"vegetation_farming_01_33",
"vegetation_farming_01_34",
"vegetation_farming_01_35",
"vegetation_farming_01_36",
"vegetation_farming_01_38",
"vegetation_farming_01_37",
"vegetation_farming_01_39",--rotten --looks like this entry never gets used in the original?
"vegetation_farming_01_39",--dry
-- "vegetation_farming_01_13"--rotten original
}
farming_vegetableconf.sprite["Broccoli"] = {
"vegetation_farming_01_24",
"vegetation_farming_01_25",
"vegetation_farming_01_26",
"vegetation_farming_01_27",
"vegetation_farming_01_28",
"vegetation_farming_01_30",
"vegetation_farming_01_29",
"vegetation_farming_01_31",
"vegetation_farming_01_31",
-- "vegetation_farming_01_23"--rotten original
}
farming_vegetableconf.sprite["Radishes"] = {
"vegetation_farming_01_48",
"vegetation_farming_01_49",
"vegetation_farming_01_50",
"vegetation_farming_01_51",
"vegetation_farming_01_52",
"vegetation_farming_01_54",
"vegetation_farming_01_53",
"vegetation_farming_01_55",
"vegetation_farming_01_39",
}
farming_vegetableconf.sprite["Strawberry plant"] = {
"vegetation_farming_01_56",
"vegetation_farming_01_57",
"vegetation_farming_01_58",
"vegetation_farming_01_59",
"vegetation_farming_01_60",
"vegetation_farming_01_61",
"vegetation_farming_01_62",
"vegetation_farming_01_63",
"vegetation_farming_01_63"
}
farming_vegetableconf.sprite["Tomato"] = {
"vegetation_farming_01_64",
"vegetation_farming_01_65",
"vegetation_farming_01_66",
"vegetation_farming_01_67",
"vegetation_farming_01_68",
"vegetation_farming_01_69",
"vegetation_farming_01_70",
"vegetation_farming_01_71",--rotten
"vegetation_farming_01_71",--dry
"vegetation_farming_01_14",--destroyed
"vegetation_farming_01_6",--died young
}
farming_vegetableconf.sprite["Potatoes"] = {
"vegetation_farming_01_40",
"vegetation_farming_01_41",
"vegetation_farming_01_42",
"vegetation_farming_01_43",
"vegetation_farming_01_44",
"vegetation_farming_01_46",
"vegetation_farming_01_45",
"vegetation_farming_01_47",
"vegetation_farming_01_47",
}
farming_vegetableconf.sprite["Cabbages"] = {
"vegetation_farming_01_16",
"vegetation_farming_01_17",
"vegetation_farming_01_18",
"vegetation_farming_01_19",
"vegetation_farming_01_20",
"vegetation_farming_01_22",
"vegetation_farming_01_21",
"vegetation_farming_01_23",
"vegetation_farming_01_23",
-- "vegetation_farming_01_31"--rotten original
}
farming_vegetableconf.sprite["Onion"] = {
	"hcFarmingOnion00_0",
	"hcFarmingOnion01_0",
	"hcFarmingOnion02_0",
	"hcFarmingOnion03_0",
	"hcFarmingOnion04_0",
	"hcFarmingOnion05_0",
	"hcFarmingOnion06_0",
	"hcFarmingOnion07_0",--rotten 
	"hcFarmingOnion07_0",--dried
}
farming_vegetableconf.sprite["Corn"] = {
	"vegetation_farming_01_72",
	"vegetation_farming_01_73",
	"vegetation_farming_01_74",
	"vegetation_farming_01_75",
	"vegetation_farming_01_76",
	"vegetation_farming_01_77",
	"vegetation_farming_01_78",
	"vegetation_farming_01_79",--rotten
	"vegetation_farming_01_79",--dried
	nil,--destroyed
	"vegetation_farming_01_47",--died young
}
farming_vegetableconf.sprite["Wheat"] = {
	"hcFarmingWheat00_0",
	"hcFarmingWheat01_0",
	"hcFarmingWheat02_0",
	"hcFarmingWheat03_0",
	"hcFarmingWheat04_0",
	"hcFarmingWheat05_0",
	"hcFarmingWheat06_0",
	"hcFarmingWheat07_0",--rotten 
	"hcFarmingWheat07_0",--dried
	"hcFarmingWheat07_0",--destroyed
	nil,--died young
}

farming_vegetableconf.sprite["Hemp"] = {
	"hcFarmingHemp00_0",
	"hcFarmingHemp01_0",
	"hcFarmingHemp02_0",
	"hcFarmingHemp03_0",
	"hcFarmingHemp04_0",
	"hcFarmingHemp05_0",
	"hcFarmingHemp06_0",
	"hcFarmingHemp07_0",
	"hcFarmingHemp07_0",
	"hcFarmingHemp07_0",
}
farming_vegetableconf.sprite["Grapes"] = {
	"hcFarmingGrapes00_0",
	"hcFarmingGrapes01_0",
	"hcFarmingGrapes02_0",
	"hcFarmingGrapes03_0",
	"hcFarmingGrapes04_0",
	"hcFarmingGrapes05_0",
	"hcFarmingGrapes06_0",
	"hcFarmingGrapes07_0",--rotten 
	"hcFarmingGrapes07_0",--dried
	"hcFarmingGrapes07_0",--destroyed
	nil,--died young
}
farming_vegetableconf.sprite["Lettuce"] = {
	"hcFarmingLettuce00_0",
	"hcFarmingLettuce01_0",
	"hcFarmingLettuce02_0",
	"hcFarmingLettuce03_0",
	"hcFarmingLettuce04_0",
	"hcFarmingLettuce05_0",
	"hcFarmingLettuce06_0",
	"hcFarmingLettuce07_0",--rotten 
	"hcFarmingLettuce07_0",--dried
	"hcFarmingLettuce07_0",--destroyed
	nil,--died young
}	
farming_vegetableconf.sprite["Peanut"] = {
	"hcFarmingPeanut00_0",
	"hcFarmingPeanut01_0",
	"hcFarmingPeanut02_0",
	"hcFarmingPeanut03_0",
	"hcFarmingPeanut04_0",
	"hcFarmingPeanut05_0",
	"hcFarmingPeanut06_0",
	"hcFarmingPeanut07_0",--rotten 
	"hcFarmingPeanut07_0",--dried
	"hcFarmingPeanut07_0",--destroyed
	nil,--died young
}	
farming_vegetableconf.sprite["Flax"] = {
	"hcFarmingFlax00_0",
	"hcFarmingFlax01_0",
	"hcFarmingFlax02_0",
	"hcFarmingFlax03_0",
	"hcFarmingFlax04_0",
	"hcFarmingFlax05_0",
	"hcFarmingFlax06_0",
	"hcFarmingFlax07_0",--rotten 
	"hcFarmingFlax07_0",--dried
	"hcFarmingFlax07_0",--destroyed
	nil,--died young
}	


farming_vegetableconf.sprite["CoffeeBeans"] = {
	"hcFarmingCoffebean00_0",
	"hcFarmingCoffebean01_0",
	"hcFarmingCoffebean02_0",
	"hcFarmingCoffebean03_0",
	"hcFarmingCoffebean04_0",
	"hcFarmingCoffebean05_0",
	"hcFarmingCoffebean06_0",
	"hcFarmingCoffebean07_0",--rotten 
	"hcFarmingCoffebean07_0",--dried
	"hcFarmingCoffebean07_0",--destroyed
	nil,--died young
}	

farming_vegetableconf.sprite["Sunflower"] = {
	"hcFarmingSunflower00_0",
	"hcFarmingSunflower01_0",
	"hcFarmingSunflower02_0",
	"hcFarmingSunflower03_0",
	"hcFarmingSunflower04_0",
	"hcFarmingSunflower05_0",
	"hcFarmingSunflower06_0",
	"hcFarmingSunflower07_0",--rotten 
	"hcFarmingSunflower07_0",--dried
	"hcFarmingSunflower07_0",--destroyed
	nil,--died young
}	

farming_vegetableconf.sprite["SoyBeans"] = {
	"hcFarmingSoyBeans00_0",
	"hcFarmingSoyBeans01_0",
	"hcFarmingSoyBeans02_0",
	"hcFarmingSoyBeans03_0",
	"hcFarmingSoyBeans04_0",
	"hcFarmingSoyBeans05_0",
	"hcFarmingSoyBeans06_0",
	"hcFarmingSoyBeans07_0",--rotten 
	"hcFarmingSoyBeans07_0",--dried
	"hcFarmingSoyBeans07_0",--destroyed
	nil,--died young
}

farming_vegetableconf.sprite["Mulberries"] = {
	"hcFarmingMulberries00_0",
	"hcFarmingMulberries01_0",
	"hcFarmingMulberries02_0",
	"hcFarmingMulberries03_0",
	"hcFarmingMulberries04_0",
	"hcFarmingMulberries05_0",
	"hcFarmingMulberries06_0",
	"hcFarmingMulberries07_0",--rotten 
	"hcFarmingMulberries07_0",--dried
	"hcFarmingMulberries07_0",--destroyed
	nil,--died young
}


