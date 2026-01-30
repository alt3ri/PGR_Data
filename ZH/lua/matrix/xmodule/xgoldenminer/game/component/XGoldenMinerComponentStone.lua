---@class XGoldenMinerComponentStone:XEntity
---@field _OwnControl XGoldenMinerGameControl
---@field _ParentEntity XGoldenMinerEntityStone
local XGoldenMinerComponentStone = XClass(XEntity, "XGoldenMinerComponentStone")

--region Override
function XGoldenMinerComponentStone:OnInit()
    ---该抓取物基本分数
    self.Score = 0

    ---该抓取物当前分数（受Buff影响）
    self.CurScore = 0

    ---该抓取物基本重量
    self.Weight = 0

    ---该抓取物当前实际重量（受Buff影响）
    self.CurWeight = 0
    
    self.IgnoreWeight = false

    self.BornDelayTime = 0

    self.AutoDestroyTime = 0

    self.BeDestroyTime = 0

    self.HideTime = 0
    
    ---抓取物对象根节点
    ---@type UnityEngine.Transform
    self.Transform = false

    ---未被抓是携带物根节点
    ---@type UnityEngine.Transform
    self.CarryItemParent = false

    ---被抓取时携带物根节点
    ---@type UnityEngine.Transform
    self.GrabCarryItemParent = false

    ---@type UnityEngine.Collider2D
    self.Collider = false

    ---@type UnityEngine.Collider2D
    self.BoomCollider = false

    ---@type XGoInputHandler
    self.GoInputHandler = false
    
    self.CanInteraction = false
end

function XGoldenMinerComponentStone:OnRelease()
    self.Transform = nil
    self.CarryItemParent = nil
    self.GrabCarryItemParent = nil
    self.Collider = nil
    self.BoomCollider = nil
    if self.GoInputHandler then
        self.GoInputHandler:RemoveAllListeners()
        self.GoInputHandler = false
    end
    
    self.CanInteraction = false
end
--endregion

--region Setter

function XGoldenMinerComponentStone:SetTransform(transform)
    self.Transform = transform

    if self.Transform then
        self.LinkMask = XUiHelper.TryGetComponent(self.Transform, "Mask")
        self.CopyStyle = XUiHelper.TryGetComponent(self.Transform, "Copy")

        if self.LinkMask then
            self.LinkMask.gameObject:SetActiveEx(false)
        end

        if self.CopyStyle then
            self.CopyStyle.gameObject:SetActiveEx(false)
        end
    end
end

function XGoldenMinerComponentStone:SetBornDelayTime(bornDelayTime)
    self.BornDelayTime = bornDelayTime
end

function XGoldenMinerComponentStone:SetCurWeight(weight)
    self.CurWeight = weight
end

function XGoldenMinerComponentStone:SetIgnoreWeight(isIgnore)
    self.IgnoreWeight = isIgnore
end

function XGoldenMinerComponentStone:SetCopyStyleShow(isCopy)
    if self.CopyStyle then
        self.CopyStyle.gameObject:SetActiveEx(isCopy)
    end
end

function XGoldenMinerComponentStone:SetLinkStyleShow(isLink)
    if self.LinkMask then
        self.LinkMask.gameObject:SetActiveEx(isLink)
    end
end
--endregion

--region Getter

function XGoldenMinerComponentStone:GetIsIgnoreWeight()
    return self.IgnoreWeight
end

function XGoldenMinerComponentStone:GetCurWeight()
    return self.CurWeight
end

function XGoldenMinerComponentStone:CheckIsBornDelay()
    return XTool.IsNumberValidEx(self.BornDelayTime)
end

--endregion

return XGoldenMinerComponentStone