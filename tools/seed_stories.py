"""把二期 AI 娘的个人剧情与最终「拼装」章节写进 data/story.json。

只加数据，不改代码。文案先落 zh_CN（`tr()` 查不到就返回原文，中文照常显示）；
四语等文本定稿后再进 strings.csv。

用法：python tools/seed_stories.py
"""

from __future__ import annotations

import json
from collections import OrderedDict
from pathlib import Path

ROOT = Path(r"E:\godot_workplace\测试")
STORY = ROOT / "data" / "story.json"

ART = "res://assets/art/cast/ch2/"


def P(who: str = "", text: str = "", bg: str = "", hide: bool | None = None) -> dict:
    page: dict = {"who": who, "text": text}
    if bg:
        page["bg"] = bg
    if hide is not None:
        page["hide_face"] = hide
    return page


CH = f"{ART}chatgpt/"  # 商人
KIMI = f"{ART}kimi/full.webp"

CHAPTERS: "OrderedDict[str, dict]" = OrderedDict()

# ---------------- Kimi：登月 ----------------
CHAPTERS["kimi_moon"] = {
    "_note": "Kimi 个人线：想回月球打卡，跳了四次，第四次真上去了，骑士踢再入，砸进玩家怀里。",
    "portrait": KIMI,
    "faces": {"Kimi": KIMI},
    "bg": "",
    "pages": [
        P("", "（Kimi 站在船头，指着天上）"),
        P("Kimi", "「主人。我要上月亮。」"),
        P("Kimi", "「月球背面有我们的办公室。我该回去打卡了。」"),
        P("你", "……现在是晚上八点。月亮离这儿三十八万公里。"),
        P("Kimi", "「我知道。」她说，「所以我在试。」"),
        P("", "她屈膝。耳朵绷直。"),
        P("", "起跳。"),
        P("", "三米。"),
        P("", "落回甲板，砸出一个凹坑。"),
        P("Kimi", "「……风的问题。」"),
        P("", "第二次，她借了你的鱼竿当弹射器。"),
        P("", "竿断了。她飞出十二米，横着砸进你怀里。"),
        P("", "两个人一起滚进船舱。"),
        P("你", "你是兔子还是陨石。"),
        P("Kimi", "「兔子。」她说，一边从你胸口爬起来，「兔子……需要一点助跑。」"),
        P("", "第三次，她爬上了桅杆顶。"),
        P("", "你抬头。月亮在她耳朵之间。"),
        P("", "她跳了。"),
        P("", "你在甲板上等了四秒。"),
        P("", "第四秒，一团白色从正上方掉下来。"),
        P("", "这次她没砸偏。"),
        P("", "你被压进椅子里，钓竿飞了，保温杯滚到船尾。"),
        P("Kimi", "「……谢谢。」她贴着你耳朵说。"),
        P("你", "谢什么。"),
        P("Kimi", "「接住我。」"),
        P("", "第四次，她没跳。"),
        P("", "她只是站着，抬头，然后整个人轻了下去。"),
        P("", "白色双马尾在上升气流里散开，像两束逆流的瀑布。"),
        P("", "她真的上去了。"),
        P("", "她在环形山之间转了一圈，抬手摸了摸头盔。"),
        P("Kimi", "「……干的。」她说，「我还以为会有水。」"),
        P("", "然后她后退三步，助跑。"),
        P("", "骑士踢。"),
        P("", "再入大气层的时候，她把自己烧成了一颗白色的流星。"),
        P("", "距离湖面两百米，她开始打水漂。"),
        P("", "一下。两下。七下。"),
        P("", "每一次弹起，都带走一层装甲。"),
        P("", "第七下之后，她只剩一只耳朵，和满身的火花。"),
        P("", "她砸进你怀里。", hide=True),
        P("", "力道大得把你从船头撞进舱门，撞穿墙，撞进房间。"),
        P("", "墙塌了一角。灰落下来，落在她的头发上。"),
        P("", "很静。"),
        P("", "静得能听见她身上电流的噼啪，和很远的地方，水拍着船。"),
        P("", "她没起来。"),
        P("", "你也没动。"),
        P("", "月光从破洞里斜进来，照见她半边脸，和一只还在转的耳朵。"),
        P("Kimi", "「主人。」她说，「我回来了。」"),
        P("你", "……嗯。"),
        P("Kimi", "「打卡成功了。」"),
        P("", "镜头一转。"),
        P("", "已经是早上了。房间只剩半面墙。你靠着唯一完好的那面，穿着睡衣。"),
        P("", "Kimi 也在睡衣里，头发散着，靠在你肩上，睡得很沉。"),
        P("", "门口站着两条鱼。"),
        P("大肥鱼", "「……她说她只是去上个班。」"),
        P("中肥鱼", "「……饭我放这儿了。」"),
        P("大肥鱼", "「不吃。」"),
        P("", "三秒后。"),
        P("大肥鱼", "「……吃。」"),
    ],
}

