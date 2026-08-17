--- 详情模式的商品样式节点（技能替换弹窗复用商品结构）
--- 与商店 GridStyle 结构一致，仅隐藏商品特有元素：购买按钮 + 升阶描述块
---@class XUiPBRShopNewDetailGridStyle: XUiPBRShopNewGridStyle
local XUiPBRShopNewGridStyle = require('XUi/XUiPBRGame/XUiPBRShopNew/GoodsPanel/XUiPBRShopNewGridStyle')
local XUiPBRShopNewDetailGridStyle = XClass(XUiPBRShopNewGridStyle, "XUiPBRShopNewDetailGridStyle")

function XUiPBRShopNewDetailGridStyle:InitComponents()
    XUiPBRShopNewGridStyle.InitComponents(self)

    -- 详情模式无购买行为，隐藏购买按钮（隐藏后不会触发 RootUi:OnSelectItemSignal）
    if self.BtnChoose then
        self.BtnChoose.gameObject:SetActiveEx(false)
    end
end

--- 详情模式不展示升阶提示：置空使 _RefreshBefore 隐藏的 ImgUpBg/TxtUpDesc 保持隐藏
function XUiPBRShopNewDetailGridStyle:_RefreshSkillShowAddition()
end

return XUiPBRShopNewDetailGridStyle
