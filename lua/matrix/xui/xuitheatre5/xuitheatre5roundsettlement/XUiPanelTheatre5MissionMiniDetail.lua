--- 回合结算专用的，只在已领取奖励时显示奖励道具描述的任务奖励弹窗
---@class XUiPanelTheatre5MissionMiniDetail: XUiNode
---@field _Control XTheatre5Control
local XUiPanelTheatre5MissionMiniDetail = XClass(XUiNode, 'XUiPanelTheatre5MissionMiniDetail')

function XUiPanelTheatre5MissionMiniDetail:OnStart()
    if self.BtnBagMaskDetailShow then
        self.BtnBagMaskDetailShow.gameObject:SetActiveEx(false)
        self.BtnBagMaskDetailShow:AddEventListener(handler(self, self.Close))
    end
end

function XUiPanelTheatre5MissionMiniDetail:OnEnable()
    if self.BtnBagMaskDetailShow then
        self.BtnBagMaskDetailShow.gameObject:SetActiveEx(true)
    end
    self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL, self.Close, self)
end

function XUiPanelTheatre5MissionMiniDetail:OnDisable()
    if self.BtnBagMaskDetailShow then
        self.BtnBagMaskDetailShow.gameObject:SetActiveEx(false)
    end
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL, self.Close, self)
end

function XUiPanelTheatre5MissionMiniDetail:RefreshDetail(itemId, level)
    local itemCfg = self._Control:GetTheatre5ItemCfgById(itemId)

    if itemCfg then
        -- 奖励名称
        local name = itemCfg.Name
        
        self.TxtName.text = name

        -- 奖励图标
        if not string.IsNilOrEmpty(itemCfg.IconRes) then
            self.RImgTaskIcon:SetRawImage(itemCfg.IconRes)
        end
        
        -- 奖励等级
        if self.TxtLv then
            self.TxtLv.text = XMVCA.XTheatre5:GetClientConfig('MissionLvFormat', 1, level)
        end
    end
    
    self.TxtActivate.transform.parent.gameObject:SetActiveEx(true)
    self.TxtActivate.text = XMVCA.XTheatre5:GetClientConfig('MissionCompleteLabel')

    -- 显示奖励描述
    self.TxtRewardDes.text = self._Control:GetItemDesc(itemCfg)
    
    -- 隐藏升级花销、显示已完成的文本
    if self.PanelConsume then
        self.PanelConsume.gameObject:SetActiveEx(false)
    end
end




return XUiPanelTheatre5MissionMiniDetail