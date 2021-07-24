Hydrocraft = {}


HcMenu = HcMenu or {}; 
HcMenu._index = HcMenu


Hydrocraft.doBuildMenus = function(_player, _context, _worldObjects)

	local player = _player;
	local context = _context;
	local worldobjects = _worldObjects;
	local HcMenuOption = context:addOption("Advanced Building", worldobjects);
	local HcSubMenu = ISContextMenu:getNew(context);
	context:addSubMenu(HcMenuOption, HcSubMenu);

Hydrocraft.BuildOptionGlassRoof(player, HcSubMenu)
Hydrocraft.BuildOptionSteelStairs (player, HcSubMenu)
Hydrocraft.BuildOptionGlassWall (player, HcSubMenu)
Hydrocraft.BuildOptionWallBrick (player, HcSubMenu)
Hydrocraft.BuildOptionWallBrickWin (player, HcSubMenu)
Hydrocraft.BuildOptionIBCTower (player, HcSubMenu)
end


Hydrocraft.BuildOptionSteelStairs  = function(player, HcSubMenu)
local option
local tooltip
sprite = {}
sprite.upToLeft01 = "fixtures_stairs_01_3"
sprite.upToLeft02 = "fixtures_stairs_01_4"
sprite.upToLeft03 = "fixtures_stairs_01_5"
sprite.upToRight01 = "fixtures_stairs_01_11"
sprite.upToRight02 = "fixtures_stairs_01_12"
sprite.upToRight03 = "fixtures_stairs_01_13"
sprite.pillar = "fixtures_stairs_01_14"
sprite.pillarNorth = "fixtures_stairs_01_14"
	
option = HcSubMenu:addOption("Build Steel Stairs", nil, function() Hydrocraft.onBuildMetalStairs(sprite,player) end);
tooltip = Hydrocraft.toolTipcheck(option)
tooltip:setName("Build Steel Stairs")
tooltip.description = "<RGB:1,1,1>Welding Mask <LINE>Blow Torch <LINE>Steelpole: 2 <LINE> Steelrod:6 <LINE> Steelsheet: 5"
tooltip:setTexture(sprite.upToLeft01)
end


Hydrocraft.BuildOptionGlassRoof  = function(player, HcSubMenu)
local option
local tooltip
option = HcSubMenu:addOption("Glass roof", nil, function() Hydrocraft.onBuildGlassRoof(player) end);
tooltip = Hydrocraft.toolTipcheck(option)
tooltip:setName("Glass roof")
tooltip.description = "<RGB:1,1,1>Welding Mask <LINE>Blow Torch <LINE> Steel Rod: 2 <LINE> Glass Pane: 1"
tooltip:setTexture("roofs_02_55")
end

Hydrocraft.BuildOptionGlassWall  = function(player, HcSubMenu)
local option
local tooltip
option = HcSubMenu:addOption("Glass Wall", nil, function() Hydrocraft.onBuildGlassWall(player) end);
tooltip = Hydrocraft.toolTipcheck(option)
tooltip:setName("Glass roof")
tooltip.description = "<RGB:1,1,1>Welding Mask <LINE>Blow Torch <LINE> Steel Rod: 3 <LINE> Large Glass Pane: 1"
tooltip:setTexture("walls_commercial_01_97")
end

Hydrocraft.BuildOptionWallBrick  = function(player, HcSubMenu)
local option
local tooltip
option = HcSubMenu:addOption("Brick wall", nil, function() Hydrocraft.onBuildWallBrick(player) end);
tooltip = Hydrocraft.toolTipcheck(option)
tooltip:setName("Brick wall")
tooltip.description = "<RGB:1,1,1>Mason Trowel<LINE> Mortar: 1 <LINE>Red Bricks:22  <LINE>Grey Bricks:18 <LINE>Stones: 20"
tooltip:setTexture("walls_exterior_house_02_65")
end


Hydrocraft.BuildOptionWallBrickWin  = function(player, HcSubMenu)
local option
local tooltip
option = HcSubMenu:addOption("Brick wall with window", nil, function() Hydrocraft.onBuildWallBrickWin(player) end);
tooltip = Hydrocraft.toolTipcheck(option)
tooltip:setName("Brick wall with window")
tooltip.description = "<RGB:1,1,1>Mason Trowel<LINE> Mortar: 1 <LINE>Red Bricks:18  <LINE>Grey Bricks:15 <LINE>Stones: 20"
tooltip:setTexture("walls_exterior_house_02_73")
end


Hydrocraft.BuildOptionIBCTower  = function(player, HcSubMenu)
local option
local tooltip
option = HcSubMenu:addOption("IBC Tower", nil, function() Hydrocraft.onBuildIBCTower(player) end);
tooltip = Hydrocraft.toolTipcheck(option)
tooltip:setName("Huge IBC Tower")
tooltip.description = "<RGB:1,1,1>IBCtower"
tooltip:setTexture("carpentry_02_52")
end


-- *********************** BuildingFunctions ********************

