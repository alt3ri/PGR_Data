--- 物品详情页
---@class XUiTheatre5BubbleItemDetail: XLuaUi
---@field private _Control XTheatre5Control
---@field PanelDetail UnityEngine.RectTransform
---@field Transform UnityEngine.RectTransform
local XUiTheatre5BubbleItemDetail = XLuaUiManager.Register(XLuaUi, 'UiTheatre5BubbleItemDetail')
local XUiGridTheatre5ItemTag = require('XUi/XUiTheatre5/XUiTheatre5BubbleItemDetail/XUiGridTheatre5ItemTag')
local XUiPanelTheatre5ItemDetailBtns = require('XUi/XUiTheatre5/XUiTheatre5BubbleItemDetail/XUiPanelTheatre5ItemDetailBtns')
local XUiPanelTheatre5ItemDetailAffix = require('XUi/XUiTheatre5/XUiTheatre5BubbleItemDetail/XUiPanelTheatre5ItemDetailAffix')

local Vector3ForCal = Vector3.zero

function XUiTheatre5BubbleItemDetail:OnAwake()
    self.UiTheatre5GridItemTag.gameObject:SetActiveEx(false)
    self.BtnClose.CallBack = handler(self, self.OnBtnCloseClickEvent)
end

---@param itemData XTheatre5Item
function XUiTheatre5BubbleItemDetail:OnStart(itemData, ownerType, posUi)
    if type(itemData) == 'table' then
        self.ItemData = itemData
        self.ItemId = itemData.ItemId
    else
        self.ItemId = itemData
    end
    self.OwnerType = ownerType

    local isOnlyShowDetails = ownerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.NormalDetails --只展示详情
    self.BtnClose.gameObject:SetActiveEx(isOnlyShowDetails) --关闭按钮都没用，那就展示详情用
    
    self:SetPosition(posUi)
    
    ---@type XTableTheatre5Item
    self.ItemConfig = XTool.IsNumberValid(self.ItemId) and self._Control:GetTheatre5ItemCfgById(self.ItemId) or nil
    
    ---@type XUiPanelTheatre5ItemDetailBtns
    self.PanelBtns = XUiPanelTheatre5ItemDetailBtns.New(self.PanelBtn, self)
    self.PanelBtns:Open()
    
    self.PanelRightAffix = XUiPanelTheatre5ItemDetailAffix.New(self.ListAffixRight, self)
    self.PanelLeftAffix = XUiPanelTheatre5ItemDetailAffix.New(self.ListAffixLeft, self)
    
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL, self.Close, self)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_ITEM_DETAIL, self.OnRefreshEvent, self)
end

function XUiTheatre5BubbleItemDetail:OnEnable()
    self:Refresh()
end


function XUiTheatre5BubbleItemDetail:OnDestroy()
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL, self.Close, self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_ITEM_DETAIL, self.OnRefreshEvent, self)
    self._Control:SetItemSelected(nil)
end
--region 界面刷新

function XUiTheatre5BubbleItemDetail:HideAllDiffShow()
    self.PanelSkill.gameObject:SetActiveEx(false)
    self.PanelGem.gameObject:SetActiveEx(false)
    self.PanelRightAffix:Close()
    self.PanelLeftAffix:Close()
    
    self.PanelBtns:HideAllBtns()
end

function XUiTheatre5BubbleItemDetail:OnRefreshEvent(itemData, ownerType, posUi)
    self:PlayAnimation('AnimEnable')
    
    if type(itemData) == 'table' then
        self.ItemData = itemData
        self.ItemId = itemData.ItemId
    else
        self.ItemId = itemData
    end
    self.OwnerType = ownerType

    self:SetPosition(posUi)

    ---@type XTableTheatre5Item
    self.ItemConfig = XTool.IsNumberValid(self.ItemId) and self._Control:GetTheatre5ItemCfgById(self.ItemId) or nil

    self:Refresh()
end

function XUiTheatre5BubbleItemDetail:Refresh()
    self:HideAllDiffShow()
    
    -- 刷新通用信息
    self:RefreshBaseShow()

    -- 按照物品类型刷新特定信息
    if self.ItemConfig.Type == XMVCA.XTheatre5.EnumConst.ItemType.Skill then
        self:RefreshSkillShow()
    elseif self.ItemConfig.Type == XMVCA.XTheatre5.EnumConst.ItemType.Equip then
        self:RefreshGemShow()
    end
    
    -- 根据物品所处位置刷新指定的交互按钮
    -- 只有商店才有交互按钮，其他地方显示没有交互按钮
    local curPlayStatus = self._Control:GetCurPlayStatus()
    
    if curPlayStatus == XMVCA.XTheatre5.EnumConst.PlayStatus.ChoiceSkill or curPlayStatus == XMVCA.XTheatre5.EnumConst.PlayStatus.Shopping then
        self.PanelBtns:RefreshBtns(self.ItemData, self.OwnerType)
    end
    
    -- 刷新词缀
    self:RefreshAffixShow()
