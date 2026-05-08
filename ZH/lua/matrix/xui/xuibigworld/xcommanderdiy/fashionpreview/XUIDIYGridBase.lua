---@class XUIDIYGridBase : XUiNode
---@desc 继承此类需要有self.BtnClick,否则自己复写InitComponents
local XUIDIYGridBase = XClass(XUiNode, "XUIDIYGridBase")

-------------------------------------override------------------------
function XUIDIYGridBase:OnSetData(data)

end

function XUIDIYGridBase:OnSelectChangde(isSelect)

end

function XUIDIYGridBase:OnClickGrid(eventData, data)

end

function XUIDIYGridBase:InitComponents()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClickClick, true)
end

-------------------------------------外部调用 ------------------------
function XUIDIYGridBase:Refresh(data)
    self:OnSetData(self:GetData())
end

function XUIDIYGridBase:GetData()
    return self._GridList:GetData(self._Index)
end

function XUIDIYGridBase:SetSelect(isSelect)
    self._GridList:SetSelect(self._Index, isSelect)
end

-------------------------------------内部调用 ------------------------
function XUIDIYGridBase:OnBtnClickClick(eventData)
    if self._ClickHandler then
        self._ClickHandler(self._Param.Index, self._Data)
    end
    self:OnClickGrid(eventData, self._Data)
end

function XUIDIYGridBase:SetGridList(gridList, index)
    self._GridList = gridList
    self._Index = index
end

function XUIDIYGridBase:OnEnableUi()
    self:InitComponents()
end

function XUIDIYGridBase:OnDisableUi()

end


return XUIDIYGridBase
