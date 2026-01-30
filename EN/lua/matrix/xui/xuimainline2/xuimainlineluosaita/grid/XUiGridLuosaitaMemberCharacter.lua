local XUiGridLuosaitaMember = require("XUi/XUiMainLine2/XUiMainLineLuosaita/Grid/XUiGridLuosaitaMember")

---@class XUiGridLuosaitaMemberCharacter : XUiNode
---@field Parent XUiPanelLuosaitaSection
---@field _Control XMainLineLuosaitaControl
---@field MemberData XMainLineLuosaitaPositionInfo
local XUiGridLuosaitaMemberCharacter = XClass(XUiGridLuosaitaMember, "XUiGridLuosaitaMemberCharacter")

function XUiGridLuosaitaMemberCharacter:OnStart()
    self:RegisterUiEvents()
end

function XUiGridLuosaitaMemberCharacter:OnDisable()
    self:ShowMovingEffect(false)
end

function XUiGridLuosaitaMemberCharacter:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnBtnClick)
end

function XUiGridLuosaitaMemberCharacter:OnBtnClick()
    if self.Parent:IsDragOperation() then
        return
    end

    self:OpenMemberDetail()
end

---@param memberData XMainLineLuosaitaPositionInfo
function XUiGridLuosaitaMemberCharacter:Refresh(memberData)
    self.MemberData = memberData

    local characterId = memberData:GetCharacterId()
    local head = self._Control:GetConfig():GetCharacterHead(characterId)
    local headCircle = self._Control:GetConfig():GetCharacterHeadCircle(characterId)
    self.RImgHead:SetRawImage(head)
    self.ImgCircle:SetSprite(headCircle)

    -- 新增特效
    local sectionInfo = self._Control:GetSectionInfo(self.Parent.SectionId)
    if sectionInfo:IsPosInfoNewAdd(memberData:GetType(), characterId) then
        self:PlayAnimation("AnimEnableStar")
    end

    -- 刷新条件动画
    self:RefreshConditionAnim()
end

-- 刷新条件动画
function XUiGridLuosaitaMemberCharacter:RefreshConditionAnim()
    if self.IsConditionAnimPlay then return end

    local characterId = self.MemberData:GetCharacterId()
    local animName = self._Control:GetConfig():GetCharacterAnimName(characterId)
    if string.IsNilOrEmpty(animName) then return end

    local conditionId = self._Control:GetConfig():GetCharacterAnimConditionId(characterId)
    local isReach = true -- 不填conditionId视为默认播放
    local tips
    if XTool.IsNumberValidEx(conditionId) then
        isReach, tips = XConditionManager.CheckCondition(conditionId)
    end
    if isReach then
        self:PlayAnimation(animName)
        self.IsConditionAnimPlay = true
    end
end

function XUiGridLuosaitaMemberCharacter:OnDestory()
    
end

function XUiGridLuosaitaMemberCharacter:Hide()
    self:PlayAnimation("AnimDisEnable", function()
        self:Close()
    end)
end

function XUiGridLuosaitaMemberCharacter:ShowMovingEffect(isShow)
    if self.FxUiLuosaita_Trails then
        self.FxUiLuosaita_Trails.gameObject:SetActiveEx(isShow)
    end
end

return XUiGridLuosaitaMemberCharacter
