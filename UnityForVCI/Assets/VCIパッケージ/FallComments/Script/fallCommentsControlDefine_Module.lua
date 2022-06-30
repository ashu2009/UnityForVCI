-- コメント落下共通部用モジュール
---共通使用部分定義
local _defineModule = {
    ---文字本体
    STR_CHAR = "FallChar (",
    ---文字本体のテキスト
    STR_CHAR_TXT = "FallCharText (",
    ---1コメント文字あたりの文字最大数
    STRING_MAX = 16,
    ---コメント削除までの時間
    DELETE_TIME = 13,
    ---握った場合のコメント削除までの時間強制変更
    DELETE_GRAB_TIME = 5,
    ---Use長押しの場合のコメント削除時間
    DELETE_USE_TIME = 2.5,
    -- コメント状態遷移
    NO_STATE = 0,
    FALL_STATE = 1,
    GRAB_STATE = 2,
    FIX_STATE = 3,
    DELETE_STATE = 4,
    WAIT_STATE = 5,
    -- ゼロ幅ジョイナー専用配列
    ZWJ_ARRAY = {},
    -- ハイサロゲート専用配列
    HIGH_SURROGATE_ARRAY = {},
    -- ローサロゲート専用配列
    LOW_SURROGATE_ARRAY = {},
    -- 異体字セレクタ専用配列
    VARIATION_SELECTOR_ARRAY = {},
    -- ランダム位置配列
    RAND_ARRAY = {}
}

---ここ自体初期化
local function initialize()
    -- ゼロ幅ジョイナー200D～200D
    for i = (16 ^ 3) * 2 + (16 ^ 2) * 0 + (16 ^ 1) * 0 + (16 ^ 0) * 13, (16 ^ 3) * 2 + (16 ^ 2) * 0 + (16 ^ 1) * 0 +
        (16 ^ 0) * 13 do
        _defineModule.ZWJ_ARRAY[string.char(i)] = true
    end
    -- ハイサロゲートペアD800～DBFF
    for i = (16 ^ 3) * 13 + (16 ^ 2) * 8 + (16 ^ 1) * 0 + (16 ^ 0) * 0, (16 ^ 3) * 13 + (16 ^ 2) * 11 + (16 ^ 1) * 15 +
        (16 ^ 0) * 15 do
        _defineModule.HIGH_SURROGATE_ARRAY[string.char(i)] = true
    end
    -- ローサロゲートペアDC00～DFFF
    for i = (16 ^ 3) * 13 + (16 ^ 2) * 12 + (16 ^ 1) * 0 + (16 ^ 0) * 0, (16 ^ 3) * 13 + (16 ^ 2) * 15 + (16 ^ 1) * 15 +
        (16 ^ 0) * 15 do
        _defineModule.LOW_SURROGATE_ARRAY[string.char(i)] = true
    end
    --------------符号位置--------------
    -- 異体字セレクタ180B～180D
    for i = (16 ^ 3) * 1 + (16 ^ 2) * 8 + (16 ^ 1) * 0 + (16 ^ 0) * 11, (16 ^ 3) * 1 + (16 ^ 2) * 8 + (16 ^ 1) * 0 +
        (16 ^ 0) * 13 do
        _defineModule.VARIATION_SELECTOR_ARRAY[string.char(i)] = true
    end
    -- 異体字セレクタFE00～FE0F
    for i = (16 ^ 3) * 15 + (16 ^ 2) * 14 + (16 ^ 1) * 0 + (16 ^ 0) * 0, (16 ^ 3) * 15 + (16 ^ 2) * 14 + (16 ^ 1) * 0 +
        (16 ^ 0) * 15 do
        _defineModule.VARIATION_SELECTOR_ARRAY[string.char(i)] = true
    end
    -- 異体字セレクタE0100～E01FE
    for i = (16 ^ 4) * 14 + (16 ^ 3) * 0 + (16 ^ 2) * 1 + (16 ^ 1) * 0 + (16 ^ 0) * 0, (16 ^ 4) * 14 + (16 ^ 3) * 0 +
        (16 ^ 2) * 1 + (16 ^ 1) * 15 + (16 ^ 0) * 14 do
        _defineModule.VARIATION_SELECTOR_ARRAY[string.char(i)] = true
    end
    --------------符号位置--------------
    local randMax = 7
    for i = 1, randMax do
        _defineModule.RAND_ARRAY[i] = i - (randMax) / 2 - 0.5
    end
end

initialize()

return _defineModule
