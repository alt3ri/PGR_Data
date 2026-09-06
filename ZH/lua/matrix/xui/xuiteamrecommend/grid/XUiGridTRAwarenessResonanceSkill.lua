-- 引用LuaUi：UiTeamRecommendRoleTargetDetail、UiTeamRecommendResonanceSkillPopup
---@class XUiGridTRAwarenessResonanceSkill : XUiNode
---@field TargetMatchMode XEquipAwarenessResonanceTargetMatchMode|nil 当前展示的目标匹配模式
local XUiGridTRAwarenessResonanceSkill = XClass(XUiNode, "XUiGridTRAwarenessResonanceSkill")
local TARGET_MATCH_MODE = XEnumConst.EQUIP.AWARENESS_RESONANCE_TARGET_MATCH_MODE

local function SetActive(ui, isActive)
    if ui then
        ui.gameObject:SetActiveEx(isActive)
    end
end

function XUiGridTRAwarenessResonanceSkill:OnStart()
    self.BtnClick.CallBack = function() self:OnBtnClick() end
end

function XUiGridTRAwarenessResonanceSkill:SetEnableClick(isEnable)
    self.BtnClick.gameObject:SetActiveEx(isEnable)
end

---@class XUiGridTRAwarenessResonanceSkillData
---@field ResonanceData table|nil 目标共鸣数据
---@field Site number 意识位，1~6
---@field Pos number 共鸣槽位，1~2
---@field WearingEquipId number|nil 当前穿戴的目标意识 Id
---@field TargetState XEquipAwarenessResonanceTargetState|nil 目标状态
---@field ShowBindCharacterMismatch boolean|nil 是否显示绑定角色不匹配标记，默认不显示
---@field TargetMatchMode XEquipAwarenessResonanceTargetMatchMode|nil 目标匹配模式，不传时展示实际技能
---@param data XUiGridTRAwarenessResonanceSkillData
function XUiGridTRAwarenessResonanceSkill:Refresh(data)
    local resonanceData = data and data.ResonanceData
    local awarenessSite = data and data.Site
    local resonanceSlot = data and data.Pos
    local wearingEquipId = data and data.WearingEquipId
    local targetState = data and data.TargetState
    local showBindCharacterMismatch = data ~= nil and data.ShowBindCharacterMismatch == true
    local targetMatchMode = data and data.TargetMatchMode
    self.ResonanceData = resonanceData
    self.Site = awarenessSite
    self.Pos = resonanceSlot or resonanceData and resonanceData.Pos or self.Pos
    self.WearingEquipId = wearingEquipId
    self.TargetMatchMode = targetMatchMode
    self.SkillInfo = resonanceData
        and XMVCA.XEquip:CreateResonanceSkillInfo(resonanceData.ResonanceType, resonanceData.SkillId) or nil

    self:Open()
    if not self.SkillInfo then
        self:RefreshEmpty()
    else
        self:RefreshSkill()
    end
    self:_RefreshSite()
    self:RefreshTargetMatchMode(targetMatchMode)
    self:RefreshTargetState(targetState, showBindCharacterMismatch)
end

-- 按目标匹配模式互斥刷新指定技能、任意攻击和任意技能图标。
---@param targetMatchMode XEquipAwarenessResonanceTargetMatchMode|nil
function XUiGridTRAwarenessResonanceSkill:RefreshTargetMatchMode(targetMatchMode)
    local isRandomAttack = targetMatchMode == TARGET_MATCH_MODE.ATTACK
    local isRandomSkill = targetMatchMode == TARGET_MATCH_MODE.ANY
    local isRandom = isRandomAttack or isRandomSkill
    local isTargetSkill = not isRandom and self.SkillInfo ~= nil
    SetActive(self.BgEmpty, not isRandom and not isTargetSkill)
    SetActive(self.RImgEmpty, not isRandom and not isTargetSkill)
    SetActive(self.BgSkill, isTargetSkill)
    SetActive(self.BgRandom, isRandom)
    SetActive(self.RImgResonanceSkill, isTargetSkill)
    SetActive(self.RImgRandomAttackSkill, isRandomAttack)
    SetActive(self.RImgRandomSkill, isRandomSkill)
