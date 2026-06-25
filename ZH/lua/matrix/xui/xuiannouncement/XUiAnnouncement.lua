local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiAnnouncement : XLuaUi
local XUiAnnouncement = XLuaUiManager.Register(XLuaUi, "UiAnnouncement")
local XUiGridAnnouncementBtn = require("XUi/XUiAnnouncement/XUiGridAnnouncementBtn")
local XHtmlHandler = require("XUi/XUiGameNotice/XHtmlHandler")

local CsVector2 = CS.UnityEngine.Vector2

local GameNoticeType = XDataCenter.NoticeManager.GameNoticeType

--- 页签下标
---@field GameNotice number 游戏公告下标
---@field ActivityNotice number 活动公告下标
local NoticeTag = {
    GameNotice     = 1,
    ActivityNotice = 2
}

--- 标题等级
---@field LevelOne number 一级标题
---@field LevelTwo number 二级标题
local TitleLevel = {
    LevelOne = "1",
    LevelTwo = "2"
}

local SortNoticeTag = { NoticeTag.GameNotice, NoticeTag.ActivityNotice }

---@desc 页签下标索引公告类型
---@field NoticeTag.ActivityNotice number 活动公告
---@field NoticeTag.GameNotice number 游戏公告
local TabTag2NoticeInfo = {
    [NoticeTag.ActivityNotice] = {
        Type = GameNoticeType.Activity,
        Name = XUiHelper.GetText("NoticeTypeTitle1")
    },
    [NoticeTag.GameNotice]     = {
        Type = GameNoticeType.Game,
        Name = XUiHelper.GetText("NoticeTypeTitle2")
    }
}
 --海外新增外链页签
    if XOverseaManager.IsOverSeaRegion() and not XOverseaManager.IsTWRegion() then
        SortNoticeTag = { NoticeTag.GameNotice, NoticeTag.ActivityNotice,NoticeTag.ActivityNotice + 1 }
        TabTag2NoticeInfo = {
            [NoticeTag.ActivityNotice] = {
                Type = GameNoticeType.Activity,
                Name = XUiHelper.GetText("NoticeTypeTitle1")
            },
            [NoticeTag.GameNotice] = {
                Type = GameNoticeType.Game,
                Name = XUiHelper.GetText("NoticeTypeTitle2")
            },
            [NoticeTag.ActivityNotice + 1] = {
            Type = GameNoticeType.Link,
            Name = XUiHelper.GetText("JPNoticeTypeTitle3")
            }
        }
    end
local HtmlContent = {}



function XUiAnnouncement:OnAwake()
    self:InitCb()
    self:InitUi()
end 

function XUiAnnouncement:OnStart(noticeType, defaultSelectId)
    local selectIndex = self:GetIndexByNoticeType(noticeType)
    selectIndex = self:GetValidIndex(selectIndex)
    if not selectIndex then
        self:Close()
        return XUiManager.TipText("NoInGameNotice")
    end
    self.DefaultSelectId = defaultSelectId
    self.PanelTopTabGroup:SelectIndex(selectIndex)
end 

function XUiAnnouncement:InitCb()
    self.BtnTanchuangCloseBig.CallBack = function() self:Close() end
end 

function XUiAnnouncement:InitUi()
    self.SpecialSoundMap = {}
    self.AutoCreateListeners = {}
    --动态列表
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTjTabEx)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridAnnouncementBtn)
    self.GridBtn.gameObject:SetActiveEx(false)
   
    --页签
    self.BtnTabs = {}
    for key, idx in ipairs(SortNoticeTag) do
        local ui = idx == 1 and self.BtnPayTab or XUiHelper.Instantiate(self.BtnPayTab, self.PanelTopTabGroup.transform)
        local btn = ui:GetComponent("XUiButton")
        btn:SetNameByGroup(0, TabTag2NoticeInfo[idx].Name)
        btn:SetNameByGroup(1, string.format("%02d", idx))
        btn.gameObject.name = string.format("Btn%s", key)
        btn.gameObject:SetActiveEx(true)
        local noticeType = TabTag2NoticeInfo[idx].Type
        btn:SetDisable(not XDataCenter.NoticeManager.CheckHaveNotice(noticeType))
        table.insert(self.BtnTabs, btn)
    end
    self.PanelTopTabGroup:Init(self.BtnTabs, function(index) self:OnSelectTag(index) end)
    
    self.WebViewPosCache = {}
    ---@type UnityEngine.UI.ScrollRect
    local panelWebView = self.ParagraphContent.parent.parent.transform:GetComponent(typeof(CS.UnityEngine.UI.ScrollRect))
    if not XTool.UObjIsNil(panelWebView) then
        panelWebView.onValueChanged:AddListener(handler(self, self.OnWebViewScroll))
    end
    self.PanelWebView = panelWebView
