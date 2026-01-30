local XUiModelDataBase = require("XUi/XUiCommon/XUiModelDisplay/XData/XUiModelDataBase")

---@class XUiModelAnimationNodeVisibility : XUiModelDataBase
local XUiModelAnimationNodeVisibility = XClass(XUiModelDataBase, "XUiModelAnimationNodeVisibility")

function XUiModelAnimationNodeVisibility:Ctor()
    self.ActiveNodesMap = {}
    self.UnActiveNodesMap = {}
end

function XUiModelAnimationNodeVisibility:IsEmpty()
    return XTool.IsTableEmpty(self.ActiveNodesMap) and XTool.IsTableEmpty(self.UnActiveNodesMap)
end

---@param helper XUiModelDisplayHelper
function XUiModelAnimationNodeVisibility:IsCompatibility(componentType, helper)
    return helper.CheckComponentDerived(XEnumConst.UiModel.ComponentType.AnimationNodeVisibility, componentType)
end

function XUiModelAnimationNodeVisibility:Clear()
    self.ActiveNodesMap = {}
    self.UnActiveNodesMap = {}
end

function XUiModelAnimationNodeVisibility:AddActiveNode(animationName, nodeName)
    if not self.ActiveNodesMap[animationName] then
        self.ActiveNodesMap[animationName] = {}
    end

    table.insert(self.ActiveNodesMap[animationName], nodeName)
end

function XUiModelAnimationNodeVisibility:AddUnActiveNode(animationName, nodeName)
    if not self.UnActiveNodesMap[animationName] then
        self.UnActiveNodesMap[animationName] = {}
    end

    table.insert(self.UnActiveNodesMap[animationName], nodeName)
end

function XUiModelAnimationNodeVisibility:InjectComponent(component)
    if not component then
        return
    end

    if not XTool.IsTableEmpty(self.ActiveNodesMap) then
        for animationName, nodeNames in pairs(self.ActiveNodesMap) do
            component:AddControlActiveNodes(animationName, nodeNames)
        end
    end

    if not XTool.IsTableEmpty(self.UnActiveNodesMap) then
        for animationName, nodeNames in pairs(self.UnActiveNodesMap) do
            component:AddControlUnActiveNodes(animationName, nodeNames)
        end
    end
end

return XUiModelAnimationNodeVisibility