end

function XUiGridTRAwarenessResonanceSkill:RefreshBaseState(isSkill)
    SetActive(self.BgEmpty, not isSkill)
    SetActive(self.RImgEmpty, not isSkill)
    SetActive(self.BgSkill, isSkill)
    SetActive(self.RImgResonanceSkill, isSkill)
    self:SetSelected(isSkill)
    SetActive(self.PanelAwakenRoot, false)
    SetActive(self.PanelAwaken, false)
    SetActive(self.PanelNeedAwake, false)
    SetActive(self.ImgPos, true)
    SetActive(self.TxtPos, true)
end

function XUiGridTRAwarenessResonanceSkill:SetActiveImgPos(flag)
    SetActive(self.ImgPos, flag)
    SetActive(self.TxtPos, flag)
end

function XUiGridTRAwarenessResonanceSkill:RefreshAwakenState()
    local isWearing = XTool.IsNumberValid(self.WearingEquipId)
    local isAwakeSupported = not isWearing or XMVCA.XEquip:CheckEquipStarCanAwake(self.WearingEquipId)
    SetActive(self.PanelAwakenRoot, isAwakeSupported)
    if isAwakeSupported then
        local isOverclocking = isWearing and XMVCA.XEquip:IsEquipPosAwaken(self.WearingEquipId, self.Pos) or false
        SetActive(self.PanelAwaken, isOverclocking)
        SetActive(self.PanelNeedAwake, not isOverclocking)
    end
end

-- 刷新意识位置编号
function XUiGridTRAwarenessResonanceSkill:_RefreshSite()
    if self.TxtPos then
        local site = self.Site or 0
        self.TxtPos.text = string.format("%02d", site)
    end
end

function XUiGridTRAwarenessResonanceSkill:RefreshEmpty()
    self:RefreshBaseState(false)
end

function XUiGridTRAwarenessResonanceSkill:RefreshSkill()
    local skillInfo = self.SkillInfo

    self:RefreshBaseState(true)
    self:RefreshAwakenState()
    if self.RImgResonanceSkill and skillInfo.Icon then
        self.RImgResonanceSkill:SetRawImage(skillInfo.Icon)
    end
end

---@param targetState XEquipAwarenessResonanceTargetState|nil
---@param showBindCharacterMismatch boolean
function XUiGridTRAwarenessResonanceSkill:RefreshTargetState(targetState, showBindCharacterMismatch)
    local hasSkill = self.SkillInfo ~= nil
        or self.TargetMatchMode == TARGET_MATCH_MODE.ANY
        or self.TargetMatchMode == TARGET_MATCH_MODE.ATTACK
    local hasTarget = targetState ~= nil and targetState.HasTarget == true
    local isAchieved = targetState ~= nil and targetState.IsAchieved == true
    local isSelected = hasSkill
    if targetState then
        isSelected = hasTarget and isAchieved
    end

    self:SetSelected(isSelected)
    SetActive(self.ImgNotResonance, showBindCharacterMismatch)
    SetActive(self.BgNotResonanceDark, hasTarget and hasSkill and not isAchieved)
end

function XUiGridTRAwarenessResonanceSkill:SetSelected(isSelected)
    -- TODO BgEffectLight已更名为ImgSelect，待UI重新打包后可删除
    if self.BgEffectLight then
        self.BgEffectLight.gameObject:SetActiveEx(isSelected)
    end
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(isSelected)
    end
end

-- 设置特效显示
function XUiGridTRAwarenessResonanceSkill:SetImgEffectShow(isShow)
    self.ImgEffect.gameObject:SetActiveEx(isShow)
end

function XUiGridTRAwarenessResonanceSkill:OnBtnClick()
    if self.Parent and self.Parent.OnResonanceSkillClick then
        self.Parent:OnResonanceSkillClick(self.Pos, self.Site)
    end
end

return XUiGridTRAwarenessResonanceSkill
