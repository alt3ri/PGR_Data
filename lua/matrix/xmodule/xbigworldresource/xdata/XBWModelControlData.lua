---@class XBWModelControlData
local XBWModelControlData = XClass(nil, "XBWModelControlData")

function XBWModelControlData:Ctor(modelId)
    self._ModelId = modelId
    self._ActiveNodesMap = {}
    self._UnActiveNodesMap = {}
end

function XBWModelControlData:GetModelId()
    return self._ModelId
end

function XBWModelControlData:AddActiveNode(animationName, nodeName)
    if not self._ActiveNodesMap[animationName] then
        self._ActiveNodesMap[animationName] = {}
    end

    table.insert(self._ActiveNodesMap[animationName], nodeName)
end

function XBWModelControlData:AddUnActiveNode(animationName, nodeName)
    if not self._UnActiveNodesMap[animationName] then
        self._UnActiveNodesMap[animationName] = {}
    end

    table.insert(self._UnActiveNodesMap[animationName], nodeName)
end

function XBWModelControlData:GetActiveNodes(animationName)
    return self._ActiveNodesMap[animationName]
end

function XBWModelControlData:GetActiveNodeMap()
    return self._ActiveNodesMap
end

function XBWModelControlData:GetUnActiveNodesMap()
    return self._UnActiveNodesMap
end

return XBWModelControlData
