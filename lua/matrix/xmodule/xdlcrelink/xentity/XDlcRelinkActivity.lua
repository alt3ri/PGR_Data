---@class XDlcRelinkActivity
local XDlcRelinkActivity = XClass(nil, "XDlcRelinkActivity")

function XDlcRelinkActivity:Ctor()
    self.ActivityId = 0
    self.FightCharacterId = 0
    self.Level = 0
    self.Exp = 0
    -- 每日签到
    self.DailySign = false
    -- 当前角色列表 key:characterId
    ---@type XDlcRelinkCharacter[]
    self.Characters = {}
    -- 装备仓库 key:EquipUid
    ---@type XDlcRelinkEquipData[]
    self.EquipsDatas = {}
    -- 等级信息 key:levelId
    ---@type table<number, XDlcRelinkLevelInfo>
    self.LevelDict = {}
    -- 表情轮盘Id列表
    ---@type number[]
    self.EmojiWheelIds = {}
    -- 装备预设 key:presetIndex
    ---@type table<number, XDlcRelinkEquipPreset>
    self.EquipPresetSets = {}
end

function XDlcRelinkActivity:NotifyActivityData(data)
    self.ActivityId = data.ActivityId or 0
    self.FightCharacterId = data.FightCharacterId or 0
    self.Level = data.Level or 0
    self.Exp = data.Exp or 0
    self.DailySign = data.DailySign or false
    self:UpdateCharacters(data.Characters)
    self:UpdateEquipsDatas(data.EquipsDatas)
    self.LevelDict = data.LevelDict or {}
    self.EmojiWheelIds = data.EmojiWheelIds or {}
    self.EquipPresetSets = data.EquipPresetSets or {}
end

--region 更新信息

function XDlcRelinkActivity:UpdateCharacters(data)
    self.Characters = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddCharacters(v)
    end
end

function XDlcRelinkActivity:AddCharacters(data)
    if not data or not data.CharacterId then
        return
    end
    local character = self.Characters[data.CharacterId]
    if not character then
        character = require("XModule/XDlcRelink/XEntity/XDlcRelinkCharacter").New()
        self.Characters[data.CharacterId] = character
    end
    character:NotifyCharacterData(data)
end

function XDlcRelinkActivity:UpdateEquipsDatas(data)
    self.EquipsDatas = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddEquipsData(v)
    end
end

function XDlcRelinkActivity:AddEquipsData(data)
    if not data or not data.Uid then
        return
    end
    local equipData = self.EquipsDatas[data.Uid]
    if not equipData then
        equipData = require("XModule/XDlcRelink/XEntity/XDlcRelinkEquipData").New()
        self.EquipsDatas[data.Uid] = equipData
    end
    equipData:NotifyEquipData(data)
end

function XDlcRelinkActivity:RemoveEquipsData(equipUid)
    if not XTool.IsNumberValid(equipUid) then
        return
    end
    self.EquipsDatas[equipUid] = nil
end

--endregion

--region 设置信息

-- 设置等级
function XDlcRelinkActivity:SetLevel(level)
    self.Level = level
end

-- 设置经验
function XDlcRelinkActivity:SetExp(exp)
    self.Exp = exp or 0
end

-- 设置每日签到状态
function XDlcRelinkActivity:SetDailySign(dailySign)
    self.DailySign = dailySign or false
end

-- 设置角色职业类型
function XDlcRelinkActivity:SetCharacterOccupationType(characterId, occupationType)
    local character = self:GetCharacterDataByCharacterId(characterId)
    if character then
        character:SetOccupationType(occupationType)
    end
end

-- 设置战斗角色Id
function XDlcRelinkActivity:SetFightCharacterId(characterId)
    if not XTool.IsNumberValid(characterId) then
        return
    end
    self.FightCharacterId = characterId
end

-- 设置装备锁定状态
function XDlcRelinkActivity:SetEquipIsLocked(equipUid, isLock)
    local equipData = self:GetEquipsDataByUid(equipUid)
    if equipData then
        equipData:SetIsLocked(isLock)
    end
end

-- 卸下穿戴的装备
function XDlcRelinkActivity:UnWearEquipByCharacterId(characterId, equipSlotIndex)
    local character = self:GetCharacterDataByCharacterId(characterId)
    if character then
        character:UnWearEquip(equipSlotIndex)
    end
end

-- 设置表情轮盘Id列表
function XDlcRelinkActivity:SetEmojiWheelIds(emojiWheelIds)
    self.EmojiWheelIds = emojiWheelIds or {}
end

