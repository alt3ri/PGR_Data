--[[4.2 到九期为止都没在用过，注释掉减少代码重构的调整范围

local XUiGridStage = require("XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStage")

--- 五期的资源点，驻守炮击玩法
local XUiGridStageResource = XClass(XUiGridStage, "XUiGridStageResource")

function XUiGridStageResource:Ctor()
    self._EffectExplode = self.Transform.parent:Find('EffectExplode')
    self._EffectShield = self.Transform.parent:Find('EffectShield')
    
    self._EffectExplode.gameObject:SetActiveEx(false)
    self._EffectShield.gameObject:SetActiveEx(false)

end

function XUiGridStageResource:UpdateGrid(nodeEntity, IsPathEdit, IsActionPlaying, isPathEditOver)
    self.Super.UpdateGrid(self,nodeEntity, IsPathEdit, IsActionPlaying, isPathEditOver)
    self.BtnStage:SetRawImage(nodeEntity:GetIcon())
    self:RefreshGarrison() 
    self:RefreshRebuildState()
    self:RefreshNormalIcon()
end

function XUiGridStageResource:RefreshGarrison()
    ---@type XGuildWarGarrisonData
    local garrisonData = XMVCA.XGuildWar:GetGarrisonData()
    
    --更新资源点的驻守百分比
    if self.DefendPercentText then
        self.DefendPercentText.transform.parent.gameObject:SetActiveEx(true)
        
        local percent = garrisonData:GetDefensePlayerPercentById(self.StageNodeId)
        self.DefendPercentText.text = string.format("%d",math.floor(percent * 100))..'%'
    end
    if self.Garrison then
        self._IsDefend = garrisonData:CheckDefensePointIsPlayerInById(self.StageNodeId)
        self.Garrison.gameObject:SetActiveEx(self._IsDefend)
        self.PanelMe.gameObject:SetActiveEx(self._IsDefend)
    end
end

function XUiGridStageResource:RefreshRebuildState()
    --更新重建显示
    if self.Rebuild then
        ---@type XGuildWarGarrisonData
        local garrisonData = XMVCA.XGuildWar:GetGarrisonData()
        self._IsRebuild = garrisonData:IsDefensePointRebuilding(self.StageNodeId)
        self.Rebuild.gameObject:SetActiveEx(self._IsRebuild)
        if self.GarrisonBg then
            self.GarrisonBg.gameObject:SetActiveEx(not self._IsRebuild)
        end
        
        local nodeEntity = XDataCenter.GuildWarManager.GetNode(self.StageNodeId)

        if nodeEntity then
            if self._IsRebuild then
                local icons = XGuildWarConfig.GetClientConfigValues('ResNodeRebuildIcons')
                self.BtnStage:SetRawImage(icons[nodeEntity.Config.StageIndex])
            else
                self.BtnStage:SetRawImage(nodeEntity:GetIcon())
            end
        end
    end
end

function XUiGridStageResource:RefreshNormalIcon()
    self.Normal.gameObject:SetActiveEx(not self._IsRebuild and not self._IsDefend)
end

function XUiGridStageResource:UpdateNodeData()
    ---@type XGuildWarGarrisonData
    local garrisonData = XMVCA.XGuildWar:GetGarrisonData()
    local latestNode = garrisonData:GetLatestResourceNodeId(self.StageNodeId)
    if latestNode then
        local nodeEntity = XDataCenter.GuildWarManager.GetNode(self.StageNodeId)

        if nodeEntity then
            nodeEntity:UpdateWithServerData(latestNode)
        end
    end
end

function XUiGridStageResource:ShowEffectShield(enable)
    self._EffectShield.gameObject:SetActiveEx(enable)
end

function XUiGridStageResource:ShowEffectExplode(enable)
    self._EffectExplode.gameObject:SetActiveEx(enable)
end

---炮击动画期间隐藏重建、驻守标记以及百分比
function XUiGridStageResource:SetDisplayWithAttackAnimation(isAnimation)
    if isAnimation then
        self.Normal.gameObject:SetActiveEx(true)
        self.Rebuild.gameObject:SetActiveEx(false)
        self.Garrison.gameObject:SetActiveEx(false)
        self.PanelMe.gameObject:SetActiveEx(false)
        self.DefendPercentText.transform.parent.gameObject:SetActiveEx(false)
    else
        self:RefreshGarrison()
        self:RefreshRebuildState()
        self:RefreshNormalIcon()
    end
end

return XUiGridStageResource

--]]