end

function XUiTheatre5BubbleItemDetail:RefreshBaseShow()
    if self.ItemConfig then
        self.TxtTitle.text = self.ItemConfig.Name
        
        -- 道具的故事
        if not string.IsNilOrEmpty(self.ItemConfig.Info) then
            self.TxtStory.transform.parent.gameObject:SetActiveEx(true)
            self.TxtStory.text = XUiHelper.ReplaceTextNewLine(self.ItemConfig.Info)
        else
            self.TxtStory.transform.parent.gameObject:SetActiveEx(false)
        end
        
        self.TxtDes.text = self._Control:GetItemDesc(self.ItemConfig, self.ItemData and self.ItemData.IsStrengthen)
        
        if self.TxtDes02 then
            local addDesc = self._Control:GetItemAddDesc(self.ItemConfig, self.ItemData and self.ItemData.IsStrengthen)
            if addDesc then
                self.TxtDes02.gameObject:SetActiveEx(true)
                self.TxtDes02.text = addDesc
            else
                self.TxtDes02.gameObject:SetActiveEx(false)
            end
        end

        if self.TagGrids == nil then
            self.TagGrids = {}
        end

        if not XTool.IsTableEmpty(self.TagGrids) then
            for i, v in pairs(self.TagGrids) do
                v:Close()
            end
        end
        
        local count = #self.ItemConfig.Tags

        if XTool.IsNumberValid(count) then
            self.ListItemTag.gameObject:SetActiveEx(true)

            for i = 1, count do
                local grid = self.TagGrids[i]

                if not grid then
                    local go = CS.UnityEngine.GameObject.Instantiate(self.UiTheatre5GridItemTag, self.UiTheatre5GridItemTag.transform.parent)
                    grid = XUiGridTheatre5ItemTag.New(go, self)
                    self.TagGrids[i] = grid
                end

                grid:Open()
                grid:Refresh(self._Control:GetTheatre5ItemTagCfgById(self.ItemConfig.Tags[i]))
            end
        else
            self.ListItemTag.gameObject:SetActiveEx(false)
        end
    end
end

function XUiTheatre5BubbleItemDetail:RefreshSkillShow()
    if self.ItemConfig then
        ---@type XTableTheatre5ItemSkill
        local skillCfg = self._Control:GetTheatre5SkillCfgById(self.ItemId)

        if skillCfg then
            local hasCd = XTool.IsNumberValid(skillCfg.CoolDownSec)
            self.PanelSkill.gameObject:SetActiveEx(hasCd)

            if hasCd then
                self.TxtCdNum.text = skillCfg.CoolDownSec
            end
        end
    end
end

function XUiTheatre5BubbleItemDetail:RefreshGemShow()
    if self.ItemConfig then
        ---@type XTableTheatre5ItemRune
        local runeCfg = self._Control:GetTheatre5ItemRuneCfgById(self.ItemConfig.Id)

        if runeCfg and XTool.IsNumberValid(runeCfg.RuneAttrId) then
            local runeAttrCfg
            if self.ItemData then
                ---@type XTableTheatre5ItemRuneAttr
                runeAttrCfg = self._Control:GetRuneAttr(self.ItemData)
            else
                runeAttrCfg = self._Control:GetTheatre5ItemRuneAttrCfgById(runeCfg.RuneAttrId)    
            end

            if runeAttrCfg then
                self.PanelGem.gameObject:SetActiveEx(true)
                
                self._AttrList = XUiHelper.RefreshUiObjectList(self._AttrList, self.PanelGem.transform, self.GridAttribute, #runeAttrCfg.AttrTypes, function(index, grid)
                    if grid.TxtName then
                        ---@type XTableTheatre5AttrShow
                        local attrShowCfg = self._Control:GetTheatre5AttrShowCfgByType(runeAttrCfg.AttrTypes[index])

                        if attrShowCfg then
                            grid.TxtName.text = attrShowCfg.AttrName
                        end
                    end

                    if grid.TxtNum then
                        grid.TxtNum.text = runeAttrCfg.AttrValues[index] or 0
                    end
                end)
            end
        end
    end
end

