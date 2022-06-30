-- 共通部用モジュール
---@class ContorolTaskCls @制御データ用クラス(タスク積むときに使用)
---@field who any @誰が
---@field toWhom any @誰に
---@field what any @何を
---@field toWhat any @何に
---@field controlNum number @制御内容
---共通使用部分定義
local _defineModule = {
    ---同期用アイテム
    SYNC_ITEM = vci.assets.GetTransform("SYNC_ITEM"),
    -- 同期等操作用メッセージ
    MESSAGEKEY_SYNC_ALL = "MESSAGEKEY_SYNC_ALL",
    MESSAGEKEY_CONTROL_ADD = "MESSAGEKEY_CONTROL_ADD",
    -- 操作内容
    CONTROLKEY_TASK_SKIP = 0,
    CONTROLKEY_TASK_SKIP_END = 1,
    CONTROLKEY_ENTER_ROOM = 2,
    CONTROLKEY_TIME_SYNC = 3,
    CONTROLKEY_STATE_SYNC = 4,
    CONTROLKEY_GRAB = 5,
    CONTROLKEY_USE = 6,
    CONTROLKEY_DELETE = 7
}

---操作情報追加共通メッセージ
---@param who number @誰が
---@param toWhom number @誰に
---@param what number @何を
---@param toWhat number @何に
---@param controlNum number @どのような操作
function _defineModule.controlAddMessage(who, toWhom, what, toWhat, controlNum)
    vci.message.EmitWithId(_defineModule.MESSAGEKEY_CONTROL_ADD, {
        who = who,
        toWhom = toWhom,
        what = what,
        toWhat = toWhat,
        controlNum = controlNum
    }, vci.assets.GetInstanceId())
end

return _defineModule
