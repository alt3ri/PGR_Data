---
--- Created by Jaylin.
--- DateTime: 2023-03-06-006 11:27
---
local IsWindowsEditor = XMain.IsWindowsEditor
---@class XModel
---@field _ConfigUtil XConfigUtil
---@field _SaveUtil XSaveUtil
XModel = XClass(nil, "XModel")

local XSaveUtil = require('MVCA/XSaveUtil')

function XModel:Ctor(id, mainModel)
    self._Id = id
    self._ConfigUtil = XConfigUtil.New(id)
    self._SaveUtil = XSaveUtil.New(id)
    ---@type table<string, XModel>
    self._SubModels = {} --子Model
    self._MainModel = mainModel
    self:OnInit()
end

---初始化函数,提供给子类重写
function XModel:OnInit()

end

function XModel:ClearAllPrivate()
    for _, subModel in pairs(self._SubModels) do
        subModel:ClearAllPrivate()
    end
    self:ClearPrivate()
end

---清理内部数据, 在Control生命周期结束的时候会触发
function XModel:ClearPrivate()
    XLog.Error("请子类重写Model.ClearPrivate方法")
end

function XModel:ClearPrivateConfig()
    for _, subModel in pairs(self._SubModels) do
        subModel:ClearPrivateConfig()
    end
    if self._ConfigUtil then
        self._ConfigUtil:ClearPrivate()
    end
end


--region 子Model

---@param cls any
---@return XModel
function XModel:AddSubModel(cls)
    if not self._SubModels[cls] then
        local model = cls.New(self._Id, self)
        self._SubModels[cls] = model
        return model
    else
        XLog.Error("请勿重复添加子model!")
    end
end

---@param model XModel
function XModel:RemoveSubModel(model)
    if self._SubModels[model.__class] then
        self._SubModels[model.__class] = nil
        model:CallResetAll()
        model:Release()
    else
        XLog.Error("移除不存在的子model: " .. model.__cname)
    end
end

---获取一个子model
---@return XModel
function XModel:GetSubModel(cls)
    return self._SubModels[cls]
end
--endregion

function XModel:CallResetAll()
    for _, subModel in pairs(self._SubModels) do
        subModel:CallResetAll()
    end
    self:ResetAll()
    self._SaveUtil:ReleaseData()
end

---重登清理, 回到登录界面的时候需重置数据
function XModel:ResetAll()

end

function XModel:Release()
    if self._SubModels then
        for _, subModel in pairs(self._SubModels) do
            subModel:Release()
        end
        self._SubModels = nil
    end    

    if self._ConfigUtil then
        self._ConfigUtil:Release()
        self._ConfigUtil = nil
    end

    if self._SaveUtil then
        self._SaveUtil:ReleaseData()
        self._SaveUtil = nil
    end
  
    if IsWindowsEditor then
        WeakRefCollector.AddRef(WeakRefCollector.Type.Model, self)
    end
end
