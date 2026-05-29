---
--- Created by Jaylin.
--- DateTime: 2023-03-06-006 11:27
---
---@class XModel : XModelBase
---@field _ConfigUtil XConfigUtil
---@field _SaveUtil XSaveUtil
XModel = XClass(XModelBase, "XModel")

function XModel:InitInternal(id, mainModel)
    self._ConfigUtil = XConfigUtil.New(id)
    XModelBase.InitInternal(self)
end

function XModel:ClearPrivateConfig()
    if self._SubModels then
        for _, subModel in pairs(self._SubModels) do
            subModel:ClearPrivateConfig()
        end
    end
    if self._ConfigUtil then
        self._ConfigUtil:ClearPrivate()
    end
end

function XModel:Release()
    XModelBase.Release(self)
    if self._ConfigUtil then
        self._ConfigUtil:Release()
        self._ConfigUtil = nil
    end
end