Hydrocraft.onBuildIBCTower = function(player)
-- create a new barrel to drag a ghost render of the barrel under the mouse

local barrel = RainCollectorBarrel:new(player, "carpentry_02_52", 2000);
--local barrel = RainCollectorBarrel:new(player, "hcBuildingIBCTower_01_0", 2000);
	-- we now set his the mod data the needed material
	-- by doing this, all will be automatically consummed, drop on the ground if destoryed etc.
	-- barrel.modData["need:Base.Nails"] = "1";
	barrel.modData["need:Hydrocraft.HCIBCtower"] = "1";
	-- barrel.modData["xp:Woodwork"] = 4;
    -- and now allow the item to be dragged by mouse
	barrel.player = player
	getCell():setDrag(barrel, player);
end


Hydrocraft.onBuildWallBrickWin = function(player)
local wall = ISWoodenWall:new("walls_exterior_house_02_72","walls_exterior_house_02_73", nil);
wall.player = player
wall.name = "Brick Wall with Window"
wall.canBarricade = true
wall.hoppable = true

wall.modData["need:Hydrocraft.HCGreybrick"] = "15";
wall.modData["need:Hydrocraft.HCRedbrick"] = "18";
wall.modData["need:Base.Stone"] = "20";
wall.modData["need:Hydrocraft.HCMortar"] = "1";


wall.firstItem = "Hydrocraft.HCMasontrowel";
wall.health = 700;
getCell():setDrag(wall, player);
end




Hydrocraft.onBuildWallBrick = function(player)
local wall = ISWoodenWall:new("walls_exterior_house_02_64","walls_exterior_house_02_65", nil);
wall.player = player
wall.name = "Brick Wall"
wall.canBarricade = false
wall.hoppable = false

wall.modData["need:Hydrocraft.HCGreybrick"] = "18";
wall.modData["need:Hydrocraft.HCRedbrick"] = "22";
wall.modData["need:Base.Stone"] = "20";
wall.modData["need:Hydrocraft.HCMortar"] = "1";

wall.firstItem = "Hydrocraft.HCMasontrowel";
wall.health = 700;
getCell():setDrag(wall, player);
end


Hydrocraft.onBuildMetalStairs = function(sprite,player)

local stairs = ISWoodenStairs:new(sprite.upToLeft01, sprite.upToLeft02, sprite.upToLeft03, sprite.upToRight01, sprite.upToRight02, sprite.upToRight03, sprite.pillar, sprite.pillarNorth)
stairs.isThumpable = false
stairs.player = player
stairs.name = "Steel Stairs"
stairs.modData["need:Hydrocraft.HCSteelpole"] = "2"
stairs.modData["need:Hydrocraft.HCSteelrod"] = "6"
stairs.modData["need:Hydrocraft.HCSteelsheet"] = "5"

stairs.firstItem = "BlowTorch";
stairs.secondItem = "WeldingMask";
stairs.craftingBank = "BlowTorch";
stairs.modData["use:Base.BlowTorch"] = torchUse;
stairs.modData["xp:MetalWelding"] = 20;
stairs.noNeedHammer = true;
stairs.health = 120;
getCell():setDrag(stairs, player)
end


Hydrocraft.onBuildGlassRoof = function(player)
local floor = ISWoodenFloor:new("roofs_02_55","roofs_02_55");
floor.player = player
floor.name = "Glass roof"

floor.modData["need:Hydrocraft.HCSteelrod"] = "2"
floor.modData["need:Hydrocraft.HCGlasspane"] = "1"

floor.firstItem = "BlowTorch";
floor.secondItem = "WeldingMask";
floor.craftingBank = "BlowTorch";
floor.modData["use:Base.BlowTorch"] = torchUse;
floor.modData["xp:MetalWelding"] = 10;
floor.noNeedHammer = true;
floor.health = 10;
getCell():setDrag(floor, player);
end


Hydrocraft.onBuildGlassWall = function(player)
local wall = ISWoodenWall:new("walls_commercial_01_96","walls_commercial_01_97", nil);
wall.player = player
wall.name = "Glass Wall"
wall.canBarricade = false
wall.hoppable = false

wall.modData["need:Hydrocraft.HCSteelrod"] = "3"
wall.modData["need:Hydrocraft.HCGlasspanelarge"] = "1"

wall.firstItem = "BlowTorch";
wall.secondItem = "WeldingMask";
wall.craftingBank = "BlowTorch";
wall.modData["use:Base.BlowTorch"] = torchUse;
wall.modData["xp:MetalWelding"] = 10;
wall.noNeedHammer = true;
wall.health = 10;
getCell():setDrag(wall, player);
end




Hydrocraft.toolTipcheck = function(option)

	local _tooltip = ISToolTip:new()
	_tooltip:initialise()
	_tooltip:setVisible(false)
	option.toolTip = _tooltip

	return _tooltip
end




local function func_Init()
	Events.OnFillWorldObjectContextMenu.Add(Hydrocraft.doBuildMenus)
end

Events.OnGameStart.Add(func_Init)




