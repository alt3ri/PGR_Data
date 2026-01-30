---@class XUiPanelMainLineLuosaitaPositionDetail
---@field _Control XMainLineLuosaitaControl
local XUiPanelMainLineLuosaitaPositionDetail = XClass(XUiNode, "XUiPanelMainLineLuosaitaPositionDetail")

function XUiPanelMainLineLuosaitaPositionDetail:OnStart()
    self:RegisterUiEvents()
end

function XUiPanelMainLineLuosaitaPositionDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
end

function XUiPanelMainLineLuosaitaPositionDetail:OnBtnCloseClick()
    if self.IsClosing then return end
    
    self.IsClosing = true
    self.DisEnable = self.DisEnable or self.Transform:FindTransform("DisEnable"):GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
    self.DisEnable.gameObject:PlayTimelineAnimation(function()
        self.IsClosing = false
        self:Close()
    end)
end

-- 刷新界面
---@param posId number
function XUiPanelMainLineLuosaitaPositionDetail:Refresh(posId)
    self.ImgDocTag.gameObject:SetActiveEx(false)
    self.PanelAttributeArmy.gameObject:SetActiveEx(false)
    self.PanelAttributeEnemy.gameObject:SetActiveEx(false)
    
    local positionInfo = self._Control:GetPositionInfo(posId)
    local name = ""
    local desc = ""
    local docIds
    local panelAttribute
    if positionInfo:IsArmy() then
        local armyId = positionInfo:GetArmyId()
        local config = self._Control:GetConfig():GetConfigArmy(armyId)
        name = config.Name
        desc = config.Desc
        self.RImgArmyHead:SetRawImage(config.Head)
        panelAttribute = self.PanelAttributeArmy
    elseif positionInfo:IsEnemy() then
        local enemyId = positionInfo:GetEnemyId()
        local config = self._Control:GetConfig():GetConfigEnemy(enemyId)
        name = config.Name
        desc = config.Desc
        docIds = config.DocIds
        self.RImgEnemyHead:SetRawImage(config.Head)
        panelAttribute = self.PanelAttributeEnemy
    elseif positionInfo:IsCharacter() then
        local characterId = positionInfo:GetCharacterId()
        local config = self._Control:GetConfig():GetConfigCharacter(characterId)
        name = config.Name
        desc = config.Desc
        self.RImgCharacterHead:SetRawImage(config.Head)
        self.ImgCharacterHeadCircle:SetSprite(config.HeadCircle)
    end
    self.TxtName.text = name
    self.TxtDetail.text = desc
    self.ImgBgArmy.gameObject:SetActiveEx(positionInfo:IsArmy())
    self.ImgBgEnemy.gameObject:SetActiveEx(positionInfo:IsEnemy())
    self.ImgBgCharacter.gameObject:SetActiveEx(positionInfo:IsCharacter())
    
    -- 属性
    if panelAttribute then
        panelAttribute.gameObject:SetActiveEx(true)
        panelAttribute:GetObject("TxtHP").text = self._Control:GetPositionCurHp(positionInfo:GetPosId())
        panelAttribute:GetObject("TxtAttack").text = self._Control:GetPositionCurAttack(positionInfo:GetPosId())
    end
    
    -- 文件掉落标签
    local isShowDocTag = docIds and #docIds > 0
    self.ImgDocTag.gameObject:SetActiveEx(isShowDocTag)
end

return XUiPanelMainLineLuosaitaPositionDetail
