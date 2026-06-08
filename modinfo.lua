name = "荒野异化"
description = "随机强化生物，重塑生存挑战\nWild Mutation: Randomly strengthen creatures, reshaping survival challenges."
author = "我好慌"
version = "0.1.0"

forumthread = ""
api_version = 10

dst_compatible = true
all_clients_require_mod = true
client_only_mod = false
icon_atlas = "modicon.xml"
icon = "modicon.tex"

configuration_options = {
    {
        name = "NORMAL_MONSTER_POWER",
        label = "普通怪强化倍率",
        hover = "控制非 Boss 生物整体强化强度",
        options = {
            {description = "关闭", data = 0.0},
            {description = "轻度", data = 0.5},
            {description = "标准", data = 1.0},
            {description = "困难", data = 1.5},
            {description = "噩梦", data = 2.0},
        },
        default = 1.0,
    },
    {
        name = "NORMAL_MUTATION_CHANCE",
        label = "普通怪强化概率",
        hover = "普通怪物被随机强化的基础概率",
        options = {
            {description = "0%", data = 0},
            {description = "15%", data = 0.15},
            {description = "30%", data = 0.30},
            {description = "45%", data = 0.45},
            {description = "60%", data = 0.60},
        },
        default = 0.30,
    },
    {
        name = "BOSS_POWER",
        label = "Boss 强化倍率",
        hover = "控制 Boss (epic) 的整体强化强度",
        options = {
            {description = "关闭", data = 0.0},
            {description = "轻度", data = 0.5},
            {description = "标准", data = 1.0},
            {description = "困难", data = 1.5},
            {description = "噩梦", data = 2.0},
            {description = "极限", data = 3.0},
        },
        default = 1.0,
    },
    {
        name = "ELITE_CHANCE",
        label = "精英怪出现概率",
        hover = "普通怪生成时成为精英怪的概率",
        options = {
            {description = "0%", data = 0},
            {description = "2%", data = 0.02},
            {description = "5%", data = 0.05},
            {description = "10%", data = 0.10},
            {description = "20%", data = 0.20},
        },
        default = 0.05,
    },
    {
        name = "ENABLE_CONTROL_EFFECTS",
        label = "控制效果",
        hover = "是否允许攻击附带冰冻、催眠、减速等效果",
        options = {
            {description = "启用", data = true},
            {description = "关闭", data = false},
        },
        default = true,
    },
    {
        name = "ENABLE_SIZE_CHANGE",
        label = "体型变化",
        hover = "是否允许生物随机改变体型大小",
        options = {
            {description = "启用", data = true},
            {description = "关闭", data = false},
        },
        default = true,
    },
    {
        name = "ENABLE_DAMAGE_REDUCTION",
        label = "伤害减免",
        hover = "是否允许生物获得伤害减免/护甲效果",
        options = {
            {description = "启用", data = true},
            {description = "关闭", data = false},
        },
        default = true,
    },
    {
        name = "EARLY_GAME_PROTECTION_DAYS",
        label = "开局保护天数",
        hover = "前若干天降低生物强化强度",
        options = {
            {description = "不保护", data = 0},
            {description = "5天", data = 5},
            {description = "10天", data = 10},
            {description = "20天", data = 20},
            {description = "30天", data = 30},
        },
        default = 10,
    },
    {
        name = "SHOW_AFFIX_NAMES",
        label = "显示词缀名称",
        hover = "是否在生物名称中显示强化词缀",
        options = {
            {description = "显示", data = true},
            {description = "隐藏", data = false},
        },
        default = true,
    },
    {
        name = "ENABLE_DAY_SCALING",
        label = "天数成长曲线",
        hover = "是否根据世界天数逐渐提高生物强化强度",
        options = {
            {description = "启用", data = true},
            {description = "关闭", data = false},
        },
        default = true,
    },
    {
        name = "INSANE_MODE",
        label = "疯狂模式",
        hover = "开启后，生物强化的随机范围将大幅增加，极度危险！",
        options = {
            {description = "开启", data = true},
            {description = "关闭", data = false},
        },
        default = false,
    },
}
