---@class XUiPBRCommonDropdownPanel: XUiNode
---@field protected _Control XPBRGameControl
---@field Parent
---@field BtnCurQualityStateCtrl XUiComponent.XUiStateControl
local XUiPBRCommonDropdownPanel = XClass(XUiNode, "XUiPBRCommonDropdownPanel")

function XUiPBRCommonDropdownPanel:OnStart()
    self.IsFold = true
    self.BtnCloseDropdown.gameObject:SetActiveEx(false)
    self.BtnCloseDropdown:AddEventListener(function() 
        self:_CloseSelectList()
    end)
    self.BtnDropdown.CallBack = function() self:OnBtnDropdownClick() end
    
    self.OnItemClickHanler = function(index) 
        self:SelectIndex(index)

        self:_CloseSelectList()
    end
end

---@param options string[]
---@param onValueChanged function
---@param defaultIndex number
function XUiPBRCommonDropdownPanel:InitDropdownList(options, onValueChanged, defaultIndex)
    self.Options = options
    self.DefaultIndex = defaultIndex
    
    self.OnValueChangedFunc = onValueChanged
    
    self:SelectIndex(defaultIndex, true)
end

function XUiPBRCommonDropdownPanel:OnBtnDropdownClick()
    if self.IsFold then
        self:_OpenSelectList()
    else
        self:_CloseSelectList()
    end
    
end

function XUiPBRCommonDropdownPanel:_CloseSelectList()
    self.ModuleList.gameObject:SetActiveEx(false)
    self.BtnCloseDropdown.gameObject:SetActiveEx(false)

    self.BtnCurQualityStateCtrl:ChangeState('FoldState')
    self.IsFold = true
end

function XUiPBRCommonDropdownPanel:_OpenSelectList()
    if XTool.IsTableEmpty(self.Options) then
        return
    end
    
    self.ModuleList.gameObject:SetActiveEx(true)
    self.BtnCloseDropdown.gameObject:SetActiveEx(true)
    self.BtnCurQualityStateCtrl:ChangeState('UnFoldState')
    self.IsFold = false
    
    if self._OptionItemDict == nil then
        self._OptionItemDict = {}
    else
        for _, item in pairs(self._OptionItemDict) do
            item:Close()
        end
    end

    local optionItemCls = self:GetOptionItemCls()

    XUiHelper.RefreshCustomizedList(self.ModuleItem.transform.parent, self.ModuleItem, self.Options and #self.Options or 0, function(index, go)
        local item = self._OptionItemDict[go]

        if not item then
            item = optionItemCls.New(go, self, self.OnItemClickHanler)
            self._OptionItemDict[go] = item
        end

        item:Open()
        item:RefreshShow(index, self.Options[index], index == self.CurIndex)
    end)
end

function XUiPBRCommonDropdownPanel:SelectIndex(index, noCallBack)
    if not XTool.IsNumberValidEx(index) or index == self.CurIndex then
        return
    end

    self.CurIndex = index
    self.TxtName.text = self.Options[self.CurIndex]

    if not noCallBack and self.OnValueChangedFunc then
        self.OnValueChangedFunc(self.CurIndex)
    end
end

--- 获取选项类，子类可重写
function XUiPBRCommonDropdownPanel:GetOptionItemCls()
    return require('XUi/XUiPBRGame/CommonUiTemplate/DropdownPanel/XUiPBRCommonDropdownItem')
end

return XUiPBRCommonDropdownPanel