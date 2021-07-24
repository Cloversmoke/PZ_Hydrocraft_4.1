HCUziSilencer = {}
HCShotgunSilencer = {}

if(ItemValueTable == nil) then ItemValueTable = {}; end
ItemValueTable["Hydrocraft.HCUziSilencer"] = 6.00;
ItemValueTable["Hydrocraft.HCShotgunSilencer"] = 6.00;

-- HC silencer handling
local HCSilencersOnEquipPrimary = function(player, item)

    if item == nil then return end
    if not item.getCanon then return end
    if item:getCanon() == nil then return end
 
    if (item:getCanon():getType() == "HCUziSilencer") or (item:getCanon():getType() == "HCShotgunSilencer") then
    
    --print ("**Silencer detected**")
    local scriptItem = item:getScriptItem()
    local soundVolume = scriptItem:getSoundVolume()
    local soundRadius = scriptItem:getSoundRadius()
    local swingSound = scriptItem:getSwingSound()
    
    soundVolume = soundVolume * (0.10)
    soundRadius = soundRadius * (0.10)
    swingSound = 'HCsilentPistolShot'

    if item:getCanon():getType() == "HCUziSilencer" then 
        swingSound = 'HCsilentPistolShot'
    end
    if item:getCanon():getType() == "HCShotgunSilencer" then 
        swingSound = 'HCshotgunSilenced'
    end
    
    item:setSoundVolume(soundVolume)
    item:setSoundRadius(soundRadius)
    item:setSwingSound(swingSound)
    end

end

Events.OnEquipPrimary.Add(HCSilencersOnEquipPrimary)
Events.OnGameStart.Add(function()
	local player = getPlayer()
	HCSilencersOnEquipPrimary(player, player:getPrimaryHandItem())
end)

