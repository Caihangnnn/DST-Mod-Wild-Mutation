local _G = rawget(_G, "GLOBAL") or _G

local function Clamp(x, min, max)
    return math.max(min, math.min(max, x))
end

local AFFIXES = {
    colossal = {
        name = "巨躯",
        cost = 2,
        color = {1.2, 1, 0.8, 1},
        apply = function(inst, is_boss, power)
            return {
                hp_mult = is_boss and (1.5 + power * 0.5) or (1.3 + power * 0.2),
                size_mult = is_boss and (1.15 + power * 0.1) or (1.1 + power * 0.05),
                speed_mult = 0.85,
                dmg_mult = 1.1,
            }
        end
    },
    agile = {
        name = "灵巧",
        cost = 2,
        color = {0.8, 1.2, 1, 1},
        apply = function(inst, is_boss, power)
            return {
                hp_mult = 0.9,
                size_mult = 0.9,
                speed_mult = is_boss and (1.1 + power * 0.1) or (1.2 + power * 0.1),
                dmg_mult = 1.0,
            }
        end
    },
    armored = {
        name = "坚甲",
        cost = 3,
        color = {0.8, 0.8, 0.9, 1},
        apply = function(inst, is_boss, power)
            return {
                hp_mult = 1.2,
                reduction = is_boss and (0.3 + power * 0.1) or (0.15 + power * 0.05),
                speed_mult = 0.9,
                dmg_mult = 1.0,
            }
        end
    },
    frenzied = {
        name = "狂暴",
        cost = 2,
        color = {1.5, 0.5, 0.5, 1},
        apply = function(inst, is_boss, power)
            return {
                hp_mult = 1.1,
                dmg_mult = is_boss and (1.5 + power * 0.5) or (1.3 + power * 0.2),
                speed_mult = 1.05,
            }
        end
    },
    frostbound = {
        name = "寒霜",
        cost = 3,
        color = {0.5, 0.8, 1.5, 1},
        apply = function(inst, is_boss, power)
            inst._wm_freeze = {
                chance = is_boss and 0.3 or 0.15,
                amount = is_boss and 0.5 or 0.2,
                cooldown = is_boss and 4 or 6,
            }
            return {
                hp_mult = 1.1,
                dmg_mult = 0.9,
            }
        end
    },
    nightmare = {
        name = "梦魇",
        cost = 3,
        color = {0.8, 0.2, 1.2, 1},
        apply = function(inst, is_boss, power)
            inst._wm_nightmare = {
                sanity = is_boss and 20 or 10,
                sleep_chance = is_boss and 0.15 or 0.05,
                cooldown = is_boss and 8 or 12,
            }
            return {
                hp_mult = 1.1,
                dmg_mult = 0.9,
            }
        end
    },
    venomous = {
        name = "剧毒",
        cost = 2,
        color = {0.2, 1.2, 0.2, 1},
        apply = function(inst, is_boss, power)
            inst._wm_poison = {
                dmg = is_boss and 5 or 2,
                duration = is_boss and 10 or 5,
            }
            return {
                hp_mult = 1.0,
                dmg_mult = 1.1,
            }
        end
    },
    regenerating = {
        name = "再生",
        cost = 3,
        color = {1, 1.2, 1, 1},
        apply = function(inst, is_boss, power)
            local regen_pct = is_boss and 0.01 or 0.02
            if inst.components.health then
                inst:DoPeriodicTask(5, function()
                    if not inst.components.health:IsDead() then
                        inst.components.health:DoDelta(inst.components.health.maxhealth * regen_pct, true, "wild_mutation_regen")
                    end
                end)
            end
            return {
                hp_mult = 1.1,
            }
        end
    },
    vampiric = {
        name = "吸血",
        cost = 2,
        color = {1.2, 0.5, 0.8, 1},
        apply = function(inst, is_boss, power)
            inst._wm_vampiric = {
                ratio = is_boss and 0.1 or 0.2,
            }
            return {
                hp_mult = 1.0,
                dmg_mult = 1.1,
            }
        end
    },
}

