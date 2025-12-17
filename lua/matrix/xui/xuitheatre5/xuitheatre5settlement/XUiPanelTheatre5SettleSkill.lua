--- 结算展示技能列表
---@class XUiPanelTheatre5SettleSkill: XUiNode
---@field protected _Control XTheatre5Control
local XUiPanelTheatre5SettleSkill = XClass(XUiNode, 'XUiPanelTheatre5SettleSkill')
local XUiGridTheatre5SettleSkill = require('XUi/XUiTheatre5/XUiTheatre5RoundSettlement/XUiGridTheatre5SettleSkill')

function XUiPanelTheatre5SettleSkill:OnStart(customContainerCls)
    self:InitSkillContainers(customContainerCls)
    self._StartRun = true
end

function XUiPanelTheatre5SettleSkill:OnEnable()
    if self._StartRun then
        self._StartRun = false
        return
    end
    
    self:RefreshShow()
end

function XUiPanelTheatre5SettleSkill:InitSkillContainers(customContainerCls)
    ---@type XUiGridTheatre5ShopContainer[]
    self.GridContainers = {}

    local skillIdList = self._Control:GetCurSelfSkillIdList()
    
    self.GridSkill.gameObject:SetActiveEx(false)

    for index = 1, #skillIdList do
        local go = CS.UnityEngine.GameObject.Instantiate(self.GridSkill, self.GridSkill.transform.parent.transform)
        ---@type XUiGridTheatre5ShopContainer
        local grid = customContainerCls and customContainerCls.New(go, self)
        grid:Open()
        grid:SetContainerType(XMVCA.XTheatre5.EnumConst.ItemContainerType.SkillBlock)
        grid:SetContainerIndex(index)

        if not grid:GetIsInitBindItems() then
            grid:InitBindItem(XUiGridTheatre5SettleSkill)
        end
        
        grid:SetItemShowById(skillIdList[index])

        self.GridContainers[index] = grid
    end
end

function XUiPanelTheatre5SettleSkill:RefreshShow()
    local skillIdList = self._Control:GetCurSelfSkillIdList()

    for index = 1, #skillIdList do
        local grid = self.GridContainers[index]

        if grid then
            grid:SetItemShowById(skillIdList[index])
        end
    end
end

return XUiPanelTheatre5SettleSkill