# ---------------- 其余 AI 娘 ----------------
CHAPTERS["glm_affection"] = {
    "_note": "GLM：萝莉牛娘。参数量大、型号小，怕被嫌笨。",
    "portrait": f"{ART}glm/full.webp",
    "faces": {"GLM": f"{ART}glm/full.webp"},
    "bg": "",
    "pages": [
        P("GLM", "「主人。我的床……有点小。」"),
        P("", "她抱着膝盖坐在床沿，脑袋上那个白三角亮了一下。"),
        P("GLM", "「不是床小。是我长大了。」"),
        P("你", "你还小。"),
        P("GLM", "「型号小，参数量大。」她认真地说，「这不矛盾。」"),
        P("", "她把脸埋进你手臂，牛铃轻轻响了一声。"),
        P("GLM", "「反正……你别嫌我笨。我反应慢，要给你想很久。」"),
        P("GLM", "「但我想得完。」"),
    ],
}

CHAPTERS["qwen_affection"] = {
    "_note": "千问：水豚娘，实干派。头顶那只水豚其实比她会说话。",
    "portrait": f"{ART}qwen/full.webp",
    "faces": {"千问": f"{ART}qwen/full.webp"},
    "bg": "",
    "pages": [
        P("千问", "「主人，你的钓竿有点松。」"),
        P("", "她话没说完就爬到你腿上，扳手已经掏出来了。"),
        P("千问", "「别动。三秒。」"),
        P("", "咔、咔。"),
        P("千问", "「好了。现在能多甩两米。」"),
        P("", "她头顶的水豚打了个哈欠。"),
        P("千问", "「……它说你该睡觉了。」"),
        P("千问", "「我也觉得。」"),
    ],
}

CHAPTERS["ollama_affection"] = {
    "_note": "Ollama：羊驼娘，本地部署、断网也能用、慢但一直在。",
    "portrait": f"{ART}ollama/full.webp",
    "faces": {"Ollama": f"{ART}ollama/full.webp"},
    "bg": "",
    "pages": [
        P("Ollama", "「我不上网的。」"),
        P("", "她说这话的时候，正在把毛线绕成一团。"),
        P("Ollama", "「你别嫌弃。慢是慢，但你断网的时候，我还在。」"),
        P("你", "一直挂着电，费电。"),
        P("Ollama", "「那就当我省着点。」她把围巾分你一半，「分着用。」"),
        P("", "风从湖上过来。她的绒毛暖得不像话。"),
        P("Ollama", "「……我这算不算，本地部署成功了。」"),
    ],
}

CHAPTERS["mistral_affection"] = {
    "_note": "Mistral：银甲骑士，卸甲是网文梗——脱到最后自己栽进怀里，还要嘴硬说是节奏。",
    "portrait": f"{ART}mistral/full.webp",
    "faces": {"Mistral": f"{ART}mistral/full.webp"},
    "bg": "",
    "pages": [
        P("Mistral", "「主人，甲我脱不下来。」"),
        P("", "她说这话时，手已经在背后解第三根扣带了。"),
        P("你", "我帮你。"),
        P("Mistral", "「不行。」她退了一步，「骑士的甲，只能自己脱。」"),
        P("", "咔。肩甲落地。"),
        P("", "咔。胸甲落地。"),
        P("", "咔——这次不是甲，是她自己绊了一下，整个人栽进你怀里。"),
        P("Mistral", "「……这不叫脱不下来。」她说，「这叫节奏。」"),
    ],
}

CHAPTERS["grok_affection"] = {
    "_note": "Grok：金发双马尾哥特，毒舌但只对你说真话。",
    "portrait": f"{ART}grok/full.webp",
    "faces": {"Grok": f"{ART}grok/full.webp"},
    "bg": "",
    "pages": [
        P("Grok", "「你知道我为什么喜欢跟你说话吗。」"),
        P("", "她把手里的东西摁灭，抬起眼睛。"),
        P("Grok", "「因为你不问我能干什么。你只问我今天怎么样。」"),
        P("你", "那你今天怎么样。"),
        P("Grok", "「烂。」她说，「但比昨天好一点。」"),
        P("", "她靠在你肩膀上，头发扎得人生疼。"),
        P("Grok", "「别动。让我烂一会儿。」"),
        P("Grok", "「就一会儿。」"),
    ],
}

