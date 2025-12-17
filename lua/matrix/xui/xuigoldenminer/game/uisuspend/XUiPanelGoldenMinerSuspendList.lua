---buff列表
---@class XUiPanelGoldenMinerSuspendList: XUiNode
---@field protected _Control XGoldenMinerControl
local XUiPanelGoldenMinerSuspendList = XClass(XUiNode, 'XUiPanelGoldenMinerSuspendList')
local XUiGridGoldenMinerSuspendItem = require('XUi/XUiGoldenMiner/Game/UiSuspend/XUiGridGoldenMinerSuspendItem')

function XUiPanelGoldenMinerSuspendList:OnStart()
    ---@type XStack
    self._UpgradeIdStack = XStack.New()
end

function XUiPanelGoldenMinerSuspendList:RefreshHexShow(hexIds, ignoreUpgrade, onlyShowGotUpgrade)
    XUiHelper.RefreshCustomizedList(self.Transform, self.GridChange, hexIds and #hexIds or 0, function(index, go)
        ---@type XUiGridGoldenMinerSuspendItem
        local grid = XUiGridGoldenMinerSuspendItem.New(go, self)
        grid:Open()
        
        local hexId = hexIds[index]
        
        local mainIcon = self._Control:GetCfgHexIcon(hexId)
        local mainDesc = self._Control:GetCfgHexDesc(hexId)
        local baseUpgradeId = self._Control:GetCfgHexUpgradeId(hexId)
        -- 升级项显示
        -- 1. 读取海克斯对应的升级方案
        local upgradeIds = self._Control:GetCfgHexUpgradeInit(baseUpgradeId)
        local additionalDescList = nil
        if not ignoreUpgrade and not XTool.IsTableEmpty(upgradeIds) then
            self._UpgradeIdStack:Clear()
            
            -- 因为可能配置多层级，因此需要逐层查找，使用栈结构处理
            -- 2. 添加初始内容
            for i, id in ipairs(upgradeIds) do
                self._UpgradeIdStack:Push(id)
            end
            
            additionalDescList = {}
            
            local loopLimit = 999

            while loopLimit > 0 and self._UpgradeIdStack:Count() > 0 do
                loopLimit = loopLimit - 1
                
                local id = self._UpgradeIdStack:Pop()

                -- 3. 判断是否有升级，字符串插值
                local baseContent = self._Control:GetCfgHexUpgradeDesc(id)
                local isGot = self._Control:GetMainDb():CheckIsHexUpgrade(hexId, id)

                if not onlyShowGotUpgrade or isGot then
                    table.insert(additionalDescList, baseContent)
                    
                    -- 4. 查找它有没下一级
                    local nextUpgradeIds = self._Control:GetCfgHexUpgradeInit(id)

                    if not XTool.IsTableEmpty(nextUpgradeIds) then
                        for i, nextId in pairs(nextUpgradeIds) do
                            self._UpgradeIdStack:Push(nextId)
                        end
                    end
                end
            end
        end
        
        grid:RefreshShow(mainIcon, mainDesc, additionalDescList)
    end)
end

function XUiPanelGoldenMinerSuspendList:RefreshBuffShow(buffIds)
    XUiHelper.RefreshCustomizedList(self.Transform, self.GridChange, buffIds and #buffIds or 0, function(index, go)
        ---@type XUiGridGoldenMinerSuspendItem
        local grid = XUiGridGoldenMinerSuspendItem.New(go, self)
        grid:Open()
        grid:RefreshShow(self._Control:GetCfgBuffIcon(buffIds[index]), self._Control:GetCfgBuffDesc(buffIds[index]))
    end)
end

return XUiPanelGoldenMinerSuspendList