end 

function XUiAnnouncement:RefreshChildView(index)
    local noticeType = TabTag2NoticeInfo[index].Type
    if not XDataCenter.NoticeManager.CheckHaveNotice(noticeType) then
        XUiManager.TipText("NoInGameNotice")
        return
    end
    local noticeInfo = XDataCenter.NoticeManager.GetInGameNoticeMap(noticeType)
    self.NoticeInfo = noticeInfo
    local tmpIdx
    if self.DefaultSelectId then
        for idx, info in ipairs(noticeInfo) do
            if info.Id == self.DefaultSelectId then
                tmpIdx = idx
                self.DefaultSelectId = nil
            end
        end
    end
    self.NoticeIndex = tmpIdx and tmpIdx or XDataCenter.NoticeManager.GetShowNoticeIndex(noticeType)
    self.DynamicTable:SetDataSource(noticeInfo)
    self.DynamicTable:ReloadDataSync(self.NoticeIndex)
end

function XUiAnnouncement:RefreshWebView(url)
    self.WebUrl = url
    if HtmlContent[url] then
        self:ShowHtml(HtmlContent[url])
        return
    end
    
    self.ImgLoading.gameObject:SetActiveEx(true)
    XLuaUiManager.SetMask(true)
    local request = CS.XUriPrefixRequest.Get(url)
    CS.XTool.WaitCoroutine(request:SendWebRequest(), function()
        XLuaUiManager.SetMask(false)
        
        if request.isNetworkError or request.isHttpError then
            return
        end
        local content = request.downloadHandler.text

        if string.IsNilOrEmpty(content) then
            return
        end
        
        request:Dispose()
        
        local html = XHtmlHandler.Deserialize(content)
        if not html then
            XLog.Error("html deserialize error, html is empty! " .. url)
            return
        end
        HtmlContent[url] = html
        if not XTool.UObjIsNil(self.ImgLoading) then
            self.ImgLoading.gameObject:SetActiveEx(false)
        end
        self:ShowHtml(html)
    end)
end

function XUiAnnouncement:ShowHtml(html)
    self:ClearAllElement()
    for _, value in ipairs(html or {}) do
        if value.Type == XHtmlHandler.ParagraphType.Text then
            value.Obj = self:CreateTxt(value.Param, value.Data, value.SourceData, value.FontSize)
        elseif value.Type == XHtmlHandler.ParagraphType.Pic then
            value.Obj = self:CreateImg(value.Data)
        elseif value.Type == XHtmlHandler.ParagraphType.Table then
            value.Obj = self:CreateTable(value.Data)
        end
    end
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.ParagraphContent)
    local cachePos = self.WebViewPosCache[self.WebUrl]
    cachePos = cachePos and cachePos or CS.UnityEngine.Vector2.zero
    self.ParagraphContent.anchoredPosition = cachePos
    self.Html = html
end