function XUiTheatre5BubbleItemDetail:RefreshAffixShow()
    -- 根据锚点x来决定
    if self.PanelDetail.pivot.x <= 0.001 then
        self.CurPanelAffix = self.PanelRightAffix
    else
        self.CurPanelAffix = self.PanelLeftAffix
    end

    -- 判断当前选择的边是否越界，如果越界了则选择另一边
    if not XTool.IsTableEmpty(self.ItemConfig.Keywords) then
        if self.CurPanelAffix == self.PanelLeftAffix then
            -- 计算左下角
            Vector3ForCal.x = self.PanelDetail.pivot.x * self.PanelDetail.rect.width
            Vector3ForCal.y = self.PanelDetail.pivot.y * self.PanelDetail.rect.height
            local leftDownPos = self.PanelDetail.localPosition - Vector3ForCal

            -- 主要关注左边位置，加上关键字水平偏移和宽度
            leftDownPos.x = leftDownPos.x + self.CurPanelAffix.Transform.anchoredPosition.x - self.CurPanelAffix.Width

            if leftDownPos.x < - self.Transform.rect.size.x / 2 then
                self.CurPanelAffix = self.PanelRightAffix
                XLog.Warning('Theatre5 道具详情页关键字左边位置越界，更换为右边')
            end

        elseif self.CurPanelAffix == self.PanelRightAffix then
            -- 计算右上角
            Vector3ForCal.x = (1 - self.PanelDetail.pivot.x) * self.PanelDetail.rect.width
            Vector3ForCal.y = (1 - self.PanelDetail.pivot.y) * self.PanelDetail.rect.height
            local rightUpPos = self.PanelDetail.localPosition + Vector3ForCal

            -- 主要关注右边位置，加上关键字水平偏移和宽度
            rightUpPos.x = rightUpPos.x + self.CurPanelAffix.Transform.anchoredPosition.x + self.CurPanelAffix.Width

            if rightUpPos.x > self.Transform.rect.size.x / 2 then
                self.CurPanelAffix = self.PanelLeftAffix
                XLog.Warning('Theatre5 道具详情页关键字右边位置越界，更换为左边')
            end
        end
    end

    self.CurPanelAffix:Open()
    self.CurPanelAffix:Refresh(self.ItemConfig.Keywords)
    
end

--endregion

---@param posUi UnityEngine.Transform
function XUiTheatre5BubbleItemDetail:SetPosition(posUi)
    if not posUi then
        return
    end
    
    self.PanelDetail.transform.pivot = posUi.pivot
    self.PanelDetail.transform.position = posUi.position
    
    -- 边界修正
    -- 计算左下角
    Vector3ForCal.x = self.PanelDetail.pivot.x * self.PanelDetail.rect.width
    Vector3ForCal.y = self.PanelDetail.pivot.y * self.PanelDetail.rect.height
    local leftDownPos = self.PanelDetail.localPosition - Vector3ForCal

    -- 计算右上角
    Vector3ForCal.x = (1 - self.PanelDetail.pivot.x) * self.PanelDetail.rect.width
    Vector3ForCal.y = (1 - self.PanelDetail.pivot.y) * self.PanelDetail.rect.height
    local rightUpPos = self.PanelDetail.localPosition + Vector3ForCal
    
    Vector3ForCal.x = self.Transform.rect.size.x / 2
    Vector3ForCal.y = self.Transform.rect.size.y / 2

    local rightUpDiff = Vector3ForCal - rightUpPos
    local leftDownDiff = leftDownPos + Vector3ForCal

    if rightUpDiff.x < 0 or rightUpDiff.y < 0 then
        Vector3ForCal.x = rightUpDiff.x < 0 and rightUpDiff.x or 0
        Vector3ForCal.y = rightUpDiff.y < 0 and rightUpDiff.y or 0

        self.PanelDetail.localPosition = self.PanelDetail.localPosition + Vector3ForCal

        if XMain.IsEditorDebug then
            XLog.Warning('Theatre5 道具详情页触发右上位置越界修正')
        end
    end

    if leftDownDiff.x < 0 or leftDownDiff.y < 0 then
        Vector3ForCal.x = leftDownDiff.x < 0 and leftDownDiff.x or 0
        Vector3ForCal.y = leftDownDiff.y < 0 and leftDownDiff.y or 0

        self.PanelDetail.localPosition = self.PanelDetail.localPosition - Vector3ForCal

        if XMain.IsEditorDebug then
            XLog.Warning('Theatre5 道具详情页触发左下位置越界修正')
        end
    end
end

function XUiTheatre5BubbleItemDetail:OnBtnCloseClickEvent()
    self._Control:SetItemSelected(nil)
    self:Close()
end

return XUiTheatre5BubbleItemDetail