-- 设置装备预设（全量）
function XDlcRelinkActivity:SetEquipPresetSets(presetSets)
    self.EquipPresetSets = presetSets or {}
end

-- 设置装备预设（单个）
function XDlcRelinkActivity:SetEquipPresetSetByIndex(presetIndex, presetEquip, presetName)
    if not XTool.IsNumberValid(presetIndex) then
        return
    end
    self.EquipPresetSets[presetIndex] = self.EquipPresetSets[presetIndex] or {}
    self.EquipPresetSets[presetIndex].Slot2EquipUid = presetEquip or {}
    self.EquipPresetSets[presetIndex].Name = presetName or ""
end

--endregion

--region 获取信息

-- 获取活动Id
function XDlcRelinkActivity:GetActivityId()
    return self.ActivityId
end

-- 获取战斗角色Id
function XDlcRelinkActivity:GetFightCharacterId()
    return self.FightCharacterId
end

-- 获取等级
function XDlcRelinkActivity:GetLevel()
    return self.Level
end

-- 获取经验
function XDlcRelinkActivity:GetExp()
    return self.Exp
end

-- 获取每日签到状态
function XDlcRelinkActivity:GetDailySign()
    return self.DailySign
end

-- 获取角色数据列表
function XDlcRelinkActivity:GetCharacterDataList()
    return self.Characters
end

-- 通过角色Id获取角色数据
function XDlcRelinkActivity:GetCharacterDataByCharacterId(characterId)
    if not XTool.IsNumberValid(characterId) then
        return nil
    end
    return self.Characters[characterId]
end

-- 获取装备数据列表
function XDlcRelinkActivity:GetEquipsDataList()
    return self.EquipsDatas
end

-- 通过装备Uid获取装备数据
function XDlcRelinkActivity:GetEquipsDataByUid(equipUid)
    if not XTool.IsNumberValid(equipUid) then
        return nil
    end
    return self.EquipsDatas[equipUid]
end

-- 获取装备数量
function XDlcRelinkActivity:GetEquipsDataCount()
    return table.nums(self.EquipsDatas)
end

-- 获取关卡通关时间
function XDlcRelinkActivity:GetLevelFinishTime(levelId)
    local levelInfo = self.LevelDict and self.LevelDict[levelId]
    if levelInfo and levelInfo.TopRankTeamInfo then
        return levelInfo.TopRankTeamInfo.FinishTime or 0
    end
    return 0
end

-- 获取关卡通关次数
function XDlcRelinkActivity:GetLevelPassTime(levelId)
    local levelInfo = self.LevelDict and self.LevelDict[levelId]
    return levelInfo and levelInfo.PassTime or 0
end

-- 获取表情轮盘Id列表
function XDlcRelinkActivity:GetEmojiWheelIds()
    return self.EmojiWheelIds
end

-- 获取装备预设列表
function XDlcRelinkActivity:GetEquipPresetSetDataList()
    return self.EquipPresetSets
end

-- 通过预设索引获取装备预设
function XDlcRelinkActivity:GetEquipPresetSetDataByIndex(presetIndex)
    if not XTool.IsNumberValid(presetIndex) then
        return nil
    end
    return self.EquipPresetSets[presetIndex]
end

--endregion

--region 检查信息

-- 是否通关某个关卡
function XDlcRelinkActivity:IsLevelPassed(levelId)
    local levelInfo = self.LevelDict and self.LevelDict[levelId]
    return levelInfo and levelInfo.FirstPass or false
end

--endregion

return XDlcRelinkActivity


---@class XDlcRelinkLevelInfo
---@field Level number 等级Id
---@field FirstPass number 是否首次通关
---@field TopRankTeamInfo XDlcRelinkRankTeamInfo 个人最好每个关卡最好成绩
---@field Score number 最高分
---@field PassTime number 通关次数

---@class XDlcRelinkRankPlayerInfo
---@field PlayerId number 玩家Id
---@field Name string 玩家名字
---@field CharacterId number 使用的角色Id
---@field OccupationType number 职业
---@field HeadPortraitId number 头像Id
---@field HeadFrameId number 头像框Id
---@field TeamId number 队伍职业(是否是队长)

---@class CustomRankInfoBase
---@field MemberKey string 成员Key
---@field Score number 分数

---@class XDlcRelinkRankTeamInfo : CustomRankInfoBase
---@field PlayerInfos XDlcRelinkRankPlayerInfo[] 小组成员
---@field LevelId number 通关关卡
---@field FinishTime number 完成时间(秒)

---@class XDlcRelinkEquipPreset
---@field Slot2EquipUid table<number, number> key:装备槽位 value:装备Uid
---@field Name string 预设名称
