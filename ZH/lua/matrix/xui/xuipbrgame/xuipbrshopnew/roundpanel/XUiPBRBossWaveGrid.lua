local XUiPBRBaseWaveGrid = require('XUi/XUiPBRGame/XUiPBRShopNew/RoundPanel/XUiPBRBaseWaveGrid')
---@class XUiPBRBossWaveGrid: XUiPBRBaseWaveGrid
---@field protected _Control XPBRGameControl
---@field Parent
local XUiPBRBossWaveGrid = XClass(XUiPBRBaseWaveGrid, "XUiPBRBossWaveGrid")

function XUiPBRBossWaveGrid:AOPBeforeRefresh(nextWaveIndex)
    self.ImgBossIcon.gameObject:SetActiveEx(true)
    self.ImgBossBg.gameObject:SetActiveEx(true)
end

function XUiPBRBossWaveGrid:AOPAfterRefresh(nextWaveIndex)
    local waveCfg = self._Control.InGameControl:GetTablePBRMonsterWaveCfgById(self.WaveId)

    if waveCfg then
        if waveCfg.IconType == XMVCA.XPBRGame.EnumConst.WaveShowType.Normal then
            XLog.Error('波次节点是普通节点，但使用了BossUI节点来显示')
        elseif waveCfg.IconType == XMVCA.XPBRGame.EnumConst.WaveShowType.Elite then
            XLog.Error('波次节点是精英节点，但使用了BossUI节点来显示')
        elseif waveCfg.IconType == XMVCA.XPBRGame.EnumConst.WaveShowType.Boss then
            self.ImgBossBg:SetImage(waveCfg.IconAssets)
        end
    end
end

return XUiPBRBossWaveGrid