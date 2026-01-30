---@class XBigWorldModel : XModel
local XBigWorldModel = XClass(XModel, "XBigWorldModel")

local GuideTableKey = {
    BigWorldGuideGroup = "Share/BigWorld/Common/Guide/BigWorldGuideGroup.tab",
    BigWorldGuideComplete = "Share/BigWorld/Common/Guide/BigWorldGuideComplete.tab",
}

local CommonTableKey = {
    BigWorldLevelFovSave = "Share/BigWorld/Common/FovSave/BigWorldLevelFovSave.tab",
}

function XBigWorldModel:OnInit()
    local identifier = "Id"
    local readInt = XConfigUtil.ReadType.Int
    local config = {
        [GuideTableKey.BigWorldGuideGroup] = {
            readInt,
            XTable.XTableGuideGroup,
            identifier,
            XConfigUtil.CacheType.Normal,
        },
        [GuideTableKey.BigWorldGuideComplete] = {
            readInt,
            XTable.XTableGuideComplete,
            identifier,
            XConfigUtil.CacheType.Normal,
        },
        [CommonTableKey.BigWorldLevelFovSave] = {
            readInt,
            XTable.XTableBigWorldLevelFovSave,
            identifier,
            XConfigUtil.CacheType.Normal,
        },
    }
    self._ConfigUtil:InitConfig(config)

    self._DefaultPerspectiveGroupId = 0

    -- 关卡人称数据
    self._LevelPerspectiveData = {}
    
    self._FinishOpenGuideIdDict = {}
end

function XBigWorldModel:ClearPrivate()
end

function XBigWorldModel:ResetAll()
    self._LevelPerspectiveData = nil
end

function XBigWorldModel:GetCookieKey(key)
    return string.format("BIG_WORLD_%s_%s_%s", self._Id, XPlayer.Id, key)
end

---@return table<number, XTableGuideGroup>
function XBigWorldModel:GetBigWorldGuideGroupTemplates()
    return self._ConfigUtil:Get(GuideTableKey.BigWorldGuideGroup)
end

---@return XTableGuideGroup
function XBigWorldModel:GetBigWorldGuideGroupTemplateById(guideId)
    return self._ConfigUtil:GetCfgByPathAndIdKey(GuideTableKey.BigWorldGuideGroup, guideId)
end

---@return table<number, XTableGuideComplete>
function XBigWorldModel:GetBigWorldGuideCompleteTemplates()
    return self._ConfigUtil:Get(GuideTableKey.BigWorldGuideComplete)
end

---@return XTableGuideComplete
function XBigWorldModel:GetBigWorldGuideCompleteTemplateById(completeId)
    return self._ConfigUtil:GetCfgByPathAndIdKey(GuideTableKey.BigWorldGuideComplete, completeId)
end

function XBigWorldModel:UpdateFinishGuideDict(idList)
    if not idList then
        return
    end
    for _, guideId in pairs(idList) do
        self._FinishOpenGuideIdDict[guideId] = true
    end
end

function XBigWorldModel:AddFinishGuideDict(guideId)
    self._FinishOpenGuideIdDict[guideId] = true
end

function XBigWorldModel:CheckOpenGuideFinish(guideId)
    return self._FinishOpenGuideIdDict[guideId] ~= nil
end

function XBigWorldModel:GetDefaultPerspectiveGroupId()
    return self._DefaultPerspectiveGroupId
end

function XBigWorldModel:InitPerspective(perspectiveData)
    if XTool.IsTableEmpty(perspectiveData) then
        return
    end
    local defaultPerspective = perspectiveData.FovType
    local levelPerspectiveData = perspectiveData.LevelFovDatas
    if not defaultPerspective or not XTool.IsNumberValid(defaultPerspective) then
        XLog.Error("XSkyGardenModel:InitPerspective error: FovType is invalid")
    end
    self._LevelPerspectiveData = levelPerspectiveData
    self._LevelPerspectiveData[self:GetDefaultPerspectiveGroupId()] = defaultPerspective
end

function XBigWorldModel:UpdatePerspective(groupId, perspectiveId)
    self._LevelPerspectiveData[groupId] = perspectiveId
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_PERSPECTIVE_CHANGED)
end

function XBigWorldModel:GetDefaultPerspective()
    return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetInt("DefaultPerspective")
end

function XBigWorldModel:GetPerspective(levelId)
    local groupId = self:GetPerspectiveGroupId(levelId)
    if not self._LevelPerspectiveData[groupId] then
        return self:GetDefaultPerspective()
    end
    return self._LevelPerspectiveData[groupId]
end

function XBigWorldModel:IsSavePerspective(levelId)
    local groupId = self:GetPerspectiveGroupId(levelId)
    return self._LevelPerspectiveData[groupId] ~= nil
end

function XBigWorldModel:GetPerspectiveGroupId(levelId)
    ---@type XTableBigWorldLevelFovSave
    local template = self._ConfigUtil:GetCfgByPathAndIdKey(CommonTableKey.BigWorldLevelFovSave, levelId, true)
    if not template then
        return self:GetDefaultPerspectiveGroupId()
    end
    return template.FovGroupId
end

return XBigWorldModel