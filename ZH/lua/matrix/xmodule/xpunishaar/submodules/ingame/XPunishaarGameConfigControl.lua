--- GameControl 关卡级配置登记：Effect/EffectGroup/Trigger 三 Client 表单点登记。
--- Control/ fightControl 不再重复登记这三表，经 GameControl 借用（修正 #60：根治重复登记）。
--- 另提供 Card/CardLevel 委派访问器（借根 Control），供 STEProjection 以 GameControl 为配置门面一站式读取。
---@type XPunishaarGameControl
local XPunishaarGameControl = XClassPartial("XPunishaarGameControl")

local XPunishaarCardBgSettingsReader = require("XModule/XPunishaar/SubModules/InGame/XPunishaarCardBgSettingsReader")

local TableKey = {
    -- Share 表：Fight/Enemy/EnemySkill（关卡内路由/战斗）+ Shop/CardSale（关卡内商店）
    PunishaarFight      = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    PunishaarEnemy      = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    PunishaarEnemySkill = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    PunishaarShop       = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    PunishaarCardSale   = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    -- Client 表：Effect/EffectGroup/Trigger（STE 引擎 + 局外投影共用）
    PunishaarEffect      = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    PunishaarEffectGroup = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    PunishaarTrigger     = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    -- Client 表：卡牌显示底图/前遮/遮罩/描边/球值标签（卡牌视觉框配置，Id=10000+100*Color+Level 复合键，#64）
    PunishaarCardBgSettings = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    -- 事件三表（#62 剧情事件面板 v2）：仅关卡内 Event 节点流转读取，与 Fight/Enemy/Shop 同关卡级生命周期
    PunishaarEventGroup   = { DirPath = XConfigUtil.DirectoryType.Share,  ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    PunishaarEventContent = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    PunishaarEventReward  = { DirPath = XConfigUtil.DirectoryType.Share,  ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    -- Client 表：HUD 引导提示（HudIcon/HudDesc/GroupId/Condition[]，#86；关卡级生命周期——随 GameControl 创建/释放，condition 调度 TODO）
    PunishaarHud          = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
}

function XPunishaarGameControl:InitConfig()
    self:InitConfigByTabKey("Punishaar", TableKey)
end

---@return XTablePunishaarFight
function XPunishaarGameControl:GetTablePunishaarFight(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarFight, id, notips)
end

---@return XTablePunishaarEnemy
function XPunishaarGameControl:GetTablePunishaarEnemy(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarEnemy, id, notips)
end

---@return XTablePunishaarEnemySkill
function XPunishaarGameControl:GetTablePunishaarEnemySkill(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarEnemySkill, id, notips)
end

---@return XTablePunishaarShop
function XPunishaarGameControl:GetTablePunishaarShop(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarShop, id, notips)
end

---@return XTablePunishaarCardSale
function XPunishaarGameControl:GetTablePunishaarCardSale(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarCardSale, id, notips)
end

---@return XTablePunishaarEffect
function XPunishaarGameControl:GetTablePunishaarEffect(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarEffect, id, notips)
end

--- 卡牌显示底图/前遮/遮罩/描边/球值标签配置（Client 表，Id=10000+100*Color+Level 复合键）。#64
---@return XTablePunishaarCardBgSettings
function XPunishaarGameControl:GetTablePunishaarCardBgSettings(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarCardBgSettings, id, notips)
end

--- 主卡详情头像背景图（#65 Reader 接入）：转发 Reader.GetMainDetailHeadBg，按 level+Type 取 Role/PartnerMainDetailHeadBg。
---@param cardType number CardType
---@param level number 卡牌等级（≥1）
---@return string|nil 背景图路径（nil=配置缺）
function XPunishaarGameControl:GetMainDetailHeadBg(cardType, level)
    return XPunishaarCardBgSettingsReader.GetMainDetailHeadBg(self, cardType, level)
end

---@return XTablePunishaarEffectGroup
function XPunishaarGameControl:GetTablePunishaarEffectGroup(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarEffectGroup, id, notips)
end

---@return XTablePunishaarTrigger
function XPunishaarGameControl:GetTablePunishaarTrigger(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarTrigger, id, notips)
end

--- Card/CardLevel 表在根 Control（ConfigControl）；GameControl 作投影门面经 GetControl() 委派借用。
---@return XTablePunishaarCard
function XPunishaarGameControl:GetTablePunishaarCard(id, notips)
    return self:GetControl():GetTablePunishaarCard(id, notips)
end

---@return XTablePunishaarCardLevel
function XPunishaarGameControl:GetTablePunishaarCardLevel(id, notips)
    return self:GetControl():GetTablePunishaarCardLevel(id, notips)
end

--- 【#62】事件三表（关卡级，仅 Event 节点流转读取）：EventGroup 抽样池(Share)/EventContent 内容本体(Client)/EventReward 奖励(Share)。
--- 服务端按 StageContent.EventGroupId 池抽候选 → 下发 RandomEventIds=EventGroup.Id；EventGroup.EventId→Content.Id（客户端链式）；EventGroup.EventRewardId→EventReward.Id。

---@return XTablePunishaarEventGroup
function XPunishaarGameControl:GetTablePunishaarEventGroup(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarEventGroup, id, notips)
end

---@return XTablePunishaarEventContent
function XPunishaarGameControl:GetTablePunishaarEventContent(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarEventContent, id, notips)
end

---@return XTablePunishaarEventReward
function XPunishaarGameControl:GetTablePunishaarEventReward(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarEventReward, id, notips)
end

--- HUD 引导提示配置（Client 表 Id/HudIcon/HudDesc/GroupId/Condition[]，#86；关卡级生命周期，随 GameControl）。
--- condition 选哪条 HUD 的调度（Evaluate/CheckHudCondition 调用/组内加权选一）TODO，待 Q1/Q2 确认后接入。
---@return XTablePunishaarHud
function XPunishaarGameControl:GetTablePunishaarHud(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarHud, id, notips)
end

--- 按 GroupId 局部加载 PunishaarHud 组（Id 规则 10000+GroupId*100+index_in_group，连续读直到空视为组结束）。
--- 填充式（调用方提供 out 表，本方法清旧后填），返组内条目数。表 Id 由导表 PunishaarHud.py compute_func 算
---   10000+GroupId*100+index（CommonIdRecombine group_index 1-based；如 GroupId 2→10201,10202,...），此处须对齐。#HudId对齐
---@param groupId number PunishaarHud.GroupId
---@param out table 调用方提供并自清的容器
---@return number count
function XPunishaarGameControl:GetHudCfgsByGroup(groupId, out)
    for k in pairs(out) do out[k] = nil end
    if not groupId or groupId == 0 then return 0 end
    local MAX_HUD_PER_GROUP = 100  -- 防御上限（规则1 连续+空结束，正常远达不到；防表配错死循环）
    local count = 0
    local idx = 1
    while idx <= MAX_HUD_PER_GROUP do
        local cfg = self:GetTablePunishaarHud(10000 + groupId * 100 + idx, true)  -- Id=10000+GroupId*100+idx 对齐导表 compute_func（nil 不报错）
        if not cfg then break end  -- 空视为组结束
        count = count + 1
        out[count] = cfg
        idx = idx + 1
    end
    return count
end

return XPunishaarGameControl
