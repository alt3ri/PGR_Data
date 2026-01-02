local XUiGridLuosaitaMember = require("XUi/XUiMainLine2/XUiMainLineLuosaita/Grid/XUiGridLuosaitaMember")
local Quaternion = CS.UnityEngine.Quaternion

---@class XUiGridLuosaitaMemberArmy : XUiNode
---@field _Control XMainLineLuosaitaControl
---@field Parent XUiPanelLuosaitaSection
---@field UiMain XUiMainLineLuosaitaMain
---@field MemberData XMainLineLuosaitaPositionInfo
local XUiGridLuosaitaMemberArmy = XClass(XUiGridLuosaitaMember, "XUiGridLuosaitaMemberArmy")

function XUiGridLuosaitaMemberArmy:OnStart()
    self:RegisterUiEvents()
end

function XUiGridLuosaitaMemberArmy:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnBtnClick)
    self.GoInputHandler:AddBeginDragListener(function(eventData) self:OnCharacterBeginDrag(eventData) end)
    self.GoInputHandler:AddDragListener(function(eventData) self:OnCharacterDrag(eventData) end)
    self.GoInputHandler:AddEndDragListener(function(eventData) self:OnCharacterEndDrag(eventData) end)
end

function XUiGridLuosaitaMemberArmy:OnBtnClick()
    if self.Parent:IsDragOperation() then
        return
    end

    self:OpenMemberDetail()
end

---@param memberData XMainLineLuosaitaPositionInfo
function XUiGridLuosaitaMemberArmy:Refresh(memberData)
    self.MemberData = memberData
    self.Arrow = self.UiMain.Arrow
    if not memberData or not memberData:IsArmy() then
        return
    end

    local posId = memberData:GetPosId()
    local curHp = self._Control:GetPositionCurHp(posId)
    local curAttack = self._Control:GetPositionCurAttack(posId)
    self.TxtAttack.text = tostring(curAttack)
    self.TxtHP.text = tostring(curHp)
end

function XUiGridLuosaitaMemberArmy:OnCharacterBeginDrag(eventData)
    self.Parent:SetAreaScaleDragEnable(false)
    
    local pos = XUiHelper.GetScreenClickPosition(self.UiMain.Transform, self.Camera)
    self.DragStarPos = pos
    self.Arrow.localPosition = pos
    self.V2.x = self.Arrow.sizeDelta.x
    self.Arrow.sizeDelta = Vector2(self.V2.x, 0);
    self.Arrow.gameObject:SetActiveEx(true)
end

function XUiGridLuosaitaMemberArmy:OnCharacterDrag(eventData)
    local pos = XUiHelper.GetScreenClickPosition(self.UiMain.Transform, self.Camera)

    self.V2.x = pos.x - self.DragStarPos.x
    self.V2.y = pos.y - self.DragStarPos.y
    local height = XLuaVector2.Magnitude(self.V2)
    local rotationAngle = math.atan(pos.y - self.DragStarPos.y, pos.x - self.DragStarPos.x) * CS.UnityEngine.Mathf.Rad2Deg - 90
    local rotation = Quaternion.AngleAxis(rotationAngle, Vector3.forward)
    self.Arrow.sizeDelta = Vector2(self.Arrow.sizeDelta.x, height);
    self.Arrow.rotation = rotation
    self:PreSelectEnemy(eventData.position)
end

function XUiGridLuosaitaMemberArmy:OnCharacterEndDrag(eventData)
    self.Parent:SetAreaScaleDragEnable(true)
    
    if self.PreSelectTarget then
        self.Parent:MoveToPos(self.MemberData:GetPosId(), self.PreSelectTarget)
    end
    self.Arrow.gameObject:SetActiveEx(false)
    self.UiMain:ClearTalk()
    self.UiMain:ClosePanelFight()
end

local TempV2Target = Vector2(0, 0)
function XUiGridLuosaitaMemberArmy:PreSelectEnemy(screenPoint)
    self.PreSelectTarget = nil
    TempV2Target.x = screenPoint.x
    TempV2Target.y = screenPoint.y
    local screenPointV2 = TempV2Target

    local pos, posUi = self:GetPosIndex(screenPointV2)
    if not pos or pos == self.MemberData:GetPosId() then
        self.UiMain:SetTalkByClientConfigKey(XMVCA.XMainLineLuosaita.EnumConst.TALK_TYPE.INFO, "DragTips1")
        self.UiMain:ClosePanelFight()
        return
    end
    local enemyId = posUi.MemberData:GetEnemyId()
    if not posUi.MemberData:IsEnemy() or not self._Control:IsEnemyShow(enemyId) then
        self.UiMain:SetTalkByClientConfigKey(XMVCA.XMainLineLuosaita.EnumConst.TALK_TYPE.INFO, "DragTips1")
        return
    end
    local endPosInfo = self._Control:GetPositionInfo(pos)
    local isCanMove, tips = self._Control:IsCanMovePosition(self.MemberData, endPosInfo)
    if not isCanMove then
        self.UiMain:SetTalk(XMVCA.XMainLineLuosaita.EnumConst.TALK_TYPE.WARNING, tips)
        return
    end

    self.UiMain:SetTalkByClientConfigKey(XMVCA.XMainLineLuosaita.EnumConst.TALK_TYPE.INFO, "DragTips4")
    self.PreSelectTarget = pos
    self.PreSelectTargetData = posUi
    self.UiMain:SetFight(self.MemberData, self.PreSelectTargetData.MemberData)
end

function XUiGridLuosaitaMemberArmy:GetBlockIndex(screenPointV2)
    local gridBlocks = self.Parent:GetGridBlocks()
    for index, block in ipairs(gridBlocks) do
        local isInside = CS.UnityEngine.RectTransformUtility.RectangleContainsScreenPoint(block.Transform, screenPointV2, self.Camera)
        if isInside then
            return index
        end
    end
    return nil
end

function XUiGridLuosaitaMemberArmy:GetPosIndex(screenPointV2)
    local targetPosId = nil
    local targetPosData = nil
    local gridMembers = self.Parent:GetGridMembers()
    for posId, enemyUi in pairs(gridMembers) do
        if enemyUi.IsInSize and enemyUi:IsInSize(screenPointV2) then
            targetPosId = posId
            targetPosData = enemyUi
        end
    end
    return targetPosId, targetPosData
end

return XUiGridLuosaitaMemberArmy
