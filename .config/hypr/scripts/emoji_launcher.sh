#!/usr/bin/env bash
# emoji_launcher.sh — emoji picker via rofi

emojis=(
"😀 grinning face"        "😃 big eyes"             "😄 smiling eyes"
"😁 beaming"              "😆 squinting"            "😅 sweat smile"
"🤣 rofl"                 "😂 tears of joy"         "🙂 slightly smiling"
"😉 winking"              "😊 smiling"              "😇 halo"
"🥰 hearts"               "😍 heart eyes"           "🤩 star struck"
"😘 kiss"                 "😋 savoring"             "😛 tongue"
"😜 winking tongue"       "😝 squinting tongue"     "🤑 money mouth"
"🤗 hugging"              "🤭 hand over mouth"      "🤫 shushing"
"🤔 thinking"             "😐 neutral"              "😑 expressionless"
"😶 no mouth"             "😏 smirking"             "😒 unamused"
"🙄 eye roll"             "😬 grimacing"            "😌 relieved"
"😔 pensive"              "😪 sleepy"               "😴 sleeping"
"😷 mask"                 "🤒 thermometer"          "🤕 bandage"
"🤢 nauseated"            "🤮 vomiting"             "🤧 sneezing"
"🥵 hot"                  "🥶 cold"                 "🥺 pleading"
"😱 screaming"            "😨 fearful"              "😰 anxious sweat"
"😢 crying"               "😭 loud crying"          "😤 triumph"
"😠 angry"                "😡 pouting"              "🤬 symbols"
"💀 skull"                "👻 ghost"                "👽 alien"
"🤖 robot"                "💩 poop"                 "🔥 fire"
"✨ sparkles"             "💥 collision"            "💫 dizzy"
"⭐ star"                 "🌟 glowing star"         "💎 gem"
"👍 thumbs up"            "👎 thumbs down"          "👏 clapping"
"🙌 raising hands"        "🤝 handshake"            "🙏 folded hands"
"💪 biceps"               "✍️ writing"              "👀 eyes"
"❤️ red heart"            "🧡 orange heart"         "💛 yellow heart"
"💚 green heart"          "💙 blue heart"           "💜 purple heart"
"🖤 black heart"          "🤍 white heart"          "💔 broken heart"
"🎉 party"                "🎊 confetti"             "🎁 gift"
"🏆 trophy"               "🥇 gold medal"           "🎮 video game"
"🎯 target"               "🎲 dice"                 "🎵 music note"
"🚀 rocket"               "🛸 flying saucer"        "🌈 rainbow"
"☀️ sun"                  "🌙 moon"                 "⚡ lightning"
"❄️ snowflake"            "🌊 wave"                 "🍕 pizza"
"🍔 burger"               "🍜 noodles"              "🍣 sushi"
"🍺 beer"                 "☕ coffee"               "🧋 bubble tea"
"🐱 cat"                  "🐶 dog"                  "🐼 panda"
"🦊 fox"                  "🐸 frog"                 "🐙 octopus"
"🌸 cherry blossom"       "🌻 sunflower"            "🍀 clover"
"✅ check mark"           "❌ cross mark"            "⚠️ warning"
"💡 bulb"                 "🔑 key"                  "🔒 lock"
"📌 pin"                  "📎 paperclip"            "📝 memo"
"📦 package"              "📂 folder"               "🗑️ trash"
)

selected=$(printf "%s\n" "${emojis[@]}" | rofi -dmenu -p "Emoji" -i)

if [ -n "$selected" ]; then
    emoji=$(echo "$selected" | awk '{print $1}')
    echo -n "$emoji" | wl-copy
    notify-send "Emoji copied" "$emoji"
fi
