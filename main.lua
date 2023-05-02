-- If someone reads this messy code please have mercy on me
-- Also if someone needs help with modding I recommend this website https://moddingofisaac.com/docs/rep/index.html
-- I will never ever again write shader code. It was painfull
-- Have fun on your own modding journey 
local mod = RegisterMod("Flashbang Skill Issue", 1)
mod.SFX = SFXManager()
mod.BANG_SOUND = Isaac.GetSoundIdByName("FLASH_BANG")
mod.wait = false
mod.switch = false
mod.is_flashed = false
mod.initialized = false
mod.current_frame = 0
mod.target_frame = 0
mod.time = 0

-- Copied from Hit tracker mod
-- Identificaiton of special damage types, referenced from Rep+ code
local function isSelfDamage(damageFlags, data)
	local selfDamageFlags = {
		['IVBag'] = DamageFlag.DAMAGE_RED_HEARTS | DamageFlag.DAMAGE_INVINCIBLE | DamageFlag.DAMAGE_IV_BAG,
		['Confessional'] = DamageFlag.DAMAGE_RED_HEARTS,
		['DemonBeggar'] = DamageFlag.DAMAGE_RED_HEARTS,
		['BloodDonationMachine'] = DamageFlag.DAMAGE_RED_HEARTS,
		['HellGame'] = DamageFlag.DAMAGE_RED_HEARTS,
		['CurseRoom'] = DamageFlag.DAMAGE_NO_PENALTIES | DamageFlag.DAMAGE_CURSED_DOOR,
		['MausoleumDoor'] = DamageFlag.DAMAGE_SPIKES | DamageFlag.DAMAGE_NO_PENALTIES | DamageFlag.DAMAGE_INVINCIBLE | DamageFlag.DAMAGE_NO_MODIFIERS,
		['SacrificeRoom'] = DamageFlag.DAMAGE_SPIKES | DamageFlag.DAMAGE_NO_PENALTIES,
        ['SpikedChest'] = DamageFlag.DAMAGE_CHEST | DamageFlag.DAMAGE_NO_PENALTIES,
        ['BadTrip'] = DamageFlag.DAMAGE_NOKILL | DamageFlag.DAMAGE_INVINCIBLE | DamageFlag.DAMAGE_NO_PENALTIES
	}
	for source, flags in pairs(selfDamageFlags) do
		if damageFlags & flags == flags then
			return true
		end
	end
	return false
end

-- If player gets hit start the whole process
function mod:onSkillIssue(Entity, dAmount, dFlags, dSource, dCountdown)
	local Source = dSource.Entity
	local Player = Entity:ToPlayer()
    if Player then
        if dFlags & DamageFlag.DAMAGE_FAKE ~= DamageFlag.DAMAGE_FAKE and not isSelfDamage(dFlags) then
			mod.SFX:Play(mod.BANG_SOUND, 100)
			mod.wait = true
        end
    end
end

-- Use the shader when player gets hit
function mod:GetShaderParams(shaderName)
	if shaderName == "Bang" and mod.is_flashed then
        local playerPos = Isaac.GetPlayer(0).Position
        local params = {Time = mod.time}
        return params;
    end
end

-- Basically a fix for some issues with screen being white instantly after loading into the game
function mod:PostPlayerInit()
	mod.wait = false
	mod.switch = false
	mod.is_flashed = true
	mod.current_frame = 0
	mod.target_frame = 0
	mod.time = 1
end

-- Basically a wait function and timer for the flashbang
function mod:PostRender()
	if mod.wait then
		if not mod.switch then
			mod.current_frame = Game():GetFrameCount()
			mod.target_frame = mod.current_frame + 30
			mod.switch = true
		end
		if mod.current_frame ~= mod.target_frame then
			mod.current_frame = Game():GetFrameCount()
		else
			mod.wait = false
			mod.switch = false
			mod.is_flashed = true
			mod.time = 100
		end
	end
	if mod.is_flashed and mod.time > -1 then
		mod.time = mod.time - 1
	end
	if mod.is_flashed and mod.time < 0 then
		mod.is_flashed = false
		mod.time = 0
	end
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.PostPlayerInit)
mod:AddCallback(ModCallbacks.MC_GET_SHADER_PARAMS, mod.GetShaderParams)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.PostRender)
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.onSkillIssue)