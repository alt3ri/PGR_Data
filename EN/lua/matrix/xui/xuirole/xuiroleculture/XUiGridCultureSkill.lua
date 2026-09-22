---@class XUiGridCultureSkill : XUiNode
local XUiGridCultureSkill = XClass(XUiNode, "XUiGridCultureSkill")

local COLOR_NORMAL = CS.UnityEngine.Color.white
local _, COLOR_PREVIEW = CS.UnityEngine.ColorUtility.TryParseHtmlString("#fee82a")

-- 技能图标缓存：GetSkillGradeDesWithDetailConfig 开销大，一次角色全部技能的加载达到117k，故缓存
-- 嵌套表 _SkillIconCache[subSkillId][level] = icon
local _SkillIconCache = {}

local function GetCultureSkillIcon(agency, subSkillId, level)
    local levelDic = _SkillIconCache[subSkillId]
    if not levelDic then
        levelDic = {}
        _SkillIconCache[subSkillId] = levelDic
    end
    local icon = levelDic[level]
    if icon == nil then
        icon = agency:GetSkillGradeDesWithDetailConfig(subSkillId, level).Icon
        levelDic[level] = icon
    end
    return icon
end

function XUiGridCultureSkill:OnStart()
    self.GridSkill:AddEventListener(handler(self, self.OnBtnClick))
end

function XUiGridCultureSkill:Update(info)
    self.ClickInfo = info
    local agency = XMVCA.XCharacter
    local characterId = self.Parent.CharacterId

    local icon, curLv
    if info.IsEnhance then
        local group = agency:GetCharacter(characterId):GetEnhanceSkillGroupData(info.GroupId)
        curLv = group:GetLevel()
        icon = group:GetIcon(info.SkillId, math.max(curLv, 1))
    else
        local groupId = agency:GetSkillGroupIdAndIndex(info.SubSkillId)
        curLv = agency:GetCharacter(characterId):GetSkillLevel(groupId)
        local minMax = agency:GetSubSkillMinMaxLevel(info.SubSkillId)
        icon = GetCultureSkillIcon(agency, info.SubSkillId, math.max(curLv, minMax.Min))
    end

    self.GridSkill:SetSprite(icon)
    self:RefreshPreview(curLv, info.PreviewLv)
end

--- 三态刷新
function XUiGridCultureSkill:RefreshPreview(curLv, previewLv)
    local isLocked = curLv <= 0 and previewLv <= 0
    self.GridSkill:SetDisable(isLocked)
    local isPreview = previewLv > curLv
    local text = isLocked and "" or (CS.XTextManager.GetText("RoleCultureGrade", isPreview and previewLv or curLv))
    local color = isPreview and COLOR_PREVIEW or COLOR_NORMAL
    self.GridSkill:SetName(text)
    self.GridSkill:SetColor(color)
end

function XUiGridCultureSkill:SetClickCb(cb)
    self.ClickCb = cb
end

function XUiGridCultureSkill:OnBtnClick()
    if self.ClickCb then
        self.ClickCb(self.ClickInfo)
    end
end

return XUiGridCultureSkill