function XUiAnnouncement:CreateTable(parameters)
    if not parameters or not parameters.headers or not parameters.rows == 0 then
        XLog.Error("XUiAnnouncement:CreateTable invalid parameters")
        return nil
    end
    -- 创建表格根节点
    local tableRoot = XUiHelper.Instantiate(self.Table, self.ParagraphContent)
    tableRoot.gameObject:SetActive(true)

    -- 获取表格组件
    local tableHeader = self.TableHeader
    local tableRow = self.TableRow
    local rootRectTransform = tableRoot:GetComponent(typeof(CS.UnityEngine.RectTransform))
    local tableHorizontalPadding = 20
    local paddingX = 20
    local paddingY = 40
    local borderThickness = 2
    -- 存储每列的最大宽度
    local maxWidths = {}
    -- 存储每行的最大高度（第1行是表头）
    local maxHeights = {}
    local totalWidth = 0
    local totalHeight = 0
    local widthAutoCount = 0
    -- 是否表格宽度拉伸填满整个容器
    local isTableExpend = false

    -- 初始化最大宽度数组
    for i = 1, #parameters.headers do
        maxWidths[i] = 0
    end

    -- 第一遍：创建所有行/单元格并记录最大宽度/高度
    local allRows = {}
    local allCells = {}

    -- 处理表头（行索引从1开始）
    local headerRow = XUiHelper.Instantiate(tableHeader, tableRoot)
    headerRow.gameObject:SetActive(true)
    table.insert(allRows, {
        rowObj = headerRow,
        cells = {},
        rowIndex = 1
    })

    for colIndex, headerData in ipairs(parameters.headers) do
        widthAutoCount = widthAutoCount + (headerData.width == "auto" and 1 or 0)
        local cell = self:CreateTableCell(headerData, headerRow.transform)
        table.insert(allRows[1].cells, cell)
        table.insert(allCells, {
            cell = cell,
            rowIndex = 1,
            colIndex = colIndex,
            cellData = headerData,
            widthIsAuto = headerData.width == "auto"
        })
    end

    -- 处理数据行
    for dataRowIndex, rowData in ipairs(parameters.rows) do
        local rowIndex = dataRowIndex + 1
        local rowObj = XUiHelper.Instantiate(tableRow, tableRoot)
        rowObj.gameObject:SetActive(true)
        table.insert(allRows, {
            rowObj = rowObj,
            cells = {},
            rowIndex = rowIndex
        })

        for colIndex, cellData in ipairs(rowData) do
            local cell = self:CreateTableCell(cellData, rowObj.transform)
            table.insert(allRows[rowIndex].cells, cell)
            table.insert(allCells, {
                cell = cell,
                rowIndex = rowIndex,
                colIndex = colIndex,
                cellData = cellData,
                widthIsAuto = cellData.width == "auto"
            })
        end
    end

    for _, cellInfo in ipairs(allCells) do
        local cell = cellInfo.cell
        local colIndex = cellInfo.colIndex
        local rowIndex = cellInfo.rowIndex

        local textComponent = cell.transform:GetComponent("XUiHrefText")
        local preferredWidth
        if cellInfo.widthIsAuto then
            preferredWidth = textComponent.preferredWidth
        else
            preferredWidth = tonumber(cellInfo.cellData.width)
        end
        local cellRect = cell:GetComponent(typeof(CS.UnityEngine.RectTransform))
        cellRect:SetUISizeDelta(preferredWidth, 0)
        local preferredHeight = textComponent.preferredHeight
        maxWidths[colIndex] = math.ceil(math.max(maxWidths[colIndex] or 0, preferredWidth + paddingX))
        maxHeights[rowIndex] = math.ceil(math.max(maxHeights[rowIndex] or 0, preferredHeight + paddingY))
    end

    for i = 1, #maxWidths do
        totalWidth = totalWidth + (maxWidths[i] or 0)
    end
    -- 表格宽度拉伸填满整个容器
    local parentWidth = self.PanelWebView:GetComponent(typeof(CS.UnityEngine.RectTransform)).rect.width - tableHorizontalPadding
    if isTableExpend then
        -- 获取父容器可用宽度
        local extraSpace = math.ceil((parentWidth - totalWidth) / widthAutoCount)
        -- 和父节点比较宽度后把多余的空间分配给auto
        for index = 1, #maxWidths do
            if allCells[index].widthIsAuto then
                maxWidths[index] = maxWidths[index] + extraSpace
            end
        end
        totalWidth = parentWidth
    else
        -- 限制最大宽度为父容器宽度
        if totalWidth > parentWidth then
            local scale = parentWidth / totalWidth
            for i = 1, #maxWidths do
                maxWidths[i] = math.floor(maxWidths[i] * scale)
            end
            totalWidth = parentWidth
        end
    end
    for i = 1, #allRows do
        totalHeight = totalHeight + (maxHeights[i] or 0)
    end

    -- 第二遍：手动设置每一行（含表头）位置 + 每个cell位置/大小
    local yOffset = 0
    for rowIndex, rowInfo in ipairs(allRows) do
        local rowObj = rowInfo.rowObj
        local rowRect = rowObj:GetComponent(typeof(CS.UnityEngine.RectTransform))
        local rowHeight = maxHeights[rowIndex] or rowRect.sizeDelta.y

        rowRect:SetAnchorMin(0, 1)
        rowRect:SetAnchorMax(0, 1)
        rowRect:SetPivot(0, 1)
        rowRect:SetAnchoredPosition(0, -yOffset)
        rowRect:SetUISizeDelta(totalWidth, rowHeight)

        local xOffset = 0
        for colIndex, cell in ipairs(rowInfo.cells) do
            local cellRect = cell:GetComponent(typeof(CS.UnityEngine.RectTransform))
            local cellWidth = maxWidths[colIndex] or cellRect.sizeDelta.x
            cellRect:SetAnchorMin(0, 1)
            cellRect:SetAnchorMax(0, 1)
            cellRect:SetPivot(0, 1)
            cellRect:SetAnchoredPosition(xOffset, 0)
            cellRect:SetUISizeDelta(cellWidth, rowHeight)

            xOffset = xOffset + cellWidth
        end

        yOffset = yOffset + rowHeight
    end

    rootRectTransform:SetUISizeDelta(totalWidth, totalHeight)
    self:DrawTableLines(tableRoot, maxWidths, maxHeights, totalWidth, totalHeight, borderThickness)
    return tableRoot
