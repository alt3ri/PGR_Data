local XUiGridLuosaitaMember = require("XUi/XUiMainLine2/XUiMainLineLuosaita/Grid/XUiGridLuosaitaMember")

---@class XUiGridLuosaitaMemberEnemy : XUiNode
---@field Parent XUiPanelLuosaitaSection
---@field UiMain XUiMainLineLuosaitaMain
---@field _Control XMainLineLuosaitaControl
---@field MemberData XMainLineLuosaitaPositionInfo
local XUiGridLuosaitaMemberEnemy = XClass(XUiGridLuosaitaMember, "XUiGridLuosaitaMemberEnemy")

function XUiGridLuosaitaMemberEnemy:OnStart()
    self:RegisterUiEvents()
end

function XUiGridLuosaitaMemberEnemy:RegisterUiEvents()
    self.Button = self.GameObject:GetComponent("XUiButton")
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnBtnClick)
end

function XUiGridLuosaitaMemberEnemy:OnBtnClick()
    if self.Parent:IsDragOperation() then
        return
    end
    
    self:OpenMemberDetail()
end

---@param posInfo XMainLineLuosaitaPositionInfo
function XUiGridLuosaitaMemberEnemy:Refresh(posInfo)
    self.MemberData = posInfo
    local sectionId = self.UiMain:GetCurSectionId()
    local posId = posInfo:GetPosId()
    local enemyId = posInfo:GetEnemyId()
    local curHp = self._Control:GetPositionCurHp(posId)
    local curAttack = self._Control:GetPositionCurAttack(posId)

    local head = self._Control:GetConfig():GetEnemyHead(enemyId)
    self.RImgHead:SetRawImage(head)
    self.TxtAttack.text = tostring(curAttack)
    self.TxtHP.text = tostring(curHp)
    local docIds = self.UiMain._Control:GetConfig():GetEnemyDocIds(enemyId)
    self.TagBg.gameObject:SetActiveEx(#docIds > 0)
    
    local isCanBeAttack = self._Control:IsEnemyCanAttack(sectionId, posInfo)
    self.ImgArrow.gameObject:SetActiveEx(isCanBeAttack)

    -- 未满足显示condition
    local isShow = self._Control:IsEnemyShow(enemyId)
    if not isShow then
        self:Close()
    end

    -- 首次显示播放Enable动画
    if isShow and self.LastIsShow == false then
        self:PlayAnimation("AnimEnable")
    end
    self.LastIsShow = isShow
end

function XUiGridLuosaitaMemberEnemy:OnDestory()
    self._LastScreenPoint = nil
end

-- 播放死亡动画
function XUiGridLuosaitaMemberEnemy:PlayAnimDead(cb)
    self:PlayAnimationWithMask("AnimDead", function()
        if cb then cb() end
    end)
end

-- 显示/隐藏选中特效
function XUiGridLuosaitaMemberEnemy:ShowSelectEffect(isShow)
    self.FxUiSelect.gameObject:SetActiveEx(isShow)
end

function XUiGridLuosaitaMemberEnemy:IsInSize(screenPointV2)
    local isInside = CS.UnityEngine.RectTransformUtility.RectangleContainsScreenPoint(self.Transform, screenPointV2, self.Camera)
    return isInside
end

return XUiGridLuosaitaMemberEnemy