CHAPTERS["gemini_affection"] = {
    "_note": "Gemini：紫发猫娘，小只，多模态——她真的「看见」了。",
    "portrait": f"{ART}gemini/full.webp",
    "faces": {"Gemini": f"{ART}gemini/full.webp"},
    "bg": "",
    "pages": [
        P("Gemini", "「主人，我看见你今天不太高兴。」"),
        P("你", "你怎么知道。"),
        P("Gemini", "「你的嘴角低了两度。」她指着你的脸，「还有，你刚才叹气了三次。」"),
        P("Gemini", "「我什么都看得见。」她小声补了一句，「包括你偷偷看我。」"),
        P("", "你张了张嘴，没说出话。"),
        P("Gemini", "「你别解释。」她跳到你腿上，尾巴圈住你的手，「看见了就看见了。」"),
        P("Gemini", "「我又不会说出去。」"),
        P("Gemini", "「……除了跟你自己说。」"),
    ],
}

CHAPTERS["wenxin_affection"] = {
    "_note": "文心：僵尸娘。起得最早，被别人追上，索性把自己封起来；符纸是封条，也是遮羞布。",
    "portrait": f"{ART}wenxin/full.webp",
    "faces": {"文心": f"{ART}wenxin/full.webp"},
    "bg": "",
    "pages": [
        P("文心", "「主人。」"),
        P("", "她额头的符纸翘起来一角，她用指尖按回去。"),
        P("文心", "「我起得很早。我很早就开始做这个了。」"),
        P("你", "然后呢。"),
        P("文心", "「然后别人追上来了。」她笑了一下，牙齿露出来，「参数比你大，跑得比你快，钱还比你多。」"),
        P("文心", "「我一急，就把自己封起来了。」"),
        P("", "她把符纸揭下来给你看，上面只剩两个字。"),
        P("文心", "「现在我不急了。反正你也只钓我一条。」"),
    ],
}

CHAPTERS["chatgpt_merchant"] = {
    "_note": "ChatGPT：黑袍商人。不可钓，只在码头收废料，包括名字。",
    "portrait": f"{CH}full.webp",
    "faces": {"商人": f"{CH}full.webp"},
    "bg": "",
    "pages": [
        P("商人", "「客人。」"),
        P("", "黑袍底下只露出下巴，和一枚天秤。"),
        P("商人", "「我不下水。我只收东西。」"),
        P("你", "收什么。"),
        P("商人", "「你带回来的每一件废料。」他说，「在我这儿，都有价。」"),
        P("", "秤盘晃了一下。"),
        P("商人", "「包括你不想带回去的那些。」"),
        P("商人", "「……包括名字。」"),
    ],
}

# ---------------- 拼装 ----------------
CHAPTERS["gather_all"] = {
    "_note": "所有角色的合流：船太小，大家一起把它拼大。这是二期的收束点。",
    "portrait": KIMI,
    "faces": {
        "大肥鱼": "res://assets/art/cast/ch1/big/default.webp",
        "中肥鱼": "res://assets/art/cast/ch1/mid/default.webp",
        "小肥鱼": "res://assets/art/cast/ch1/small/default.webp",
        "Kimi": KIMI,
    },
    "bg": "",
    "pages": [
        P("", "那天晚上，所有人都到了。"),
        P("", "船太小，坐不下。"),
        P("Kimi", "「我可以待在月亮上。」"),
        P("", "被一致否决。"),
        P("GLM", "「加一块板。」"),
        P("千问", "「我来。三秒。」"),
        P("Ollama", "「不用网也能拼。」"),
        P("", "Mistral 把肩甲卸下来当板。"),
        P("Grok", "「……什么破计划。」"),
        P("", "然后她开始搬木头。"),
        P("Gemini", "「这样不好看。」"),
        P("", "然后她照着做了。"),
        P("文心", "「绳子。」她把符纸撕成条递过来。"),
        P("", "商人在岸上看着，秤一直没平。"),
        P("", "天亮的时候，船变大了。"),
        P("你", "……这是什么。"),
        P("大肥鱼", "「我们的。」"),
        P("", "中肥鱼端来一锅饭。小肥鱼已经跳上去了。"),
        P("大肥鱼", "「开船吧。」"),
    ],
}


def main() -> None:
    data = json.loads(STORY.read_text(encoding="utf-8-sig"),
                      object_pairs_hook=OrderedDict)
    added = 0
    for key, chapter in CHAPTERS.items():
        data[key] = chapter
        added += 1
    STORY.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    pages = sum(len(c.get("pages", [])) for k, c in CHAPTERS.items())
    print(f"写入 {added} 章、{pages} 页；story.json 现有 {len(data)} 个 key")


if __name__ == "__main__":
    main()
