local XUiPopTeachVisual = require("XUi/XUiHelpCourse/XTeachPopType/Common/XUiPopTeachVisual")
local XUiPopTeachDot = require("XUi/XUiHelpCourse/XTeachPopType/Common/XUiPopTeachDot")

---@class XUiPopTeachContent : XUiNode
---@field Visual UnityEngine.RectTransform
---@field PanelDot UnityEngine.RectTransform
---@field GridDot UnityEngine.RectTransform
---@field BtnLast XUiComponent.XUiButton
---@field BtnNext XUiComponent.XUiButton
---@field TxtTeachTitle UnityEngine.UI.Text
---@field TxtTeach UnityEngine.UI.Text
---@field _Control XHelpCourseControl
local XUiPopTeachContent = XClass(XUiNode, "XUiPopTeachContent")

function XUiPopTeachContent:OnStart(clickCb)
    self._DotCount = 0
    self._CurrentIndex = 1

    ---@type XUiPopTeachVisual
    self._VisualUi = XUiPopTeachVisual.New(self.Visual, self)

    ---@type XUiPopTeachDot[]
    self._TeachDotList = {}

    self:_RegisterButtonClicks()
    
    self._ClickCb = clickCb
end

function XUiPopTeachContent:Refresh(config, index)
    ---@type XTableHelpCourse
    self.Config = config
    self._CurrentIndex = index or 1

    self:_Refresh()

    if self._ClickCb then
        self._ClickCb(self._CurrentIndex)
    end
end

function XUiPopTeachContent:OnBtnLastClick()
    self:_RefreshContent(self._CurrentIndex - 1, self._CurrentIndex)
    self:_RefreshButton()

    if self._ClickCb then
        self._ClickCb(self._CurrentIndex)
    end
end

function XUiPopTeachContent:OnBtnNextClick()
    self:_RefreshContent(self._CurrentIndex + 1, self._CurrentIndex)
    self:_RefreshButton()

    if self._ClickCb then
        self._ClickCb(self._CurrentIndex)
    end
end

function XUiPopTeachContent:TryMoveLastByHand()
    if self._CurrentIndex > 1 then
        self:OnBtnLastClick()
    end
end

function XUiPopTeachContent:TryMoveNextByHand()
    if self._CurrentIndex < self._DotCount then
        self:OnBtnNextClick()
    end
end

function XUiPopTeachContent:_Refresh()
    self:_RefreshDotList()
    self:_RefreshContent(self._CurrentIndex)
    self:_RefreshButton()
end

function XUiPopTeachContent:_RegisterButtonClicks()
    self.BtnLast.CallBack = Handler(self, self.OnBtnLastClick)
    self.BtnNext.CallBack = Handler(self, self.OnBtnNextClick)
end

function XUiPopTeachContent:_RefreshContent(index, oldIndex)
    self._CurrentIndex = index
    self.TxtTeachTitle.text = self.Config.Name
    
    local txtGroupId = self.Config.TextGroupIds[index]

    local hasValidTexts = false
    
    if XTool.IsNumberValid(txtGroupId) then
        local txtGroupCfg = self._Control:GetHelpCourseTextGroupCfgById(txtGroupId)

        if txtGroupCfg then
            hasValidTexts = true
            
            XUiHelper.RefreshCustomizedList(self.TxtTeach.transform.parent, self.TxtTeach, txtGroupCfg.Texts and #txtGroupCfg.Texts or 0, function(index, go)
                local text = go:GetComponent(typeof(CS.UnityEngine.UI.Text))

                if text then
                    local fixContent = XUiHelper.ReplaceTextNewLine(txtGroupCfg.Texts[index])

                    text.text = fixContent
                end
            end)
        end
    end

    if not hasValidTexts then
        -- 回收所有文本
        XUiHelper.RefreshCustomizedList(self.TxtTeach.transform.parent, self.TxtTeach, 0)
    end
    
    self._VisualUi:RefreshImg(self.Config.ImageAsset[index])
    self:_RefreshCurrentDot(oldIndex)
end

function XUiPopTeachContent:_RefreshDotList()
    local count = #self.Config.ImageAsset

    self._DotCount = count
    
    -- 数量只有1时不显示
    if count == 1 then
        count = 0
    end
    
    for i = 1, count do
        local dot = self._TeachDotList[i]

        if not dot then
            local dotGrid = XUiHelper.Instantiate(self.GridDot, self.PanelDot)

            dot = XUiPopTeachDot.New(dotGrid, self)
            self._TeachDotList[i] = dot
        end

        dot:Open()
        dot:Refresh(i == self._CurrentIndex)
    end
    for i = count + 1, table.nums(self._TeachDotList) do
        self._TeachDotList[i]:Close()
    end
    self.GridDot.gameObject:SetActiveEx(false)
end

function XUiPopTeachContent:_RefreshCurrentDot(oldIndex)
    local dot = self._TeachDotList[self._CurrentIndex]

    if dot then
        dot:Refresh(true)
    end
    if oldIndex then
        local oldDot = self._TeachDotList[oldIndex]

        if oldDot then
            oldDot:Refresh(false)
        end
    end
end

function XUiPopTeachContent:_RefreshButton()
    if self._DotCount == 1 then
        self.BtnNext.gameObject:SetActiveEx(false)
        self.BtnLast.gameObject:SetActiveEx(false)
    else
        self.BtnNext.gameObject:SetActiveEx(true)
        self.BtnLast.gameObject:SetActiveEx(true)
        if self._CurrentIndex < self._DotCount then
            self.BtnNext:SetDisable(false)
        else
            self.BtnNext:SetDisable(true, false)
        end
        if self._CurrentIndex > 1 then
            self.BtnLast:SetDisable(false)
        else
            self.BtnLast:SetDisable(true, false)
        end
    end
end

return XUiPopTeachContent
