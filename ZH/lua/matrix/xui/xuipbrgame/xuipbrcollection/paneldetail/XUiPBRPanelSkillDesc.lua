---@class XUiPBRPanelSkillDesc: XUiNode
---@field protected _Control
---@field Parent
local XUiPBRPanelSkillDesc = XClass(XUiNode, "XUiPBRPanelSkillDesc")


function XUiPBRPanelSkillDesc:OnStart()
    self.TxtSkillLevel1.gameObject:SetActiveEx(false)
    ---@type XPool
    self.TxtLevelPool = XPool.New(function()
        local txtLevel = XUiHelper.Instantiate(self.TxtSkillLevel1, self.TxtSkillLevel1.transform.parent)
        local txt = txtLevel.transform:GetComponent(typeof(CS.UnityEngine.UI.Text))
        
        return txt
    end, function(txtLevel)
        txtLevel.gameObject:SetActiveEx(false)
    end, false)

    if self.TxtSkillBasic:GetType() == typeof(CS.XUiComponent.XUiRichTextCustomRender) then
        self.TxtSkillBasic.requestImage = self._Control:GetRichTextImageRequestHandler()
    end
end


---@param params XPBRCollectionSkillDetailParam
function XUiPBRPanelSkillDesc:RefreshShow(params)
    self.TxtSkillBasic.text = params.BaseDesc
    
    self:RecycleAllLevelTxt()

    if not XTool.IsTableEmpty(params.LevelStrList) then
        for _, levelStr in ipairs(params.LevelStrList) do
            local txtLevel = self.TxtLevelPool:GetItemFromPool()
            txtLevel.gameObject:SetActiveEx(true)
            txtLevel.text = XUiHelper.ReplaceTextNewLine(levelStr)
            table.insert(self._ShowedLevelTxtList, txtLevel)
        end
    end
end

function XUiPBRPanelSkillDesc:RecycleAllLevelTxt()
    if self._ShowedLevelTxtList == nil then
        self._ShowedLevelTxtList = {}
    elseif not XTool.IsTableEmpty(self._ShowedLevelTxtList) then
        for i = #self._ShowedLevelTxtList, 1, -1 do
            self.TxtLevelPool:ReturnItemToPool(self._ShowedLevelTxtList[i])
            self._ShowedLevelTxtList[i] = nil
        end    
    end
end

return XUiPBRPanelSkillDesc