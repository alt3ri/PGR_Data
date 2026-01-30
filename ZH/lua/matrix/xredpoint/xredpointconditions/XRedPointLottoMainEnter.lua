---@class XRedPointLottoMainEnter
local XRedPointLottoMainEnter = {}

function XRedPointLottoMainEnter.Check()
    return XDataCenter.LottoManager:CheckLottoMainEnterRedPoint()
end

return XRedPointLottoMainEnter