end

-- 添加单元格边框的辅助函数
function XUiAnnouncement:DrawTableLines(tableRoot, colWidths, rowHeights, totalWidth, totalHeight, thickness)
    if not tableRoot or not colWidths or not rowHeights then
        return
    end
    thickness = thickness or 1
    local rootRect = tableRoot:GetComponent(typeof(CS.UnityEngine.RectTransform))
    if rootRect then
        rootRect:SetAnchorMin(0, 1)
        rootRect:SetAnchorMax(0, 1)
        rootRect:SetPivot(0, 1)
    end

    -- 横线：rowCount + 1
    local y = 0
    local rowCount = #rowHeights
    for i = 0, rowCount do
        local rt = self:CreateTableLine(tableRoot, string.format("TableHLine_%d", i))
        rt:SetAnchoredPosition(0, -y)
        rt:SetUISizeDelta(totalWidth, thickness)
        if i < rowCount then
            y = y + (rowHeights[i + 1] or 0)
        end
    end

    -- 竖线：colCount + 1
    local x = 0
    local colCount = #colWidths
    for i = 0, colCount do
        local rt = self:CreateTableLine(tableRoot, string.format("TableVLine_%d", i))
        rt:SetAnchoredPosition(x, 0)
        rt:SetUISizeDelta(thickness, totalHeight)

        if i < colCount then
            x = x + (colWidths[i + 1] or 0)
        end
    end
end

function XUiAnnouncement:GetTextAnchor(textAlign)
    if textAlign == "center" then
        return CS.UnityEngine.TextAnchor.MiddleCenter
    elseif textAlign == "left" then
        return CS.UnityEngine.TextAnchor.MiddleLeft
    elseif textAlign == "right" then
        return CS.UnityEngine.TextAnchor.MiddleRight
    else
        return CS.UnityEngine.TextAnchor.MiddleCenter
    end
end

-- 创建表格单元格
function XUiAnnouncement:CreateTableCell(cellData, parent, fontSize)
    local content = cellData.innerContent
    local cell = XUiHelper.Instantiate(self.TableCell, parent)
    cell.gameObject:SetActive(true)

    -- 设置单元格内容
    local textComponent = cell.transform:GetComponent("XUiHrefText")

    textComponent.fontSize = fontSize or XHtmlHandler.FontSizeMap["large"]
    textComponent.lineSpacing = 1.0
    textComponent.alignment = self:GetTextAnchor(cellData.textAlign)
    textComponent.text = content

    return cell
end

function XUiAnnouncement:CreateTableLine(tableRoot, name)
    local go = XUiHelper.Instantiate(self.TableLine, tableRoot)
    go.gameObject:SetActive(true)
    go.name = name
    local img = go:GetComponent(typeof(CS.UnityEngine.UI.Image))
    if img then
        img.raycastTarget = false
    end
    local rt = go:GetComponent(typeof(CS.UnityEngine.RectTransform))
    rt:SetAnchorMin(0, 1)
    rt:SetAnchorMax(0, 1)
    rt:SetPivot(0, 1)
    return rt
end


