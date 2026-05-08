---@class XUiGridList
local XUiGridList = XClass(nil, "XUiGridList")

function XUiGridList:Ctor(template, parentGo, uiNode, parent, selectCallBack, allowMultSelect)
    self._Template = template
    self._ParentGo = parentGo
    self._Parent = parent
    self._GridGoList = {}
    self._GridList = {}
    self._UiNode = uiNode
    self._SelectCallBack = selectCallBack
    self._AllowMultSelect = allowMultSelect or false
    self._SelectIndexsMap = {}
end

function XUiGridList:Refresh(dataList)
    self.dataList = dataList
    for i = #dataList + 1, #self._GridList do
        self._GridList[i]:SetActiveEx(false)
        self._GridList[i]:Close()
    end
    for i, data in ipairs(dataList) do
        local go = self._GridGoList[i]
        if not go then
            go = XUiHelper.Instantiate(self._Template, self._ParentGo)
            self._GridList[i] = self._UiNode.New(go, self._Parent)
            self._GridList[i]:SetGridList(self, i)
            self._GridGoList[i] = go
        end
        go.gameObject:SetActiveEx(true)
        self._GridList[i]:Open()
    end
    for i, data in ipairs(dataList) do
        self._GridList[i]:Refresh(data)
    end
end

function XUiGridList:SetSelect(index, isSelect)
    self:_SetSelect(index, isSelect)
    if not self._AllowMultSelect and isSelect then
        for i, grid in ipairs(self._GridList) do
            if i ~= index then
                self:_SetSelect(i, false)
            end
        end
    end
end

function XUiGridList:_SetSelect(index, isSelect)
    if self._SelectIndexsMap[index] ~= isSelect then
        self._SelectIndexsMap[index] = isSelect
        self._GridList[index]:OnSelectChangde(isSelect)
        if self._SelectCallBack then
            self._SelectCallBack(index, isSelect, self:GetData(index))
        end
    end
end

function XUiGridList:SetSelects(indexMap)
    for index, isSelect in pairs(self._SelectIndexsMap) do
        self:_SetSelect(index, isSelect == indexMap[index])
    end
    -- 这里数据晚设置，属于偷个懒，省一个copy表。如果有问题就在一开始就copy一个表，然后把self._SelectIndexsMap = indexMap提到最前面
    self._SelectIndexsMap = indexMap
end

function XUiGridList:GetSelectIndex()
    for i, grid in ipairs(self._GridList) do
        if grid:IsSelect() then
            return i
        end
    end
    return nil
end

function XUiGridList:_OnClickGrid(index, data)
    if self._ClickCallback then
        self._ClickCallback(index, data)
    end
end

function XUiGridList:GetData(index)
    return self.dataList[index]
end

return XUiGridList
