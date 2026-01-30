local XBWModelControlData = require("XModule/XBigWorldResource/XData/XBWModelControlData")
local XBigWorldResourceConfigModel = require("XModule/XBigWorldResource/XBigWorldResourceConfigModel")

---@class XBigWorldResourceModel : XBigWorldResourceConfigModel
local XBigWorldResourceModel = XClass(XBigWorldResourceConfigModel, "XBigWorldResourceModel")
function XBigWorldResourceModel:OnInit()
    -- 初始化内部变量
    -- 这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    ---@type table<string, XBWModelControlData>
    self._ModelNodeControlDataMap = false

    self:_InitTableKey()
end

function XBigWorldResourceModel:ClearPrivate()
    -- 这里执行内部数据清理
end

function XBigWorldResourceModel:ResetAll()
    -- 这里执行重登数据清理
end

---@return XBWModelControlData
function XBigWorldResourceModel:GetModelControlNodeData(modelId)
    self:__InitModelNodeControlDatas()

    return self._ModelNodeControlDataMap[modelId]
end

function XBigWorldResourceModel:__InitModelNodeControlDatas()
    if not self._ModelNodeControlDataMap then
        local configs = self:GetDlcUiModelNodeControlConfigs()

        self._ModelNodeControlDataMap = {}
        if not XTool.IsTableEmpty(configs) then
            for _, config in pairs(configs) do
                local controlData = self._ModelNodeControlDataMap[config.ModelId]
                local animationName = config.AnimationName
                local hideNodes = config.HideNodes
                local showNodes = config.ShowNodes

                if not controlData then
                    controlData = XBWModelControlData.New(config.ModelId)
                    self._ModelNodeControlDataMap[config.ModelId] = controlData
                end

                if not XTool.IsTableEmpty(hideNodes) then
                    for _, nodeName in pairs(hideNodes) do
                        controlData:AddUnActiveNode(animationName, nodeName)
                    end
                end
                if not XTool.IsTableEmpty(showNodes) then
                    for _, nodeName in pairs(showNodes) do
                        controlData:AddActiveNode(animationName, nodeName)
                    end
                end
            end
        end
    end
end

return XBigWorldResourceModel
