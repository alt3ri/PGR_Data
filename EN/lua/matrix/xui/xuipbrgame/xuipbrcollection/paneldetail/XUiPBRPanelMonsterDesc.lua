---@class XUiPBRPanelMonsterDesc: XUiNode
---@field protected _Control XPBRGameControl
---@field Parent XUiPBRCollectionPanelDesc
local XUiPBRPanelMonsterDesc = XClass(XUiNode, "XUiPBRPanelMonsterDesc")

function XUiPBRPanelMonsterDesc:OnStart()
    self.TxtDetail.gameObject:SetActiveEx(false)
    ---@type XPool
    self.TxtDetailUiObjectPool = XPool.New(function()
        local txtDetail = XUiHelper.Instantiate(self.TxtDetail, self.TxtDetail.transform.parent)
        local uiObject = txtDetail.transform:GetComponent(typeof(CS.UiObject))

        return uiObject
    end, function(uiObject)
        uiObject.gameObject:SetActiveEx(false)
    end, false)
    
    self.BtnHelp:AddEventListener(handler(self, self.OnBtnHelpClick))
end

---@param params XPBRCollectionMonsterDetailParam
function XUiPBRPanelMonsterDesc:RefreshShow(params)
    self:_RecycleTxtDetails()

    if not XTool.IsTableEmpty(params.StatusDict) then
        for statusId, statusVal in pairs(params.StatusDict) do
            ---@type UiObject
            local uiObject = self.TxtDetailUiObjectPool:GetItemFromPool()
            uiObject.gameObject:SetActiveEx(true)

            table.insert(self._ShowedTxtDetailList, uiObject)

            local txtDetail = uiObject:GetObject('TxtDetail')
            local txtDetailNum = uiObject:GetObject('TxtDetailNum')

            if txtDetail then
                txtDetail.text = self._Control.CollectionControl:GetTableStatusNameById(statusId)
            end

            if txtDetailNum then
                txtDetailNum.text = self._Control.CharacterControl:GetValueDescByStatusIdAndValue(statusId, statusVal)
            end
        end
    end

    self.TxtMonsterDetail.text = params.BaseDesc
    self.TxtMonsterDetail.transform:SetAsLastSibling()
    
    self._UpgradeDesc = params.UpgradeDesc
end

function XUiPBRPanelMonsterDesc:_RecycleTxtDetails()
    -- 回收
    if self._ShowedTxtDetailList == nil then
        self._ShowedTxtDetailList = {}
    elseif not XTool.IsTableEmpty(self._ShowedTxtDetailList) then
        for i = #self._ShowedTxtDetailList, 1, -1 do
            self.TxtDetailUiObjectPool:ReturnItemToPool(self._ShowedTxtDetailList[i])
            self._ShowedTxtDetailList[i] = nil
        end
    end
end

function XUiPBRPanelMonsterDesc:OnBtnHelpClick()
    self._Control:DispatchEvent(XMVCA.XPBRGame.EventId.EVENT_PBR_INNER_OPEN_MONSTER_ARCHIVE_POPUPPANEL, self.DetailPos.transform.position, self.DetailPos.transform.pivot, self._UpgradeDesc)
end

return XUiPBRPanelMonsterDesc