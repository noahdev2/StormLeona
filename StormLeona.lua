--[[
    First Release By Storm Team (Raau,Martin) @ 14.Nov.2020    
]]

if Player.CharName ~= "Leona" then return end

require("common.log")
module("Storm Leona", package.seeall, log.setup)

local clock = os.clock
local insert, sort = table.insert, table.sort
local huge, min, max, abs = math.huge, math.min, math.max, math.abs

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred
local DmgLib, ImmobileLib, Spell = _G.Libs.DamageLib, _G.Libs.ImmobileLib, _G.Libs.Spell

---@type TargetSelector
local TS = _G.Libs.TargetSelector()
local Leona = {}

local spells = {
    Q = Spell.Active({
        Slot = Enums.SpellSlots.Q,
        Range = Player.AttackRange,
        Delay = 0
    }),
    W = Spell.Active({
        Slot = Enums.SpellSlots.W,
        Range = 270,
    }),
    E = Spell.Skillshot({
        Slot = Enums.SpellSlots.E,
        Range = 875,
        Delay = 0.25,
        Radius = 50,
        Speed = 2000,
        Collisions = { Heroes = true },
        Type = "Linear",
        UseHitbox = true
    }),
    R = Spell.Skillshot({
        Slot = Enums.SpellSlots.R,
        Delay = 0.5,
        Range = 1200,
        Radius = 100,
        Type = "Circular"
    }),
}

local function GameIsAvailable()
    return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling)
end


function Leona.IsEnabledAndReady(spell, mode)
    return Menu.Get(mode .. ".Use"..spell) and spells[spell]:IsReady()
end
local lastTick = 0
function Leona.OnTick()    
    if not GameIsAvailable() then return end 

    local gameTime = Game.GetTime()
    if gameTime < (lastTick + 0.25) then return end
    lastTick = gameTime    

    if Leona.Auto() then return end
    if not Orbwalker.CanCast() then return end

    local ModeToExecute = Leona[Orbwalker.GetMode()]
    if ModeToExecute then
        ModeToExecute()
    end
end
function Leona.OnDraw() 
    local playerPos = Player.Position
    local pRange = Orbwalker.GetTrueAutoAttackRange(Player)   
    

    for k, v in pairs(spells) do
        if Menu.Get("Drawing."..k..".Enabled", true) then
            Renderer.DrawCircle3D(playerPos, v.Range, 30, 2, Menu.Get("Drawing."..k..".Color")) 
        end
    end
end

function Leona.GetTargets(range)
    return {TS:GetTarget(range, true)}
end

function Leona.ComboLogic(mode)
    if Leona.IsEnabledAndReady("E", mode) then
        local eChance = Menu.Get(mode .. ".ChanceE")
        for k, eTarget in ipairs(Leona.GetTargets(spells.E.Range)) do
            if spells.E:CastOnHitChance(eTarget, eChance) then
                return
            end
        end
    end
    if Leona.IsEnabledAndReady("Q", mode) then
        for k, qTarget in ipairs(Leona.GetTargets(Player.AttackRange)) do
            if spells.Q:Cast() then
                return
            end
        end
    end    
    if Leona.IsEnabledAndReady("W", mode) then
        for k, wTarget in ipairs(Leona.GetTargets(spells.W.Range)) do
            if spells.W:Cast() then
                return
            end
        end
    end    
    if Leona.IsEnabledAndReady("R", mode) then
        local rChance = Menu.Get(mode .. ".ChanceR")
        for k, rTarget in ipairs(Leona.GetTargets(spells.R.Range)) do
            if spells.R:CastOnHitChance(rTarget, rChance) then
                return
            end
        end
    end
