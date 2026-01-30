--- 任务结算奖励n选1单个选项
---@class XUiGridTheatre5ChooseTaskReward: XUiNode
---@field _Control XTheatre5Control
local XUiGridTheatre5ChooseTaskReward = XClass(XUiNode, 'XUiGridTheatre5ChooseTaskReward')

function XUiGridTheatre5ChooseTaskReward:OnStart()
    self.BtnConfirm:AddEventListener(handler(self, self.OnBtnConfirmClick))
end

function XUiGridTheatre5ChooseTaskReward:Refresh(itemId)
    local itemCfg = self._Control:GetTheatre5ItemCfgById(itemId)

    if itemCfg then
        self.TxtTitle.text = itemCfg.Name
        self.TxtDes.text = self._Control:GetItemDesc(itemCfg)
        self.RImgTaskIcon:SetRawImage(itemCfg.IconRes)
    end
    
    self.ItemId = itemId
end

function XUiGridTheatre5ChooseTaskReward:OnBtnConfirmClick()
    if XTool.IsNumberValidEx(self.ItemId) then
        XMVCA.XTheatre5:RequestTheatre5MissionReward(self.ItemId, function() 
            XLuaUiManager.Close('UiTheatre5PopupChooseTaskReward')
        end)
    end
end

return XUiGridTheatre5ChooseTaskReward