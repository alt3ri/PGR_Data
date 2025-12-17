--- 技能栏
---@class XUiPanelTheatre5Skill: XUiNode
---@field private _Control XTheatre5Control
---@field Parent XUiTheatre5BattleShop
local XUiPanelTheatre5Skill = XClass(XUiNode, 'XUiPanelTheatre5Skill')
local XUiGridTheatre5ShopContainer = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5ShopContainer')

function XUiPanelTheatre5Skill:OnStart(customContainerCls, containerType)
    self:InitSkillContainers(customContainerCls)
    self:RefreshSkillShow()
    
    self._ContainerType = containerType
end

function XUiPanelTheatre5Skill:OnEnable()
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_SKILL_SHOW, self.RefreshSkillShow, self)
end

function XUiPanelTheatre5Skill:OnDisable()
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_SKILL_SHOW, self.RefreshSkillShow, self)
end

function XUiPanelTheatre5Skill:InitSkillContainers(customContainerCls)
    ---@type XUiGridTheatre5ShopContainer[]
    self.GridContainers = {}
    
    local skillGridCount = self._Control.ShopControl:GetSkillListSize()

    self.GridSkill.gameObject:SetActiveEx(false)

    for index = 1, skillGridCount do
        local go = CS.UnityEngine.GameObject.Instantiate(self.GridSkill, self.GridSkill.transform.parent.transform)
        ---@type XUiGridTheatre5ShopContainer
        local grid = customContainerCls and customContainerCls.New(go, self) or XUiGridTheatre5ShopContainer.New(go, self)
        grid:Open()
        grid:SetContainerType(XMVCA.XTheatre5.EnumConst.ItemContainerType.SkillBlock)
        grid:SetContainerIndex(index)

        if not grid:GetIsInitBindItems() then
            grid:InitBindItem()
        end
        
        self.GridContainers[index] = grid
    end
end

function XUiPanelTheatre5Skill:RefreshSkillShow()
    for i, v in ipairs(self.GridContainers) do
        v:SetItemData(self._Control.ShopControl:GetItemInSkillListByIndex(i))
        if self._ContainerType then
            v:SetContainerType(self._ContainerType)
        end
    end
end

return XUiPanelTheatre5Skill