function XUiAnnouncement:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiAnnouncement:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then
        return
    end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiPanelWorldChatMyMsgItem:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XLuaAudioManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiAnnouncement:ClearAllElement()
    if not self.Html then
        return
    end

    for _, value in pairs(self.Html or {}) do
        if value.Obj then
            CS.UnityEngine.Object.DestroyImmediate(value.Obj.gameObject)
        end
    end
end

function XUiAnnouncement:CreateTxt(param, data, sourceData, fontSize)
    local parent = self.ParagraphContent
    local textComponent, obj = self:GetTextAndObj(param, parent)
    
    textComponent.fontSize = fontSize or XHtmlHandler.FontSizeMap["large"]
    textComponent.lineSpacing = 1.0

    local width = parent.rect.width
    local layout = textComponent.cachedTextGeneratorForLayout
    local setting = textComponent:GetGenerationSettings(CsVector2(width, 0))
    
    local height = math.ceil(layout:GetPreferredHeight(CS.XTool.ReplaceNoBreakingSpace(sourceData), setting) / textComponent.pixelsPerUnit) + textComponent.fontSize * (textComponent.lineSpacing - 1)

    textComponent.rectTransform.sizeDelta = CsVector2(width, height)
    textComponent.text = data
    self:RegisterListener(textComponent, "onHrefClick", self.OnBtnHrefClick)

    local align
    local _, _, styleParam = string.find(param, "style=\"(.-)\"")
    
    if styleParam then
        _, _, align = string.find(styleParam, "text%-align:(.-);")
        if align then
            align = XHtmlHandler.RemoveBlank(align)
            textComponent.alignment = XHtmlHandler.AlignMap[align]
        end
    end

    if not align then
        _, _, align = string.find(param, "align=\"(.-)\"")
        if align then
            align = XHtmlHandler.RemoveBlank(align)
            textComponent.alignment = XHtmlHandler.AlignMap[align]
        end
    end
    
    return obj
end

function XUiAnnouncement:OnBtnHrefClick(str)
    local skipId = tonumber(str)
    if skipId then
        XFunctionManager.SkipInterface(skipId)
    else
        -- 判断特殊传参
        if string.find(str, 'urlId=.+') then
            local urlIdStr = string.match(str, 'urlId=(.+)')

            if string.IsNumeric(urlIdStr) then
                local urlId = tonumber(urlIdStr)
                
                XMVCA.XUrl:SkipByUrlId(urlId)
            end
        else
            CS.UnityEngine.Application.OpenURL(str)
        end
    end
end

function XUiAnnouncement:GetTextAndObj(param, parent)
    local _, _, titleLevel = string.find(param, "h(%d)")
    local textComponent, obj
    if titleLevel == TitleLevel.LevelOne then
        obj = XUiHelper.Instantiate(self.ImgMainTittle, parent)
        textComponent = obj.transform:Find("Txt01"):GetComponent("XUiHrefText")
        obj.gameObject:SetActiveEx(true)
        textComponent.gameObject:SetActiveEx(true)
    elseif titleLevel == TitleLevel.LevelTwo then
        obj = XUiHelper.Instantiate(self.ImgSecondTittle, parent)
        textComponent = obj.transform:Find("Txt03"):GetComponent("XUiHrefText")
        obj.gameObject:SetActiveEx(true)
        textComponent.gameObject:SetActiveEx(true)
    else
        textComponent = XUiHelper.Instantiate(self.Txt02, parent):GetComponent("XUiHrefText")
        textComponent.gameObject:SetActiveEx(true)
        obj = textComponent
    end
    
    return textComponent, obj
end

function XUiAnnouncement:CreateImg(tex)
    local parent = self.ParagraphContent
    local ui = XUiHelper.Instantiate(self.Img, parent)
    ui.gameObject:SetActiveEx(true)
    ui.texture = tex


    local width = parent.rect.width
    local height = math.floor(width * tex.height / tex.width)
    ui.rectTransform.sizeDelta =CsVector2(width, height)
    
    return ui
end

---@desc 获取有内容的公告下标
---@param index number 可不填
function XUiAnnouncement:GetValidIndex(index)
    local valid = XTool.IsNumberValid(index)
    if valid then
        local noticeType = TabTag2NoticeInfo[index].Type
        local hasNotice = XDataCenter.NoticeManager.CheckHaveNotice(noticeType)
        if hasNotice then
            return index
        end
    end
    for _, idx in ipairs(SortNoticeTag) do
        local noticeType = TabTag2NoticeInfo[idx].Type
        local hasNotice = XDataCenter.NoticeManager.CheckHaveNotice(noticeType)
        if hasNotice then
            return idx
        end
    end
    return nil
