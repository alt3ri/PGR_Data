---@class XDlcRelinkActivity
local XDlcRelinkActivity = XClass(nil, "XDlcRelinkActivity")

function XDlcRelinkActivity:Ctor()
    self.ActivityId = 0
    self.FightCharacterId = 0
    ---@type XDlcRelinkCharacter[]
    self.Characters = {} -- 当前角色列表 key:characterId
    ---@type XDlcRelinkEquipData[]
    self.EquipsDatas = {} -- 装备仓库 key:EquipUId
    ---@type table<number, XDlcRelinkLevelInfo> -- 等级信息 key:levelId
    self.LevelDict = {}
end

function XDlcRelinkActivity:NotifyActivityData(data)
    self.ActivityId = data.ActivityId or 0
    self.FightCharacterId = data.FightCharacterId or 0
    self:UpdateCharacters(data.Characters)
    self:UpdateEquipsDatas(data.EquipsDatas)
    self.LevelDict = data.LevelDict or {}
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

--endregion

--region 设置信息

function XDlcRelinkActivity:SetFightCharacterId(characterId)
    if not XTool.IsNumberValid(characterId) then
        return
    end
    self.FightCharacterId = characterId
end

--endregion

--region 获取信息

function XDlcRelinkActivity:GetActivityId()
    return self.ActivityId
end

function XDlcRelinkActivity:GetFightCharacterId()
    return self.FightCharacterId
end

function XDlcRelinkActivity:GetCharacterDataList()
    return self.Characters
end

function XDlcRelinkActivity:GetCharacterDataByCharacterId(characterId)
    if not XTool.IsNumberValid(characterId) then
        return nil
    end
    return self.Characters[characterId]
end

function XDlcRelinkActivity:GetEquipsDataList()
    return self.EquipsDatas
end

function XDlcRelinkActivity:GetEquipsDataByUid(equipUId)
    if not XTool.IsNumberValid(equipUId) then
        return nil
    end
    return self.EquipsDatas[equipUId]
end

function XDlcRelinkActivity:GetLevelFinishTime(levelId)
    local levelInfo = self.LevelDict and self.LevelDict[levelId]
    if levelInfo and levelInfo.TopRankTeamInfo then
        return levelInfo.TopRankTeamInfo.FinishTime or 0
    end
    return 0
end

--endregion

--region 检查信息

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

---@class XDlcRelinkRankPlayerInfo
---@field PlayerId number 玩家Id
---@field Name string 玩家名字
---@field CharacterId number 使用的角色Id
---@field OccupationType number 职业
---@field HeadPortraitId number 头像Id
---@field HeadFrameId number 头像框Id
---@field TeamId number 队伍职业(是否是队长)

---@class XDlcRelinkRankTeamInfo
---@field PlayerInfos XDlcRelinkRankPlayerInfo[] 小组成员
---@field LevelId number 通关关卡
---@field FinishTime number 完成时间(秒)
---@field Rank number 排名