local function ApplyMutationLogic(inst, config)
    local is_boss = config.is_boss
    local base_power = config.power
    local show_names = config.show_names
    local enable_size = config.enable_size
    local enable_color = config.enable_color ~= false
    local enable_reduction = config.enable_reduction
    local enable_control = config.enable_control
    local elite_chance = config.elite_chance
    local insane_mode = config.insane_mode
    local normal_mutation_chance = config.normal_mutation_chance or 0.3

    -- 强化概率判定 (普通怪)
    if not is_boss then
        local rand = _G.math.random()
        local actual_normal_chance = insane_mode and 0.8 or normal_mutation_chance
        if rand > actual_normal_chance then return end 
    end

    -- 确定预算和词缀数量上限
    local budget = is_boss and 10 or 3
    local max_affixes = is_boss and 3 or 1
    
    if insane_mode then
        budget = is_boss and 25 or 10
        max_affixes = is_boss and 5 or 3
    end

    local is_elite = false
    local actual_elite_chance = insane_mode and (elite_chance * 3) or elite_chance
    if not is_boss and _G.math.random() < actual_elite_chance then
        is_elite = true
        budget = insane_mode and 20 or 7
        max_affixes = insane_mode and 5 or 3
    end

    local applied_affixes = {}
    local total_hp_mult = 1.0
    local total_dmg_mult = 1.0
    local total_speed_mult = 1.0
    local total_size_mult = 1.0
    local total_reduction = 0

    -- 随机选择词缀
    local affix_keys = {}
    for k, v in pairs(AFFIXES) do
        table.insert(affix_keys, k)
    end

    for i = #affix_keys, 2, -1 do
        local j = _G.math.random(i)
        affix_keys[i], affix_keys[j] = affix_keys[j], affix_keys[i]
    end

    for _, key in ipairs(affix_keys) do
        if #applied_affixes >= max_affixes then break end
        
        local affix = AFFIXES[key]
        if budget >= affix.cost then
            local can_apply = true
            if (key == "frostbound" or key == "nightmare") and not enable_control then
                can_apply = false
            end
            
            if can_apply then
                budget = budget - affix.cost
                table.insert(applied_affixes, affix)
                
                local res = affix.apply(inst, is_boss, base_power)
                if res.hp_mult then total_hp_mult = total_hp_mult * res.hp_mult end
                if res.dmg_mult then total_dmg_mult = total_dmg_mult * res.dmg_mult end
                if res.speed_mult then total_speed_mult = total_speed_mult * res.speed_mult end
                if res.size_mult and enable_size then total_size_mult = total_size_mult * res.size_mult end
                if res.reduction and enable_reduction then total_reduction = total_reduction + res.reduction end
            end
        end
    end

    -- 如果没有词缀且不是 Boss，就不强化了
    if #applied_affixes == 0 and not is_boss then 
        inst._wild_mutation_applied = nil -- 重置标记
        return 
    end

    -- 精英怪基础数值
    if is_elite then
        local hp_boost = insane_mode and 2.5 or 1.5
        local dmg_boost = insane_mode and 1.5 or 1.2
        total_hp_mult = total_hp_mult * hp_boost
        total_dmg_mult = total_dmg_mult * dmg_boost
    end

    -- 疯狂模式下的额外数值膨胀
    if insane_mode then
        total_hp_mult = total_hp_mult * 1.5
        total_dmg_mult = total_dmg_mult * 1.3
    end

    -- 数值限制 (Clamp)
    if is_boss then
        total_hp_mult = math.min(total_hp_mult, insane_mode and 8.0 or 3.5)
        total_dmg_mult = math.min(total_dmg_mult, insane_mode and 5.0 or 2.5)
        total_speed_mult = math.min(total_speed_mult, insane_mode and 1.5 or 1.25)
        total_size_mult = math.min(total_size_mult, insane_mode and 1.8 or 1.4)
        total_reduction = math.min(total_reduction, insane_mode and 0.75 or 0.6)
    else
        total_hp_mult = math.min(total_hp_mult, insane_mode and 4.0 or 2.0)
        total_dmg_mult = math.min(total_dmg_mult, insane_mode and 3.0 or 1.8)
        total_speed_mult = math.min(total_speed_mult, insane_mode and 1.5 or 1.35)
        total_size_mult = math.min(total_size_mult, insane_mode and 1.4 or 1.25)
        total_reduction = math.min(total_reduction, insane_mode and 0.5 or 0.3)
    end

    -- 应用属性 (存档保护)
    if inst.components.health then
        local health = inst.components.health
        local old_percent = health:GetPercent()
        
        -- 保存原始生命值
        inst._wm_original_maxhealth = inst._wm_original_maxhealth or health.maxhealth
        health:SetMaxHealth(inst._wm_original_maxhealth * total_hp_mult)
        
        -- 血量同步
        if old_percent >= 0.99 then
            health:SetPercent(1)
        else
            health:SetPercent(old_percent)
        end
        
        -- 免伤实现
        if total_reduction > 0 and health.externalabsorbmodifiers then
            health.externalabsorbmodifiers:SetModifier(inst, total_reduction, "wild_mutation")
        end
    end

    if inst.components.combat then
        local combat = inst.components.combat
        -- 保存原始伤害
        inst._wm_original_damage = inst._wm_original_damage or combat.defaultdamage or 0
        combat:SetDefaultDamage(inst._wm_original_damage * total_dmg_mult)
        
        local old_onhitother = combat.onhitotherfn
        combat.onhitotherfn = function(inst, target, damage, ...)
            if target and target.components.health and not target.components.health:IsDead() then
                -- 只有对玩家生效或通过配置控制 (默认对玩家生效，增加挑战)
                local is_player = target:HasTag("player")
                local now = _G.GetTime()

                -- 寒霜 (带冷却)
                if inst._wm_freeze and is_player then
                    if inst._wm_next_freeze_time == nil or now >= inst._wm_next_freeze_time then
                        if _G.math.random() < inst._wm_freeze.chance then
                            if target.components.freezable then
                                target.components.freezable:AddColdness(inst._wm_freeze.amount)
                                if target.components.freezable.SpawnShatterFX then
                                    target.components.freezable:SpawnShatterFX()
                                end
                            end
                            inst._wm_next_freeze_time = now + inst._wm_freeze.cooldown
                        end
                    end
                end

                -- 梦魇 (带冷却)
                if inst._wm_nightmare and is_player then
                    if inst._wm_next_sleep_time == nil or now >= inst._wm_next_sleep_time then
                        if target.components.sanity then
                            target.components.sanity:DoDelta(-inst._wm_nightmare.sanity)
                        end
                        if _G.math.random() < inst._wm_nightmare.sleep_chance then
                            if target.components.sleeper then
                                target.components.sleeper:GoToSleep(2)
                            end
                            inst._wm_next_sleep_time = now + inst._wm_nightmare.cooldown
                        end
                    end
                end

                -- 剧毒 (Token 修复)
                if inst._wm_poison and is_player then
                    local poison = inst._wm_poison
                    local token = {}
                    target._wm_poison_token = token
                    
                    if target._wm_poison_task then target._wm_poison_task:Cancel() end
                    target._wm_poison_task = target:DoPeriodicTask(1, function()
                        if target.components.health and not target.components.health:IsDead() then
                            target.components.health:DoDelta(-poison.dmg, nil, inst.prefab)
                        end
                    end)
                    
                    target:DoTaskInTime(poison.duration, function()
                        if target._wm_poison_token == token then
                            if target._wm_poison_task then 
                                target._wm_poison_task:Cancel() 
                                target._wm_poison_task = nil 
                            end
                            target._wm_poison_token = nil
                        end
                    end)
                end

                -- 吸血
                if inst._wm_vampiric and damage then
                    inst.components.health:DoDelta(damage * inst._wm_vampiric.ratio, true, "wild_mutation_vampire")
                end
            end
            if old_onhitother then return old_onhitother(inst, target, damage, ...) end
        end
    end

    if inst.components.locomotor then
        local loco = inst.components.locomotor
        -- 保存原始速度
        inst._wm_original_walkspeed = inst._wm_original_walkspeed or loco.walkspeed
        inst._wm_original_runspeed = inst._wm_original_runspeed or loco.runspeed
        loco.walkspeed = inst._wm_original_walkspeed * total_speed_mult
        loco.runspeed = inst._wm_original_runspeed * total_speed_mult
    end

    if total_size_mult ~= 1.0 then
        local s = total_size_mult
        inst.Transform:SetScale(s, s, s)
    end

    -- 视觉效果
    if enable_color and inst.AnimState and #applied_affixes > 0 then
        local r, g, b, a = 1, 1, 1, 1
        for _, affix in ipairs(applied_affixes) do
            r = r * affix.color[1]
            g = g * affix.color[2]
            b = b * affix.color[3]
            a = a * affix.color[4]
        end
        -- 颜色 Clamp
        r = Clamp(r, 0.3, 1.5)
        g = Clamp(g, 0.3, 1.5)
        b = Clamp(b, 0.3, 1.5)
        inst.AnimState:SetMultColour(r, g, b, a)
    end

    -- 名称显示 (防止叠加)
    if show_names and #applied_affixes > 0 then
        local name_parts = {}
        if is_elite then table.insert(name_parts, "精英") end
        for _, affix in ipairs(applied_affixes) do
            table.insert(name_parts, affix.name)
        end
        
        local prefix = table.concat(name_parts, "·")
        if prefix ~= "" then prefix = prefix .. "·" end
        
        -- 保存原始名字
        inst._wm_original_name = inst._wm_original_name or inst.name or inst.prefab
        inst.name = prefix .. inst._wm_original_name
        
        if inst.components.inspectable then
            local old_desc = inst.components.inspectable.getspecialdescription
            inst.components.inspectable.getspecialdescription = function(inst, viewer)
                local desc = string.format("这是一只被异化的%s，拥有词缀：%s", inst._wm_original_name, prefix)
                if old_desc then
                    return desc .. "\n" .. old_desc(inst, viewer)
                end
                return desc
            end
        end
    end
end

return {
    ApplyMutationLogic = ApplyMutationLogic
}