end

---@param grid XUiGridAnnouncementBtn
function XUiAnnouncement:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.NoticeInfo[index])
        self:CheckGridSelectionAtIndex(grid, index)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if XTool.IsNumberValid(self.NoticeIndex) then
            local selectGrid = self.DynamicTable:GetGridByIndex(self.NoticeIndex)
            if selectGrid then
                self:OnSelectGrid(selectGrid, self.NoticeIndex, true)
            end
        end
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:SetSelect(false)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnSelectGrid(grid, index)
    end
end

function XUiAnnouncement:GetIndexByNoticeType(noticeType)
    if not noticeType or noticeType < 0 then
        return GameNoticeType.Game
    end
    for idx, info in pairs(TabTag2NoticeInfo) do
        if info.Type == noticeType then
            return idx
        end
    end
    return GameNoticeType.Game
end

function XUiAnnouncement:CheckTabRedPoint()
    for _, idx in ipairs(SortNoticeTag) do
        local noticeType = TabTag2NoticeInfo[idx].Type
        local btn = self.BtnTabs[idx]
        btn:ShowReddot(XDataCenter.NoticeManager.CheckInGameNoticeRedPoint(noticeType))
    end
end

--region   ------------------UI事件 start-------------------

function XUiAnnouncement:OnSelectTag(index)

    if index == self.TabIndex  then
        return
    end
    self:CheckTabRedPoint()
    local noticeType = TabTag2NoticeInfo[index].Type
    if noticeType == GameNoticeType.Link then
        self:PlayAnimation("QieHuanUp")
        self.TabIndex = index
        self.LastGrid = nil
        self.PanelTjTabEx.gameObject:SetActiveEx(false)
        self.ParagraphContent.gameObject:SetActiveEx(false)
        self:OpenOneChildUi("UiActivityBaseLink")
        return
    end
    if not XDataCenter.NoticeManager.CheckHaveNotice(noticeType) then
        XUiManager.TipText("NoInGameNotice")
        return
    end
    if XOverseaManager.IsOverSeaRegion() and not XOverseaManager.IsTWRegion() then
        self.PanelTjTabEx.gameObject:SetActiveEx(true)
        self.ParagraphContent.gameObject:SetActiveEx(true)
        if XLuaUiManager.IsUiShow("UiActivityBaseLink") then
            self:CloseChildUi("UiActivityBaseLink")
        end
    end
    self:PlayAnimation("QieHuanUp")
    self.TabIndex = index
    self.LastGrid = nil
    self:RefreshChildView(self.TabIndex)
end

function XUiAnnouncement:OnSelectGrid(grid, index, force)
    if self._SelectIndex == index and not force then
        return
    end
    
    if self.LastGrid then
        self.LastGrid:SetSelect(false)
    end
    self.PanelWebView:StopMovement()
    self:CheckTabRedPoint()
    self:PlayAnimation("QiehuanLeft")
    self.LastGrid = grid
    self:RefreshWebView(grid.Info.Content[1].Url)

    if grid then
        grid:OnBtnClick(true)
    end
    
    self._SelectIndex = index
end

--- 因为动态列表复用节点，所以同一个节点在不同时刻代表的页签数据不同，需要在被复用时重新检查并刷新显示
function XUiAnnouncement:CheckGridSelectionAtIndex(grid, index)
    if self.LastGrid == grid then
        -- 如果当前刷出的格子和选中格子一样，那么要检查索引是否一致
        if index ~= self._SelectIndex then
            -- 如果索引不一致，那么该格子不应该表现为选中
            self.LastGrid:SetSelect(false)
        else
            self.LastGrid:SetSelect(true)
        end
    end
end

---@param vec2 UnityEngine.Vector2
function XUiAnnouncement:OnWebViewScroll(vec2)
    if string.IsNilOrEmpty(self.WebUrl) then
        return
    end
    self.WebViewPosCache[self.WebUrl] = self.ParagraphContent.anchoredPosition
end

--endregion------------------UI事件 finish------------------