local _G = GLOBAL
local IsServer = _G.TheNet:GetIsServer()

-- 获取配置项
local NORMAL_MONSTER_POWER = GetModConfigData("NORMAL_MONSTER_POWER") or 1.0
local BOSS_POWER = GetModConfigData("BOSS_POWER") or 1.0
local ELITE_CHANCE = GetModConfigData("ELITE_CHANCE") or 0.05
local ENABLE_CONTROL_EFFECTS = GetModConfigData("ENABLE_CONTROL_EFFECTS")
local ENABLE_SIZE_CHANGE = GetModConfigData("ENABLE_SIZE_CHANGE")
local ENABLE_COLOR_CHANGE = GetModConfigData("ENABLE_COLOR_CHANGE")
local ENABLE_DAMAGE_REDUCTION = GetModConfigData("ENABLE_DAMAGE_REDUCTION")
local EARLY_GAME_PROTECTION_DAYS = GetModConfigData("EARLY_GAME_PROTECTION_DAYS") or 10
local SHOW_AFFIX_NAMES = GetModConfigData("SHOW_AFFIX_NAMES")
local ENABLE_DAY_SCALING = GetModConfigData("ENABLE_DAY_SCALING")
local INSANE_MODE = GetModConfigData("INSANE_MODE")
local NORMAL_MUTATION_CHANCE = GetModConfigData("NORMAL_MUTATION_CHANCE") or 0.30

-- ============================================================
-- 五、黑名单、白名单与特殊分类表
-- ============================================================

local BLACKLIST_PREFABS = {
    chester = true,
    hutch = true,
    glommer = true,
    abigail = true,
    shadowminion = true,
    eyeplant = true,
    friendlyfruitfly = true,
    bernie_active = true,
    wobybig = true,
    wobysmall = true,
    ghost = true,
}

local IMMOBILE_MOBS = {
    eyeplant = true,
    antlion = true,
    tentacle = true,
    waterplant = true,
    lureplant = true,
}

local GROUP_MOBS = {
    spider = true,
    spider_warrior = true,
    hound = true,
    firehound = true,
    icehound = true,
    frog = true,
    killerbee = true,
    bat = true,
    monkey = true,
    slurtle = true,
    snurtle = true,
    mosquito = true,
}

local BOSS_MOBS = {
    deerclops = true,
    bearger = true,
    dragonfly = true,
    beequeen = true,
    klaus = true,
    toadstool = true,
    stalker = true,
    alterguardian_phase1 = true,
    alterguardian_phase2 = true,
    alterguardian_phase3 = true,
    spiderqueen = true,
    minotaur = true,
}

local RESOURCE_OR_NEUTRAL_MOBS = {
    beefalo = true,
    pigman = true,
    bunnyman = true,
    rocky = true,
    catcoon = true,
    koalefant_summer = true,
    koalefant_winter = true,
    lightninggoat = true,
}

-- ============================================================
-- 核心逻辑
-- ============================================================

if not IsServer then return end

-- 导入强化逻辑
local mutation_logic = _G.require("wild_mutation_logic")

-- 检查是否为有效强化目标
local function IsValidTarget(inst)
    if not inst or not inst:IsValid() then return false end
    if BLACKLIST_PREFABS[inst.prefab] then return false end
    
    -- 必须有生命和战斗组件
    if not (inst.components.health and inst.components.combat) then return false end
    
    -- 排除玩家
    if inst:HasTag("player") then return false end
    
    -- 排除墙、建筑等
    if inst:HasTag("wall") or inst:HasTag("structure") then return false end
    
    -- 排除已强化的
    if inst._wild_mutation_applied then return false end
    
    return true
end

-- 获取当前天数倍率
local function GetDayScaling()
    if not ENABLE_DAY_SCALING then return 1.0 end
    
    local day = _G.TheWorld.state.cycles + 1
    
    -- 开局保护
    if day <= EARLY_GAME_PROTECTION_DAYS then
        return 0.5
    end
    
    if day <= 30 then
        return 1.0
    elseif day <= 70 then
        return 1.2
    elseif day <= 150 then
        return 1.5
    else
        return 2.0
    end
end

-- 应用强化
local function ApplyMutation(inst)
    if not IsValidTarget(inst) then return end
    
    local is_boss = inst:HasTag("epic") or BOSS_MOBS[inst.prefab]
    local is_group = GROUP_MOBS[inst.prefab]
    local is_neutral = RESOURCE_OR_NEUTRAL_MOBS[inst.prefab]
    
    local base_power = is_boss and BOSS_POWER or NORMAL_MONSTER_POWER
    if base_power <= 0 then return end
    
    -- 只有确定要强化了才设置标记
    inst._wild_mutation_applied = true
    
    local day_mult = GetDayScaling()
    local total_power = base_power * day_mult
    
    -- 群体怪削弱系数
    if is_group then
        total_power = total_power * 0.7
    end
    
    -- 中立怪默认低倍率
    if is_neutral then
        total_power = total_power * 0.8
    end

    -- 传递配置
    local config = {
        is_boss = is_boss,
        power = total_power,
        show_names = SHOW_AFFIX_NAMES,
        enable_size = ENABLE_SIZE_CHANGE and not IMMOBILE_MOBS[inst.prefab],
        enable_color = ENABLE_COLOR_CHANGE,
        enable_reduction = ENABLE_DAMAGE_REDUCTION,
        enable_control = ENABLE_CONTROL_EFFECTS,
        elite_chance = ELITE_CHANCE,
        insane_mode = INSANE_MODE,
        normal_mutation_chance = NORMAL_MUTATION_CHANCE,
    }

    -- 延迟一帧处理，确保属性已加载且由 PrefabPostInit 调用
    inst:DoTaskInTime(0, function()
        if mutation_logic and mutation_logic.ApplyMutationLogic then
            mutation_logic.ApplyMutationLogic(inst, config)
        end
    end)
end

-- 监听实体生成
AddPrefabPostInitAny(function(inst)
    -- 必须在服务器运行且是 MasterSim
    if not IsServer or not _G.TheWorld.ismastersim then return end
    
    -- 延迟一下检查，因为有些组件可能还没加载完
    inst:DoTaskInTime(0, function()
        if IsValidTarget(inst) then
            ApplyMutation(inst)
        end
    end)
end)