end
function Leona.HarassLogic(mode)
    local PM = Player.Mana / Player.MaxMana * 100
    local SettedMana = Menu.Get("Harass.Mana")
    if SettedMana > PM then 
        return 
        end
        if Leona.IsEnabledAndReady("E", mode) then
            local eChance = Menu.Get(mode .. ".ChanceE")
            for k, eTarget in ipairs(Leona.GetTargets(spells.E.Range)) do
                if spells.E:CastOnHitChance(eTarget, eChance) then
                    return
                end
            end
        end
        if Leona.IsEnabledAndReady("Q", mode) then
            for k, qTarget in ipairs(Leona.GetTargets(Player.AttackRange)) do
                if spells.Q:Cast() then
                    return
                end
            end
        end    
        if Leona.IsEnabledAndReady("W", mode) then
            for k, wTarget in ipairs(Leona.GetTargets(spells.W.Range)) do
                if spells.W:Cast() then
                    return
                end
            end
        end    
end
---@param source AIBaseClient
---@param spell SpellCast
function Leona.OnInterruptibleSpell(source, spell, danger, endT, canMove)
    if not (source.IsEnemy and Menu.Get("Misc.IntE") and spells.E:IsReady() and danger > 2) then return end

    spells.E:CastOnHitChance(source, Enums.HitChance.VeryHigh)
end
function Leona.OnInterruptibleSpell(source, spell, danger, endT, canMove)
    if not (source.IsEnemy and Menu.Get("Misc.IntR") and spells.R:IsReady() and danger > 2) then return end

    spells.R:CastOnHitChance(source, Enums.HitChance.VeryHigh)
end

function Leona.Auto() 
    local ForceR = Menu.Get("Misc.ForceR")
    if ForceR then
        for k, rTarget in ipairs(Leona.GetTargets(spells.R.Range)) do
            if spells.R:CastOnHitChance(rTarget, 0.7) then
                return
            end
        end
    end 
end

function Leona.Combo()  Leona.ComboLogic("Combo")  end
function Leona.Harass() Leona.HarassLogic("Harass") end



function Leona.LoadMenu()

    Menu.RegisterMenu("StormLeona", "Storm Leona", function()
        Menu.ColumnLayout("cols", "cols", 2, true, function()
            Menu.ColoredText("Combo", 0xFFD700FF, true)
            Menu.Checkbox("Combo.UseQ",   "Use [Q]", true) 
            Menu.Checkbox("Combo.UseW",   "Use [W]", true)
            Menu.Checkbox("Combo.UseE",   "Use [E]", true)
            Menu.Slider("Combo.ChanceE", "HitChance [E]", 0.7, 0, 1, 0.05)   
            Menu.Checkbox("Combo.UseR",   "Use [R]", false)  
            Menu.Slider("Combo.ChanceR", "HitChance [R]", 0.7, 0, 1, 0.05)   
            Menu.NextColumn()

            Menu.ColoredText("Harass", 0xFFD700FF, true)
            Menu.Slider("Harass.Mana", "Mana Percent ", 50,0, 100)
            Menu.Checkbox("Harass.UseQ",   "Use [Q]", true)   
            Menu.Checkbox("Harass.UseW",   "Use [W]", false)
            Menu.Checkbox("Harass.UseE",   "Use [E]", true)
            Menu.Slider("Harass.ChanceE", "HitChance [E]", 0.85, 0, 1, 0.05)    
        end)
        Menu.Separator()

        Menu.ColoredText("Misc Options", 0xFFD700FF, true)      
        Menu.Checkbox("Misc.IntE", "Use [E] Interrupt", true)   
        Menu.Checkbox("Misc.IntR", "Use [R] Interrupt", false)       
        Menu.Keybind("Misc.ForceR", "Force [R] Key", string.byte('T'))
        Menu.Separator()

        Menu.ColoredText("Draw Options", 0xFFD700FF, true)
        Menu.Checkbox("Drawing.E.Enabled",   "Draw [E] Range")
        Menu.ColorPicker("Drawing.E.Color", "Draw [E] Color", 0x118AB2FF)     
        Menu.Checkbox("Drawing.R.Enabled",   "Draw [R] Range")
        Menu.ColorPicker("Drawing.R.Color", "Draw [R] Color", 0x118AB2FF)     
    end)     
end

function OnLoad()
    Leona.LoadMenu()
    for eventName, eventId in pairs(Enums.Events) do
        if Leona[eventName] then
            EventManager.RegisterCallback(eventId, Leona[eventName])
        end
    end    
    return true
end
