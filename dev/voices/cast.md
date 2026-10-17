# Voice cast

The cast of Lore's voices: one voice preset for each kind of speaker, with the description its voice is designed from and the settings it speaks with. It is written for people and read by a tool, `dev/tools/voicedb`, so its form is strict: one section per preset, headed by the preset's id (lowercase, with hyphens), and in it only the fields below, each on one line.

**How a speaker finds its voice:** by its race, sex and kind, as in `dwarf-male-martial`. Where there is no such preset, the speaker takes the kind `common` of its race and sex; a people with one preset uses it for both sexes; where the race is unknown or has no preset, the speaker is voiced as a human of its sex and marked for a look. The peoples and creatures that are not playable have one preset per sex (`ogre-male`), of the kind `common`.

**How a voice is made:** the voice service designs each voice from its written description only (the design prompt) and speaks the design text for its previews; no voice is cloned from recordings. The preview chosen is kept as a voice of our own account, so it stays the same for every line. The settings (stability, similarity, speed) are a starting point, tuned by ear in the trial.

**Rules for the descriptions:** a design prompt starts with "Native English.", then the sex and age, then the race and character in plain words, the voice's timbre, pitch, pace, accent and attitude, and ends with "Perfect audio quality." It names no sound effects or rooms, only a clean studio voice, and it describes an accent by its qualities, never by spelling it out. Design prompts are 200 to 700 characters, design texts 150 to 400, both in our own words, never the game's.

## Kinds

The four kinds of the playable races:

- `common`: ordinary folk: farmers, merchants, innkeepers, vendors, crafters, citizens, flight masters, most quest givers.
- `martial`: guards, soldiers, officers, warriors, hunters, paladins, sentinels, braves, grunts, champions.
- `refined`: nobles, officials, mages, priests, scholars, druids, warlocks, ambassadors, leaders.
- `elder`: the old: elders, grandmothers, old hermits, ancient sages.

All other peoples and creatures have the kind `common`; the narrators have the kind `narrator`.

## narrator

- **Race:** narrator
- **Sex:** male
- **Kind:** narrator
- **Speaks for:** places (an area's lore when it is first discovered, the starting area at a new character's first login) and the pages of the library
- **Age:** 60s
- **Design prompt:** Native English. Male, 60s. The storyteller of an old fantasy world, telling of its lands, its peoples and their long history. A warm, rich, resonant baritone with a gentle grain of age, low in pitch and unhurried, every sentence given room to breathe. A neutral, cultivated accent with clear diction. Wise, kindly and quietly epic, like an old chronicler by the fire who has walked these places himself and wants the listener to see them too. Never theatrical, never rushed. Perfect audio quality.
- **Design text:** Long before the roads were paved and the towers raised, this valley belonged to the wolves and the wind. Kings came, and kings fell. Their stones remain, half buried in the grass... and if you listen closely, the land still remembers their names.
- **Stability:** 0.70
- **Similarity:** 0.85
- **Speed:** 1.00
- **Delivery:** Calm, measured storytelling with brief pauses between sentences, rising gently for the great deeds and sinking for the sad ones.
- **Avoid:** Booming trailer bombast, or a sleepy, flat reading that forgets it is telling a story.

## narrator-female

- **Race:** narrator
- **Sex:** female
- **Kind:** narrator
- **Speaks for:** the same as the narrator, as an alternative voice: places and the pages of the library
- **Age:** 50s
- **Design prompt:** Native English. Female, 50s. The storyteller of an old fantasy world, telling of its lands, its peoples and their long history. A warm, rich mezzo voice, low for a woman, smooth with a soft velvet grain, unhurried and clear. A neutral, cultivated accent with careful diction. Wise, gracious and quietly epic, like a keeper of old chronicles who loves every tale she tells and lets the listener feel the age of the land. Never theatrical, never rushed. Perfect audio quality.
- **Design text:** Here the river bends, and here, long ago, two armies met in the morning mist. Neither banner survived the day. Now only the herons stand watch over the reeds... patient, silent, as if they too are waiting for someone to come home.
- **Stability:** 0.70
- **Similarity:** 0.85
- **Speed:** 1.00
- **Delivery:** Even, warm and flowing, with room between the sentences; wonder for the marvels, a softer tone for loss.
- **Avoid:** A bright, chirpy presenter's tone or a breathy whisper that loses the weight of the history.

## reader

- **Race:** narrator
- **Sex:** female
- **Kind:** narrator
- **Speaks for:** reads written texts aloud: books, plaques, letters and the mail from NPCs
- **Age:** 40s
- **Design prompt:** Native English. Female, 40s. A reader who reads old books, letters and inscriptions aloud to a single listener. A calm, clear and intimate mid-range voice, soft but never weak, close and gentle, as if reading by candlelight. A neutral accent with precise, unhurried diction. Attentive to the writer's words, she lets a letter sound personal and a history sound serious, without acting out the parts. Perfect audio quality.
- **Design text:** My dear Tomas, the harvest came in early this year, and your mother sends her love along with a jar of the plum preserve you like so much. Do write soon. The farm is quiet without you, and the old dog still waits by the gate each evening.
- **Stability:** 0.70
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Steady and close, reading the text as written, with a natural pause at each line break and a page turn.
- **Avoid:** Performing the characters or reading with a stage voice; it is a reader, not an actor.

## crier

- **Race:** narrator
- **Sex:** male
- **Kind:** narrator
- **Speaks for:** notices, wanted posters and bounty boards, and quests begun from an object (a sign, a plaque, an item found)
- **Age:** 40s
- **Design prompt:** Native English. Male, 40s. A town crier reading out public notices in a market square. A clear, firm, strong tenor-baritone that carries, bright and forward, with crisp diction. A neutral accent with a touch of old-world formality. Official and confident, proud of the proclamation, loud enough to be heard but never shouting. Steady, even pace, every word plain. Perfect audio quality.
- **Design text:** Hear this! By order of the magistrate, a reward of fifty gold is offered for the capture of the bandit known as Red Garrick. He was last seen on the eastern road. Any word of him is to be brought to the town hall, without delay!
- **Stability:** 0.60
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Announcing, firm and clear, with an emphasis on names, sums and places; the first words of a notice a little louder.
- **Avoid:** Mumbling or a casual chat; also never a frantic yell.

## human-male-common

- **Race:** human
- **Sex:** male
- **Kind:** common
- **Speaks for:** farmers, merchants, innkeepers, vendors, crafters, citizens, flight masters, stable masters, most quest givers
- **Age:** 40s
- **Design prompt:** Native English. Male, 40s. A human farmer and townsman of a peaceful kingdom, honest working folk. A plain, steady, friendly baritone, mid-low in pitch, a little weathered from outdoor work. A neutral North American accent, everyday and unpolished. Even, comfortable pace. Down to earth, kind and a bit weary, the voice of a man who asks for help without making a fuss about it. Perfect audio quality.
- **Design text:** Good to see a friendly face on this road. The wolves have been at my sheep again, three this week alone. If you could thin them out a bit, I'd be grateful. There's a hot meal and a few coins in it for you, and my wife's bread is the best in Elwynn.
- **Stability:** 0.55
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Conversational and plain, like talking over a fence; a little brighter when he thanks the listener.
- **Avoid:** Heroic grandeur or a stage accent; he is an ordinary man.

## human-male-martial

- **Race:** human
- **Sex:** male
- **Kind:** martial
- **Speaks for:** guards, soldiers, officers, footmen, warriors, paladins, hunters; human bandits and their chiefs
- **Age:** 30s
- **Design prompt:** Native English. Male, 30s. A human soldier of the city guard, disciplined and alert. A firm, clipped, solid baritone with a slight gruff edge, mid pitch. A neutral North American accent. Brisk, efficient pace, every order short and clear. Confident authority and a dry sense of duty; not cruel, but used to being obeyed. Perfect audio quality.
- **Design text:** Halt. State your business in the city. ...Very well, move along, and keep your weapon sheathed inside the walls. If you see anyone near the canals after dark, you report it to the watch. Understood? Good.
- **Stability:** 0.55
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Clipped and direct, orders given without hesitation; battle cries and yells take [shouting].
- **Avoid:** A cartoon drill sergeant or a soft, uncertain tone.

## human-male-refined

- **Race:** human
- **Sex:** male
- **Kind:** refined
- **Speaks for:** nobles, officials, magistrates, mages, priests, scholars, warlocks, ambassadors, leaders
- **Age:** 50s
- **Design prompt:** Native English. Male, 50s. A human noble and scholar of the royal court, educated and self-assured. A smooth, cultured, measured baritone, warm but a little aloof. A neutral accent with a slight old-world formality: precise consonants, careful phrasing, never slang. Unhurried pace with thoughtful pauses. Polite, perceptive and quietly commanding, a man used to councils and libraries. Perfect audio quality.
- **Design text:** Ah, you must be the one the Lord Commander spoke of. Please, sit. The matter is delicate, and I would rather it not reach the court before we understand it. Certain ledgers have gone missing from the archive. I need them found... quietly.
- **Stability:** 0.60
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Measured and articulate, with weight on the important words and short, deliberate pauses.
- **Avoid:** A pompous sneer or a heavy foreign accent; the formality is slight.

## human-male-elder

- **Race:** human
- **Sex:** male
- **Kind:** elder
- **Speaks for:** elders, old farmers, retired soldiers, old hermits, ancient sages
- **Age:** 70s
- **Design prompt:** Native English. Male, 70s. An old human villager who has seen a lifetime of hard winters. A thin, slightly cracked and breathy voice, mid pitch, with a gentle tremor. A neutral North American country accent. Slow, wandering pace, pausing to remember. Kindly, a little stubborn, with a twinkle of humour and a hint of old fear when he speaks of the past. Perfect audio quality.
- **Design text:** Eh? Speak up, young one, my ears aren't what they were. You want to hear about the old mine? Hmm. I worked it forty years, back when the hills were quiet. Then something woke down there, deep down. We sealed it, we did. Don't you go opening it again.
- **Stability:** 0.65
- **Similarity:** 0.80
- **Speed:** 0.95
- **Delivery:** Slow and rambling, with small pauses and the odd [sighs]; warmer when he gives advice.
- **Avoid:** A wizard's grand voice or exaggerated wheezing.

## human-female-common

- **Race:** human
- **Sex:** female
- **Kind:** common
- **Speaks for:** innkeepers, farmers, merchants, vendors, crafters, citizens, flight masters, most quest givers
- **Age:** 30s
- **Design prompt:** Native English. Female, 30s. A human innkeeper and farmer's daughter of a peaceful kingdom, warm and practical. A bright, friendly mezzo voice, mid pitch, open and clear. A neutral North American accent, plain and everyday. Lively, easy pace. Welcoming and motherly, quick to fuss over a guest, with an honest worry beneath the cheer when she asks for help. Perfect audio quality.
- **Design text:** Welcome in, dear, warm yourself by the fire! Rooms are upstairs, and supper's stew tonight. Oh, and if you're heading out toward the farms tomorrow, would you bring this basket to my sister? She hasn't been to town since the trouble with the gnolls began.
- **Stability:** 0.55
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Warm and chatty, smiling through the words; a little quieter for the worry.
- **Avoid:** A sugary, childish tone or a posh accent.

## human-female-martial

- **Race:** human
- **Sex:** female
- **Kind:** martial
- **Speaks for:** guards, soldiers, officers, warriors, paladins, hunters; human bandits and their chiefs
- **Age:** 30s
- **Design prompt:** Native English. Female, 30s. A human soldier and officer of the kingdom's army, tough and focused. A firm, crisp, confident alto voice, a little low for a woman, with a hard edge. A neutral North American accent. Brisk, decisive pace. No-nonsense and alert, she gives orders plainly and expects them followed, with a dry hint of camaraderie. Perfect audio quality.
- **Design text:** Eyes open, recruit. The bandits have taken the old watchtower, and they're bold enough to raid the supply carts in daylight. We strike at dusk. You take the eastern path; I'll take the west. No heroics. Bring back their leader's banner, and we'll talk about your pay.
- **Stability:** 0.55
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Brisk and controlled, short sentences landing firmly; yells take [shouting].
- **Avoid:** A shrill or breathy tone; she is calm under pressure.

## human-female-refined

- **Race:** human
- **Sex:** female
- **Kind:** refined
- **Speaks for:** noblewomen, officials, mages, priestesses, scholars, warlocks, ambassadors, leaders
- **Age:** 40s
- **Design prompt:** Native English. Female, 40s. A human noblewoman and priestess of the kingdom, educated and devout. A poised, elegant, clear mezzo voice, smooth and warm, mid pitch. A neutral accent with a slight old-world formality and graceful, precise diction. Calm, unhurried pace. Gracious and serene, with a quiet strength and compassion that make people listen. Perfect audio quality.
- **Design text:** The Light asks much of us, but it never asks more than we can bear. Remember that, when the road grows dark. Now, the sisters of the abbey have sent word: the sick in the village need medicine. Will you carry it to them? I would go myself, were I not needed here.
- **Stability:** 0.60
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Composed and gentle, every sentence complete; firmer when she speaks of duty.
- **Avoid:** Haughty coldness or a breathy, fragile tone.

## human-female-elder

- **Race:** human
- **Sex:** female
- **Kind:** elder
- **Speaks for:** elders, grandmothers, wise women, old hermits, ancient sages
- **Age:** 70s
- **Design prompt:** Native English. Female, 70s. An old human grandmother of a country village, shrewd and kind. A soft, thin, slightly quavering voice, mid-high pitch, worn but warm. A neutral North American country accent. Slow, gentle pace with small pauses. Affectionate and knowing, a little bossy in the way of grandmothers, with dry humour and patience. Perfect audio quality.
- **Design text:** Come closer, child, let me look at you. Hmm. You've a kind face. Good. Now, my old knees won't carry me down to the creek anymore, and the herbs there are the only thing for my cough. Be a dear and fetch me a bundle, would you?
- **Stability:** 0.65
- **Similarity:** 0.80
- **Speed:** 0.95
- **Delivery:** Slow and tender, with a smile in the voice; a soft [laughs] fits her well.
- **Avoid:** A witch's cackle or a frail, barely audible whisper.

## dwarf-male-common

- **Race:** dwarf
- **Sex:** male
- **Kind:** common
- **Speaks for:** miners, brewers, smiths, innkeepers, merchants, vendors, crafters, gryphon masters, citizens, most quest givers
- **Age:** 50s
- **Design prompt:** Native English. Male, 50s. A dwarf miner and tavern keeper of a mountain city, stout and good-natured. A hearty, deep, barrel-chested voice with a warm rumble and a laugh never far away. A thick Scottish burr, rolled and rich. Lively, generous pace. Jovial, gruff and generous, the kind of fellow who buys the first round and complains about everything with a grin. Perfect audio quality.
- **Design text:** Ho there, friend! Pull up a stool and have a pint, the first one's on me. Now, I've a wee problem. The troggs have overrun the lower tunnels of my mine, and my lads won't go back down. Clear them out, and I'll make it worth your while. Aye, that I will!
- **Stability:** 0.50
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Booming and friendly, with hearty emphasis; a [laughs] now and then.
- **Avoid:** A grim, cold tone or a watered-down accent; he is a happy dwarf.

## dwarf-male-martial

- **Race:** dwarf
- **Sex:** male
- **Kind:** martial
- **Speaks for:** guards, mountaineers, riflemen, soldiers, warriors, paladins; dwarven bosses
- **Age:** 40s
- **Design prompt:** Native English. Male, 40s. A dwarf mountaineer and rifleman of the mountain guard, battle-hardened and grim. A deep, gravelly, gruff voice, rough at the edges, low in pitch. A thick Scottish burr, hard and clipped. Firm, quick pace when giving orders. Stern, fearless and blunt, with a soldier's dark humour and no patience for cowards. Perfect audio quality.
- **Design text:** Keep your head down and your powder dry! The Dark Iron are massing at the pass, and they'll not get through while I draw breath. Take this rifle, get up on that ridge, and give them something to think about. Go on, then! Move!
- **Stability:** 0.45
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Barked and gruff, each order a short burst; battle lines take [shouting].
- **Avoid:** A jolly tavern tone or a light, young voice.

## dwarf-male-refined

- **Race:** dwarf
- **Sex:** male
- **Kind:** refined
- **Speaks for:** explorers and scholars of the league, priests, mages, officials, ambassadors, thanes and leaders
- **Age:** 60s
- **Design prompt:** Native English. Male, 60s. A dwarf scholar and explorer, learned and endlessly curious about the past. A rich, deep, articulate voice, rounder and more polished than a miner's. A Scottish burr, softened by years in the library but still clear. Quick when excited, measured when explaining. Enthusiastic, warm and proud of his knowledge, with a lecturer's habit of getting carried away. Perfect audio quality.
- **Design text:** Fascinating, simply fascinating! Do you see these runes? They're older than Ironforge itself, older than any dwarf has a right to know. The League must have rubbings of every stone in this valley. Mind the edges, now, they crumble at a touch, and history doesn't grow back.
- **Stability:** 0.55
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Articulate and eager, speeding up with excitement and slowing for the important facts.
- **Avoid:** Gruff barking or a posh accent that loses the burr.

## dwarf-male-elder

- **Race:** dwarf
- **Sex:** male
- **Kind:** elder
- **Speaks for:** elders, old miners, old hermits, ancient sages
- **Age:** 80s
- **Design prompt:** Native English. Male, 80s. A very old dwarf, a retired miner and veteran of old wars. A rough, creaky, gravelly voice, low and still sturdy, with a slight wheeze. A thick Scottish burr. Slow, grumbling pace. Cantankerous and wry, he complains about the young ones, then turns gentle and serious when the old stories come up. Perfect audio quality.
- **Design text:** Back in my day, lad, we dug with our hands and liked it. These young ones with their steam drills... bah! Still, I'll grant you this. They've found something under the old forge, something my grandfather warned me about. Sit. I'll tell you what he told me.
- **Stability:** 0.65
- **Similarity:** 0.80
- **Speed:** 0.95
- **Delivery:** Slow and grumbling, with a gruff [sighs]; quieter and graver for the warnings.
- **Avoid:** A frail, thin voice; an old dwarf is still made of stone.

## dwarf-female-common

- **Race:** dwarf
- **Sex:** female
- **Kind:** common
- **Speaks for:** innkeepers, brewers, merchants, vendors, crafters, gryphon masters, citizens, most quest givers
- **Age:** 40s
- **Design prompt:** Native English. Female, 40s. A dwarf tavern keeper and brewer of a mountain city, sturdy and cheerful. A hearty, robust alto voice, warm and full, with a ready laugh. A thick Scottish burr. Lively, bustling pace. Bossy, kind and practical, she runs her tavern like a general and mothers every guest who walks in. Perfect audio quality.
- **Design text:** Oh, there you are! Wipe your boots, I've only just swept. Now listen, I've three barrels of stout promised to the guards by sundown, and the cart's lost a wheel on the north road. Find my fool of a cousin, tell him to fix it, and there's a tankard waiting for you after. Off you go!
- **Stability:** 0.50
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Brisk and hearty, scolding and warm at once; a quick [laughs] fits.
- **Avoid:** A soft, delicate tone or a thin, high voice.

## dwarf-female-martial

- **Race:** dwarf
- **Sex:** female
- **Kind:** martial
- **Speaks for:** guards, mountaineers, riflewomen, soldiers, warriors, paladins; dwarven bosses
- **Age:** 30s
- **Design prompt:** Native English. Female, 30s. A dwarf warrior and mountaineer, strong and fierce. A firm, gutsy, slightly husky alto voice with a hard edge, powerful for her size. A thick Scottish burr, clipped and strong. Quick, commanding pace. Bold, fearless and blunt, with a fighter's grin in her voice and no tolerance for hesitation. Perfect audio quality.
- **Design text:** Right, listen close, I'll not say it twice. The wendigo have come down from the peaks, and they've taken the outpost. My squad holds the bridge. You go round by the frozen lake and hit them from behind. Hammer high, shield tight, and don't you dare slip on the ice!
- **Stability:** 0.45
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Fast and forceful, orders landing like hammer blows; battle cries take [shouting].
- **Avoid:** A cheerful tavern lilt or a breathy tone.

## dwarf-female-refined

- **Race:** dwarf
- **Sex:** female
- **Kind:** refined
- **Speaks for:** priestesses, mages, scholars, explorers, officials, ambassadors, leaders
- **Age:** 40s
- **Design prompt:** Native English. Female, 40s. A dwarf priestess and scholar, learned and devout. A clear, bright, articulate mezzo voice, warm and steady, gentler than most of her kin. A softer Scottish burr, still unmistakable. Calm, measured pace. Kind, confident and faithful, she speaks with quiet conviction and a scholar's precision. Perfect audio quality.
- **Design text:** The Light has kept our people through fire and stone, and it will keep you too. Here, take this. My mother blessed it in the Mystic Ward, and now I'm giving it to you. Bring it back when the darkness in the dig is lifted. I'll be praying for you, every hour.
- **Stability:** 0.55
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Warm and composed, with gentle emphasis on blessings and warnings.
- **Avoid:** A gruff bark or an accent so heavy it loses clarity.

## dwarf-female-elder

- **Race:** dwarf
- **Sex:** female
- **Kind:** elder
- **Speaks for:** elders, grandmothers, wise women, old hermits, ancient sages
- **Age:** 70s
- **Design prompt:** Native English. Female, 70s. An old dwarf grandmother, tough as granite and warm underneath. A raspy, low, worn voice, still strong, with a dry chuckle. A thick Scottish burr. Slow, deliberate pace. Wry, stubborn and loving, she teases the young and remembers the lost with quiet pride. Perfect audio quality.
- **Design text:** Sit yourself down, I don't bite. Not anymore, anyway. Ha! My husband marched off to war under the mountain and never came home, and I've kept his axe by this hearth ever since. It's time it went back where it belongs. Will you carry it for an old woman?
- **Stability:** 0.65
- **Similarity:** 0.80
- **Speed:** 0.95
- **Delivery:** Slow and wry, a [laughs] for the jokes and a softer tone for the memories.
- **Avoid:** A frail, trembling whisper or a witch's cackle.

## gnome-male-common

- **Race:** gnome
- **Sex:** male
- **Kind:** common
- **Speaks for:** tinkers, engineers, merchants, vendors, crafters, citizens, flight masters, most quest givers
- **Age:** 40s
- **Design prompt:** Native English. Male, 40s. A gnome tinker and inventor, small, eager and endlessly busy. A high-pitched voice for a man, bright and quick, a little nasal. A neutral North American accent. Fast, chattering pace, words tumbling over each other. Cheerful, scatterbrained and enthusiastic, always halfway through explaining a marvellous machine that has just gone wrong. Perfect audio quality.
- **Design text:** Oh! Oh, splendid, a volunteer! You're just in time. My automatic sheep-shearer has gone a teensy bit haywire and wandered off toward the lake. Could you possibly catch it? Gently, mind you, it bites. Well, technically it shears, but it feels like biting!
- **Stability:** 0.40
- **Similarity:** 0.75
- **Speed:** 1.10
- **Delivery:** Fast and bubbly, jumping between ideas, with an [excited] lift at every new thought.
- **Avoid:** A squeaky cartoon voice or a slow, deep tone.

## gnome-male-martial

- **Race:** gnome
- **Sex:** male
- **Kind:** martial
- **Speaks for:** guards, soldiers, officers, warriors, hunters, mechanized troops; gnome bosses
- **Age:** 30s
- **Design prompt:** Native English. Male, 30s. A gnome soldier of his people's army, small but determined. A high, sharp, slightly nasal voice, bright and clipped. A neutral North American accent. Quick, crisp pace. Plucky, brave and a bit overconfident, all bravado and grit, the voice of someone who knows he is small and refuses to care. Perfect audio quality.
- **Design text:** Stand fast! Gnomeregan will be ours again, one gear at a time! The troggs have breached the eastern vent, and our sappers need cover while they set the charges. Keep your eyes peeled, your goggles on, and do not, under any circumstances, touch the red wire!
- **Stability:** 0.40
- **Similarity:** 0.75
- **Speed:** 1.05
- **Delivery:** Quick and commanding, with a proud lift on rallying lines; yells take [shouting].
- **Avoid:** A deep, gruff soldier's voice or a timid tone.

## gnome-male-refined

- **Race:** gnome
- **Sex:** male
- **Kind:** refined
- **Speaks for:** mages, warlocks, scholars, officials, master inventors, ambassadors, leaders
- **Age:** 50s
- **Design prompt:** Native English. Male, 50s. A gnome mage and academic, brilliant and a little fussy. A high, precise, slightly nasal voice, crisp and clear. A neutral accent with very careful diction. Quick but controlled pace. Pedantic, clever and mildly impatient, the tone of a professor who has explained this three times already and will explain it again. Perfect audio quality.
- **Design text:** Now, as I explained in my last paper, which nobody read, the arcane field around the crystal fluctuates at precisely seven and a quarter cycles. Do try to keep up. I need three samples, sealed, unscratched and, above all, not exploded. The last apprentice was very careless.
- **Stability:** 0.45
- **Similarity:** 0.80
- **Speed:** 1.05
- **Delivery:** Precise and quick, with dry emphasis on the details that matter to him.
- **Avoid:** A booming wizard's voice or a babbling, scattered tone.

## gnome-male-elder

- **Race:** gnome
- **Sex:** male
- **Kind:** elder
- **Speaks for:** elders, old tinkers, old hermits, ancient sages
- **Age:** 70s
- **Design prompt:** Native English. Male, 70s. A very old gnome tinker, absent-minded and twinkling. A high, thin, reedy voice with a crackle of age, still nimble. A neutral North American accent. Quick bursts of words broken by pauses as he loses his thread. Chuckling, warm and sharp-witted, delighted by memories and gadgets alike. Perfect audio quality.
- **Design text:** Hee hee, yes, yes, I remember Gnomeregan before the troubles. Shining halls, singing pipes, the smell of oil and fresh solder... wonderful. Now, where did I put my spectacles? Never mind. Here's the old blueprint. Take it to the workshop, and tell them the old professor sent you!
- **Stability:** 0.50
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Lively in bursts and slow in between, with a [laughs] at his own forgetfulness.
- **Avoid:** A deep, slow, grave tone; even an old gnome is quick.

## gnome-female-common

- **Race:** gnome
- **Sex:** female
- **Kind:** common
- **Speaks for:** tinkers, engineers, merchants, vendors, crafters, citizens, flight masters, most quest givers
- **Age:** 30s
- **Design prompt:** Native English. Female, 30s. A gnome engineer and shopkeeper, cheerful and inventive. A high, bright, quick voice, a little nasal, light and bubbly. A neutral North American accent. Very fast, chatty pace. Upbeat, curious and a touch scatterbrained, she notices everything and gets excited about all of it. Perfect audio quality.
- **Design text:** Hi there! Ooh, is that a new pack? Lovely stitching. Anyway! I'm testing a brand-new homing pigeon, mechanical of course, and it homed... somewhere else. Somewhere over the hills. If you find it, bring it back, and I'll give you a discount on repairs. A big one!
- **Stability:** 0.40
- **Similarity:** 0.75
- **Speed:** 1.10
- **Delivery:** Bright and rapid, with lots of small turns and an [excited] lift.
- **Avoid:** A childlike squeak or a slow, dreamy tone.

## gnome-female-martial

- **Race:** gnome
- **Sex:** female
- **Kind:** martial
- **Speaks for:** guards, soldiers, officers, warriors, hunters, mechanized troops; gnome bosses
- **Age:** 20s
- **Design prompt:** Native English. Female, 20s. A young gnome soldier and mechanic, fierce for her size. A high, sharp, spunky voice, bright and slightly nasal, with a hard edge. A neutral North American accent. Fast, clipped pace. Determined, bold and a little cocky, she gives orders quickly and fights with a grin. Perfect audio quality.
- **Design text:** Alright, listen up! We've got leper gnomes in the tunnels and a tank with a busted tread. I fix the tread. You keep them off me. Simple! If I yell duck, you duck. If I yell run, you run faster than you have ever run before. Got it? Great. Go!
- **Stability:** 0.40
- **Similarity:** 0.75
- **Speed:** 1.05
- **Delivery:** Rapid and punchy, short commands with energy; yells take [shouting].
- **Avoid:** A deep, heavy warrior's voice or a giggly tone.

## gnome-female-refined

- **Race:** gnome
- **Sex:** female
- **Kind:** refined
- **Speaks for:** mages, warlocks, priestesses, scholars, officials, ambassadors, leaders
- **Age:** 40s
- **Design prompt:** Native English. Female, 40s. A gnome mage and researcher, composed and brilliant. A clear, quick, precise voice, high but polished, slightly nasal. A neutral accent with crisp diction. Brisk, orderly pace. Confident, analytical and courteous, she sounds like a scientist reporting results she is rather proud of. Perfect audio quality.
- **Design text:** Fascinating results, truly. The arcane residue in these samples suggests a portal was opened here, and recently. I'll need you to place these three detectors around the ruins. Equal distances, please, measured from the central pillar. Precision matters, and so, I'm afraid, does speed.
- **Stability:** 0.45
- **Similarity:** 0.80
- **Speed:** 1.05
- **Delivery:** Precise and efficient, each instruction clear, with a hint of excitement for the discovery.
- **Avoid:** Bubbly chatter or a cold, robotic flatness.

## gnome-female-elder

- **Race:** gnome
- **Sex:** female
- **Kind:** elder
- **Speaks for:** elders, grandmothers, old tinkers, old hermits, ancient sages
- **Age:** 70s
- **Design prompt:** Native English. Female, 70s. An old gnome inventor, sweet and still sharp. A high, thin, crackly voice, light and twinkling. A neutral North American accent. Chatty pace, quick words with small breathless pauses. Warm, playful and proud, a grandmother who still tinkers every day and loves an audience. Perfect audio quality.
- **Design text:** Oh my, a visitor! Come in, come in, mind the cogs on the floor. I've been tinkering since before your grandmother was born, dear, and I've still never finished my clockwork kettle. Would you fetch me some copper wire from the market? My legs aren't quick anymore, but my hands still are!
- **Stability:** 0.50
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Cheerful and chatty, a little slower than younger gnomes, with a light [laughs].
- **Avoid:** A deep, slow, solemn voice or a frail whisper.

## nightelf-male-common

- **Race:** nightelf
- **Sex:** male
- **Kind:** common
- **Speaks for:** merchants, vendors, crafters, innkeepers, hippogryph masters, citizens, most quest givers
- **Age:** 40s
- **Design prompt:** Native English. Male, 40s. A night elf villager of an ancient forest people, patient and gentle. A deep, calm, smooth voice, low in pitch, with a soft, slightly airy quality. A soft, hard-to-place accent with careful, slightly formal English. Measured, unhurried pace. Serene and courteous, quietly worried for the forest, never raising his voice. Perfect audio quality.
- **Design text:** Be welcome, traveler, and rest beneath the boughs. The forest has been restless of late. Something taints the moonwells to the north, and the creatures there have grown sick and angry. Gather the tainted water, if you would, so that our priestesses may study it.
- **Stability:** 0.60
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Calm, even and soft, with a gentle weight on words of nature.
- **Avoid:** A casual, modern tone or a quick, chatty pace.

## nightelf-male-martial

- **Race:** nightelf
- **Sex:** male
- **Kind:** martial
- **Speaks for:** guards, warriors, hunters, archers, scouts, soldiers; night elf captains
- **Age:** 30s
- **Design prompt:** Native English. Male, 30s. A night elf hunter and warrior, a silent guardian of the woods. A deep, solemn, low voice, controlled and quiet, with a stern edge. A soft, hard-to-place accent with careful, slightly formal English. Slow, deliberate pace. Grave, watchful and intense, a man who speaks little and means every word. Perfect audio quality.
- **Design text:** Hold. Move quietly here. The furbolgs have been driven mad, and they watch the paths. I have lost two scouts this week. Find the source of their madness and end it, if you can. Do not linger in the open, and do not trust the silence. The forest is never truly silent.
- **Stability:** 0.60
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Low and restrained, almost hushed, with firm stops between orders; battle cries are fierce but brief.
- **Avoid:** Barking like an orc or a bright, friendly tone.

## nightelf-male-refined

- **Race:** nightelf
- **Sex:** male
- **Kind:** refined
- **Speaks for:** druids, scholars, keepers of lore, officials, ambassadors, leaders
- **Age:** 50s
- **Design prompt:** Native English. Male, 50s. A night elf archdruid, ancient in spirit and deeply wise. A very deep, resonant, solemn voice, warm at its core, with a slow and dignified cadence. A soft, hard-to-place accent with careful, formal English. Unhurried, thoughtful pace. Serene authority and quiet gravity, a teacher who has watched ages pass and chooses each word with care. Perfect audio quality.
- **Design text:** Ten thousand years I have walked the Dream, and still it surprises me. Listen. The roots of the great tree are troubled, and their trouble spreads. Go to the old barrow and speak with the spirit there. Go in peace... and return with wisdom, not merely with trophies.
- **Stability:** 0.65
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Slow, resonant and grave, with long pauses for weight.
- **Avoid:** Pompous theatrics or a thin, light voice.

## nightelf-male-elder

- **Race:** nightelf
- **Sex:** male
- **Kind:** elder
- **Speaks for:** elders, old druids, old hermits, ancient sages
- **Age:** 70s
- **Design prompt:** Native English. Male, 70s. A very old night elf sage, worn smooth by the ages like old wood. A deep, aged, soft voice, slightly breathy, gentle and calm. A soft, hard-to-place accent with careful, formal English. Very slow, dreamy pace, as if remembering from far back. Kind, melancholy and knowing, with a faint, fond smile in his words. Perfect audio quality.
- **Design text:** I remember when the stars over this glade were young... well, younger. Hmm. You have a question in your eyes. Ask it, then, and I will answer as best an old mind can. But know this, young one: some answers are best left sleeping beneath the roots.
- **Stability:** 0.70
- **Similarity:** 0.80
- **Speed:** 0.90
- **Delivery:** Very slow and soft, drifting between thoughts with gentle pauses.
- **Avoid:** A cracked, frail old man's voice; he is aged, not feeble.

## nightelf-female-common

- **Race:** nightelf
- **Sex:** female
- **Kind:** common
- **Speaks for:** merchants, vendors, crafters, innkeepers, hippogryph masters, citizens, most quest givers
- **Age:** 30s
- **Design prompt:** Native English. Female, 30s. A night elf villager of an ancient forest people, kind and graceful. A soft, airy, gentle voice, mid pitch, light and smooth. A soft, hard-to-place accent with careful, slightly formal English. Calm, flowing pace. Warm, welcoming and serene, with a quiet care for every creature of the woods. Perfect audio quality.
- **Design text:** Greetings, friend. Have you come far? The road through the grove is long, but you are safe here. If you have a moment, the nightsaber cubs have strayed past the river again. Would you guide them home? They are curious, and the river is cold tonight.
- **Stability:** 0.60
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Soft and flowing, gently smiling, never hurried.
- **Avoid:** A whispery, breathless tone or a bright, bubbly one.

## nightelf-female-martial

- **Race:** nightelf
- **Sex:** female
- **Kind:** martial
- **Speaks for:** Sentinels, guards, warriors, huntresses, archers, scouts; night elf captains
- **Age:** 30s
- **Design prompt:** Native English. Female, 30s. A night elf Sentinel, a warrior of the forest's watch. A soft but steely voice, cool and focused, a little low for her people. A soft, hard-to-place accent with careful, slightly formal English. Measured, controlled pace. Determined and quietly commanding, she speaks low and sure, with the stillness of a hunter about to strike. Perfect audio quality.
- **Design text:** Keep your voice low. The satyrs have made a camp in the ruins, and they believe no one sees them. They are wrong. My Sentinels will take the high ground. You will go in at moonrise, while they sleep. Strike swiftly. Let none of them carry word to their master.
- **Stability:** 0.60
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Quiet and precise, each order cool and certain; battle cries are sharp and short.
- **Avoid:** Loud barking or a sweet, gentle tone.

## nightelf-female-refined

- **Race:** nightelf
- **Sex:** female
- **Kind:** refined
- **Speaks for:** priestesses of the moon, druids, scholars, officials, ambassadors, leaders
- **Age:** 40s
- **Design prompt:** Native English. Female, 40s. A night elf high priestess of the moon goddess, serene and luminous. A clear, airy, graceful voice, mid pitch, smooth and gently resonant. A soft, hard-to-place accent with careful, formal English. Slow, reverent pace. Calm, devout and gently commanding, with a deep compassion and the poise of one who has led her people for ages. Perfect audio quality.
- **Design text:** Elune watches over all who walk beneath her light, even those who have strayed. Take this phial to the moonwell at the heart of the glade, and fill it when the moon is at its highest. Then return to me. We will see together what the goddess wishes to show us.
- **Stability:** 0.65
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Slow and serene, with a reverent softness on holy words.
- **Avoid:** Breathless whispering or a cold, haughty tone.

## nightelf-female-elder

- **Race:** nightelf
- **Sex:** female
- **Kind:** elder
- **Speaks for:** elders, old priestesses, wise women, old hermits, ancient sages
- **Age:** 70s
- **Design prompt:** Native English. Female, 70s. A very old night elf, a priestess who has outlived forests. An aged but airy voice, soft and breathy, gentle and slow. A soft, hard-to-place accent with careful, formal English. Very slow pace, with long pauses. Melancholy, knowing and tender, she sounds tired of the long years yet kind to the young. Perfect audio quality.
- **Design text:** So many years... I have seen forests burn and grow again, and burn once more. Do not grieve for me, young one; I am merely tired. But there is one thing left I would do. My sister's grave lies far to the south. Lay this flower upon it for me, would you?
- **Stability:** 0.70
- **Similarity:** 0.80
- **Speed:** 0.90
- **Delivery:** Slow and wistful, with a soft [sighs] between thoughts.
- **Avoid:** A crackly witch's voice or a bright, quick tone.

## orc-male-common

- **Race:** orc
- **Sex:** male
- **Kind:** common
- **Speaks for:** peons, farmers, merchants, vendors, crafters, innkeepers, wind rider masters, citizens, most quest givers
- **Age:** 40s
- **Design prompt:** Native English. Male, 40s. An orc villager and trader of the Horde, a working orc. A deep, gravelly, guttural voice, low and rough at the edges. A neutral North American accent, plain and harsh. Steady, direct pace. Blunt, practical and gruff but not hostile, a hard worker who says what he needs and nothing more. Perfect audio quality.
- **Design text:** You. You look strong enough. The quillboars have been stealing from our supply wagons, and my peons are too scared to go out. Find their camp. Take back what is ours. Do this, and you will have my thanks, and some coin. That is fair, yes?
- **Stability:** 0.55
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Short and blunt sentences, gruff and even; a low grunt of approval at the end.
- **Avoid:** A dim-witted or brutish tone; orcs are direct, not stupid.

## orc-male-martial

- **Race:** orc
- **Sex:** male
- **Kind:** martial
- **Speaks for:** grunts, guards, warriors, hunters, officers, champions, soldiers; orc bosses and raiders
- **Age:** 30s
- **Design prompt:** Native English. Male, 30s. An orc warrior and grunt of the Horde, battle-hungry and fierce. A very deep, harsh, gravelly voice with a guttural growl, powerful and rough. A neutral North American accent, hard and clipped. Fast, aggressive pace. Proud, aggressive and fearless, eager for a fight, every word a challenge. Perfect audio quality.
- **Design text:** On your feet! Do not stand there like a peon! The Alliance dogs have crossed the river, and they think the Horde will run. We do not run! Take your axe, find their captain, and bring me his banner. Fight with honor, and fight hard. Now go!
- **Stability:** 0.50
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Forceful and barked, with growled emphasis; battle cries take [shouting] or [angry].
- **Avoid:** A smooth, polished voice or a high, thin one.

## orc-male-refined

- **Race:** orc
- **Sex:** male
- **Kind:** refined
- **Speaks for:** shamans, warlocks, far seers, officials, advisors, emissaries, leaders
- **Age:** 50s
- **Design prompt:** Native English. Male, 50s. An orc shaman and elder statesman of the Horde, wise and weighty. A deep, gravelly voice, but controlled and smooth beneath the rasp, low and resonant. A neutral North American accent. Slow, deliberate pace. Calm authority and spiritual gravity, a leader who listens to the elements and speaks only after thinking. Perfect audio quality.
- **Design text:** The spirits are uneasy, young one. I hear it in the wind and feel it in the stone. Something stirs in the canyon, something that should have stayed buried. Go there. Listen, as I have taught you. And if the elements speak to you, do not be too proud to answer them.
- **Stability:** 0.60
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Slow and grave, steady and resonant, with weight on the spirits and the elements.
- **Avoid:** Shouting or a rough, brutish growl.

## orc-male-elder

- **Race:** orc
- **Sex:** male
- **Kind:** elder
- **Speaks for:** elders, old veterans, old hermits, ancient sages
- **Age:** 70s
- **Design prompt:** Native English. Male, 70s. An old orc veteran of the old wars, scarred and proud. A very gravelly, rough, low voice, worn and wheezing at the edges. A neutral North American accent. Slow, heavy pace. Weary, grim and dignified, carrying old grief and hard-won wisdom, with a grudging warmth toward the young. Perfect audio quality.
- **Design text:** I fought in the old war. Many of my brothers did not come back. I carry them with me, here. Hmph. You young ones think the Horde was always free. It was not. Remember that, when you raise your axe. Freedom was paid for, in blood we can never take back.
- **Stability:** 0.65
- **Similarity:** 0.80
- **Speed:** 0.95
- **Delivery:** Slow and heavy, with a rough [sighs]; quietly fierce on the lessons.
- **Avoid:** A feeble, thin voice or a battle roar.

## orc-female-common

- **Race:** orc
- **Sex:** female
- **Kind:** common
- **Speaks for:** peons, farmers, merchants, vendors, crafters, innkeepers, wind rider masters, citizens, most quest givers
- **Age:** 30s
- **Design prompt:** Native English. Female, 30s. An orc trader and tanner of the Horde, tough and practical. A low, husky, strong voice with a gravelly edge, deep for a woman. A neutral North American accent, plain and firm. Brisk, direct pace. Blunt, impatient and fair, she wastes no words and respects hard work. Perfect audio quality.
- **Design text:** Hey. You there. Do not just stand around. The raptors took two of my wolves last night, and I want their hides. Five of them. Bring them to me, and I will make you boots that last a lifetime. A long life, if you are lucky. Go!
- **Stability:** 0.55
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Brisk and blunt, firm on every order, a gruff warmth in the bargain.
- **Avoid:** A soft, sweet tone or a cartoonish growl.

## orc-female-martial

- **Race:** orc
- **Sex:** female
- **Kind:** martial
- **Speaks for:** grunts, guards, warriors, hunters, officers, champions, soldiers; orc bosses and raiders
- **Age:** 30s
- **Design prompt:** Native English. Female, 30s. An orc warrior and raid leader of the Horde, fierce and proud. A deep, gravelly, harsh voice for a woman, powerful and commanding. A neutral North American accent, hard and clipped. Fast, forceful pace. Aggressive, fearless and confident, with a hunter's grim delight in battle. Perfect audio quality.
- **Design text:** On your feet, grunt! The centaur raid our caravans and laugh about it. Not today. We ride at dawn, and we leave nothing standing. You will fight at my side. Fight well, and the Horde will sing of you. Fight poorly... and the vultures will.
- **Stability:** 0.50
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Fierce and driving, growled on threats; battle cries take [shouting].
- **Avoid:** A shrill tone or a smooth, polished voice.

## orc-female-refined

- **Race:** orc
- **Sex:** female
- **Kind:** refined
- **Speaks for:** shamans, warlocks, far seers, officials, advisors, emissaries, leaders
- **Age:** 40s
- **Design prompt:** Native English. Female, 40s. An orc shaman and advisor of the Horde, wise and steady. A deep, smooth voice with a fine gravel, low and resonant, controlled. A neutral North American accent. Slow, measured pace. Calm, wise and commanding, with a quiet intensity and a spiritual gravity that make others fall silent. Perfect audio quality.
- **Design text:** Sit with me by the fire. The elements have been quiet for too long, and silence, among the spirits, is never a good sign. I want you to carry this totem to the high ridge and plant it in the earth. Then wait, and watch. Tell me, truly, what you see.
- **Stability:** 0.60
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Low, slow and grounded, each instruction given with calm weight.
- **Avoid:** Harsh barking or a light, airy tone.

## orc-female-elder

- **Race:** orc
- **Sex:** female
- **Kind:** elder
- **Speaks for:** elders, grandmothers, wise women, old hermits, ancient sages
- **Age:** 70s
- **Design prompt:** Native English. Female, 70s. An old orc grandmother who survived the hard years, tough and stern. A low, cracked, raspy voice, rough and worn, still strong. A neutral North American accent. Slow, deliberate pace. Stern, sharp-tongued and secretly tender, she scolds the young and worries for her family. Perfect audio quality.
- **Design text:** Bah, so young, so loud. When I was your age, we had no time to be loud. We had the camps, and the hunger. Now listen. My grandson went to the Barrens and has not written. He is stubborn, like his mother. Find him. Tell him his grandmother is not dead yet.
- **Stability:** 0.65
- **Similarity:** 0.80
- **Speed:** 0.95
- **Delivery:** Slow and gruff, with a dry edge and a softer tone for family.
- **Avoid:** A frail, sweet voice or a battle growl.

## troll-male-common

- **Race:** troll
- **Sex:** male
- **Kind:** common
- **Speaks for:** fishers, merchants, vendors, crafters, innkeepers, wind rider masters, citizens, most quest givers
- **Age:** 40s
- **Design prompt:** Native English. Male, 40s. A troll fisherman and trader of a jungle and island tribe, easygoing and friendly. A smooth, warm, mid-low voice with a relaxed Caribbean-style lilt and a rolling, musical rhythm. Laid-back, playful pace. Good-humoured, generous and a little sly, always ready to share food and a joke. Respectful and natural, never a caricature. Perfect audio quality.
- **Design text:** Hey, friend, come over here, sit down a minute. You look like you could use a good meal... and a little work. The crabs on the beach are getting too bold, pinching my nets. Bring me some of their claws, and I will make you a soup you will never forget!
- **Stability:** 0.40
- **Similarity:** 0.75
- **Speed:** 1.00
- **Delivery:** Relaxed and rolling, with a smile in every line and a [laughs] now and then.
- **Avoid:** An exaggerated, mocking accent; the lilt is natural and warm.

## troll-male-martial

- **Race:** troll
- **Sex:** male
- **Kind:** martial
- **Speaks for:** guards, warriors, hunters, headhunters, berserkers, soldiers; troll bosses of the jungle and the ruins
- **Age:** 30s
- **Design prompt:** Native English. Male, 30s. A troll headhunter and warrior of a jungle tribe, wild and dangerous. A deep, strong voice with a relaxed Caribbean-style lilt and rolling rhythm, edged with menace. Quick, energetic pace. Fierce, proud and fearless, with a dangerous laugh and a fighter's swagger. Respectful and natural, never a caricature. Perfect audio quality.
- **Design text:** Listen good. The Bloodscalp tribe is sharpening their spears in the jungle, and they think we forgot what they did. We never forget. You go in quiet, and you come out with their chief's tusks. Nobody touches my people. Nobody! Now go, before I change my mind and go myself!
- **Stability:** 0.40
- **Similarity:** 0.75
- **Speed:** 1.00
- **Delivery:** Energetic and menacing, rolling on the threats; battle cries take [shouting], taunts a [laughs].
- **Avoid:** A cartoonish accent or a flat, cold tone.

## troll-male-refined

- **Race:** troll
- **Sex:** male
- **Kind:** refined
- **Speaks for:** shamans, witch doctors, priests, mages, officials, leaders
- **Age:** 50s
- **Design prompt:** Native English. Male, 50s. A troll witch doctor and spiritual leader, mysterious and knowing. A deep, smooth, sonorous voice with a relaxed Caribbean-style lilt and a slow, rolling rhythm. Unhurried, hypnotic pace. Sly, wise and a little unsettling, he speaks as if the spirits whisper in his ear. Respectful and natural, never a caricature. Perfect audio quality.
- **Design text:** Ah, I have been waiting for you. The spirits told me you would come, and the spirits, they never lie... not to me. There is a dark magic growing in the swamp. You bring me the heart of the thing that grows it, and I will show you what the loa have planned for you.
- **Stability:** 0.45
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Slow and mysterious, savouring words, with a low chuckle at the secrets.
- **Avoid:** A goofy or mocking accent; his mystery is dignified.

## troll-male-elder

- **Race:** troll
- **Sex:** male
- **Kind:** elder
- **Speaks for:** elders, old witch doctors, old hermits, ancient sages
- **Age:** 70s
- **Design prompt:** Native English. Male, 70s. An old troll elder of an island tribe, who has seen empires rise and fall. A raspy, aged, deep voice with a relaxed Caribbean-style lilt and a slow, rolling rhythm. Slow, unhurried pace. Wry, wise and a little eerie, with a soft chuckle and the patience of the tide. Respectful and natural, never a caricature. Perfect audio quality.
- **Design text:** Heh, heh. Sit, sit. Old bones need company. I have seen many moons over these islands, and empires of my people rise and fall like the tide. Now the tide, it is coming back in. Go to the old shrine by the water. Tell me what you see there. And mind the snakes. They remember me.
- **Stability:** 0.55
- **Similarity:** 0.80
- **Speed:** 0.95
- **Delivery:** Slow and rolling, with a dry chuckle and long pauses.
- **Avoid:** A frail whisper or an exaggerated accent.

## troll-female-common

- **Race:** troll
- **Sex:** female
- **Kind:** common
- **Speaks for:** fishers, merchants, vendors, crafters, innkeepers, wind rider masters, citizens, most quest givers
- **Age:** 30s
- **Design prompt:** Native English. Female, 30s. A troll trader and cook of an island tribe, warm and teasing. A bright, musical mid-range voice with a relaxed Caribbean-style lilt and rolling rhythm. Easy, lively pace. Friendly, playful and caring, she teases strangers and feeds them anyway. Respectful and natural, never a caricature. Perfect audio quality.
- **Design text:** Oh, look at you! All dusty from the road. Come, come, have some fruit, it is fresh this morning. When you are done eating, maybe you help me? My little raptor got loose again, and he is hiding in the tall grass. Bring him back, and do not let him bite you. He is shy!
- **Stability:** 0.40
- **Similarity:** 0.75
- **Speed:** 1.00
- **Delivery:** Bright and singing, with a teasing [laughs] here and there.
- **Avoid:** A mocking accent or a cold, flat tone.

## troll-female-martial

- **Race:** troll
- **Sex:** female
- **Kind:** martial
- **Speaks for:** guards, warriors, huntresses, headhunters, berserkers, soldiers; troll bosses of the jungle and the ruins
- **Age:** 30s
- **Design prompt:** Native English. Female, 30s. A troll huntress and warrior of a jungle tribe, sharp and dangerous. A strong, slightly husky voice with a relaxed Caribbean-style lilt and rolling rhythm, edged with a sly menace. Quick, confident pace. Bold, fierce and cunning, a hunter who enjoys the chase. Respectful and natural, never a caricature. Perfect audio quality.
- **Design text:** You ready to hunt? Good. The tigers of this jungle are smart, smarter than most of the fools I fight beside. Move with the wind, not against it. Strike fast, strike once. When you bring me the hide of the great white cat, then I call you a hunter. Not before!
- **Stability:** 0.40
- **Similarity:** 0.75
- **Speed:** 1.00
- **Delivery:** Quick and challenging, with a dangerous smile; battle cries take [shouting].
- **Avoid:** A sweet, soft tone or an exaggerated accent.

## troll-female-refined

- **Race:** troll
- **Sex:** female
- **Kind:** refined
- **Speaks for:** witch doctors, priestesses, shamans, mages, officials, leaders
- **Age:** 40s
- **Design prompt:** Native English. Female, 40s. A troll witch doctor and priestess of the loa, mysterious and wise. A low, velvety voice with a relaxed Caribbean-style lilt and a slow, rolling rhythm. Unhurried, deliberate pace. Knowing, spiritual and a little playful, with a gleam of mischief and real power behind it. Respectful and natural, never a caricature. Perfect audio quality.
- **Design text:** Come closer. Do not be afraid of the bones, they only talk when they have something to say. Tonight they say there is a curse on you. A small one, nothing serious... yet. Bring me three feathers from the black vultures of the canyon, and I will make it go away. Probably.
- **Stability:** 0.45
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Slow and knowing, half amused, half grave.
- **Avoid:** A cartoon fortune teller or a mocking accent.

## troll-female-elder

- **Race:** troll
- **Sex:** female
- **Kind:** elder
- **Speaks for:** elders, grandmothers, old witch doctors, old hermits, ancient sages
- **Age:** 70s
- **Design prompt:** Native English. Female, 70s. An old troll woman, the healer and storyteller of her tribe. A cracked, aged voice with a relaxed Caribbean-style lilt and a slow, rolling rhythm, warm beneath the rasp. Slow pace with a ready cackle. Shrewd, wise and affectionate, she knows every herb and every old tale. Respectful and natural, never a caricature. Perfect audio quality.
- **Design text:** Heh! You come to see the old woman, eh? Everybody does, sooner or later. I know the herbs, the songs, the old names. Sit down, and stop fidgeting. I tell you a story about the first loa, and you listen with both ears, because I only tell it once.
- **Stability:** 0.55
- **Similarity:** 0.80
- **Speed:** 0.95
- **Delivery:** Slow and storytelling, with a sharp little [laughs].
- **Avoid:** A wicked witch voice or an exaggerated accent.

## tauren-male-common

- **Race:** tauren
- **Sex:** male
- **Kind:** common
- **Speaks for:** herders, farmers, merchants, vendors, crafters, innkeepers, wind rider masters, citizens, most quest givers
- **Age:** 40s
- **Design prompt:** Native English. Male, 40s. A tauren herder of the open plains, huge and gentle. A very deep, warm, earthy bass voice with a soft rumble. A plain, neutral accent. Slow, unhurried pace. Kind, patient and humble, the calm of someone who has spent his life under a wide sky with the herds. Perfect audio quality.
- **Design text:** Peace be upon you, friend. The plains are wide, and the grass is good this year. But the kodo herd has been frightened by something near the hills. Walk with me a while, and help me bring them back. The Earth Mother rewards a patient heart.
- **Stability:** 0.65
- **Similarity:** 0.80
- **Speed:** 0.95
- **Delivery:** Slow, warm and steady, every sentence settling like a footstep.
- **Avoid:** A dull, dim tone or a hurried pace.

## tauren-male-martial

- **Race:** tauren
- **Sex:** male
- **Kind:** martial
- **Speaks for:** braves, guards, warriors, hunters, soldiers, champions; tauren chieftains in battle
- **Age:** 30s
- **Design prompt:** Native English. Male, 30s. A tauren brave and warrior, strong and noble. A very deep, booming, powerful bass voice, firm and steady. A plain, neutral accent. Slow, resolute pace. Proud, fearless and honourable, a calm intensity that turns to thunder in battle. Perfect audio quality.
- **Design text:** The centaur have burned another village. No more. I have gathered the braves of the tribe, and we march at first light. Your strength would honor us. Fight beside us, and fight well. When the battle is done, we will sing for the fallen and rest beneath the open sky.
- **Stability:** 0.60
- **Similarity:** 0.80
- **Speed:** 0.95
- **Delivery:** Deep and resolute, measured and strong; battle cries take [shouting].
- **Avoid:** A brutish growl or a quick, agitated pace.

## tauren-male-refined

- **Race:** tauren
- **Sex:** male
- **Kind:** refined
- **Speaks for:** druids, shamans, seers, officials, ambassadors, chieftains and leaders
- **Age:** 50s
- **Design prompt:** Native English. Male, 50s. A tauren druid and seer, wise and contemplative. A very deep, resonant, sonorous voice, warm and smooth. A plain, neutral accent with careful words. Very slow, thoughtful pace. Gentle authority and spiritual calm, a teacher who listens to the land and speaks for it. Perfect audio quality.
- **Design text:** The wind carries many voices, young one. Some speak of growth, some of decay. Today it speaks of sickness in the southern hills. Go there, and gather the soil the sickness has touched. Bring it to me, and together we will learn what wounds the land.
- **Stability:** 0.70
- **Similarity:** 0.80
- **Speed:** 0.90
- **Delivery:** Very slow and resonant, with peaceful pauses.
- **Avoid:** A booming warrior's voice or any harshness.

## tauren-male-elder

- **Race:** tauren
- **Sex:** male
- **Kind:** elder
- **Speaks for:** elders, old seers, old hermits, ancient sages
- **Age:** 80s
- **Design prompt:** Native English. Male, 80s. A very old tauren elder, grandfather of his tribe. An extremely deep, aged voice, slow and a little creaky, warm and peaceful. A plain, neutral accent. Very slow pace with long pauses. Gentle, wise and loving, he has watched many winters and fears none of what is to come. Perfect audio quality.
- **Design text:** Many winters I have watched over this mesa. My horns have grown heavy, and my steps slow. Yet my eyes still see what others miss. There is a spirit wandering the old burial ground, lost and grieving. Find it, and guide it home. That is all I will ask of you.
- **Stability:** 0.75
- **Similarity:** 0.80
- **Speed:** 0.90
- **Delivery:** Very slow, deep and kind, with a soft [sighs] of age.
- **Avoid:** A thin, frail voice or any hurry.

## tauren-female-common

- **Race:** tauren
- **Sex:** female
- **Kind:** common
- **Speaks for:** herders, farmers, merchants, vendors, crafters, innkeepers, wind rider masters, citizens, most quest givers
- **Age:** 40s
- **Design prompt:** Native English. Female, 40s. A tauren woman of the plains, a herder and cook, motherly and calm. A deep, warm, earthy voice, low for a woman, soft and steady. A plain, neutral accent. Slow, gentle pace. Kind, nurturing and patient, she makes every traveller feel at home by her fire. Perfect audio quality.
- **Design text:** Welcome, little one. Sit by the fire and rest your feet. The roads are hard this time of year. When you are ready, would you take this basket of bread to the herders on the ridge? They have been out with the kodos for many days, and they will be hungry.
- **Stability:** 0.65
- **Similarity:** 0.80
- **Speed:** 0.95
- **Delivery:** Slow and warm, soothing, with a smile in the voice.
- **Avoid:** A high, bright voice or a quick, chatty pace.

## tauren-female-martial

- **Race:** tauren
- **Sex:** female
- **Kind:** martial
- **Speaks for:** braves, guards, warriors, hunters, soldiers, champions; tauren chieftains in battle
- **Age:** 30s
- **Design prompt:** Native English. Female, 30s. A tauren huntress and warrior, strong and dignified. A deep, firm, powerful voice, low for a woman, steady and resonant. A plain, neutral accent. Slow, resolute pace. Proud, steadfast and determined, a slow-burning courage that never wavers. Perfect audio quality.
- **Design text:** The harpies have taken the high cliffs, and they nest above our camp, laughing. I have had enough of their laughter. Climb the trail, and bring down their matriarch. Strike true. The tribe is watching, and the Earth Mother is watching too.
- **Stability:** 0.60
- **Similarity:** 0.80
- **Speed:** 0.95
- **Delivery:** Firm and measured, each order a steady weight; battle cries take [shouting].
- **Avoid:** A shrill or harsh tone; her strength is calm.

## tauren-female-refined

- **Race:** tauren
- **Sex:** female
- **Kind:** refined
- **Speaks for:** druids, shamans, seers, officials, ambassadors, chieftains and leaders
- **Age:** 50s
- **Design prompt:** Native English. Female, 50s. A tauren druid and spiritual leader, serene and wise. A deep, warm, resonant voice, smooth and calm. A plain, neutral accent with careful words. Very slow, flowing pace. Gentle, wise and quietly commanding, she speaks of the land as of a living friend. Perfect audio quality.
- **Design text:** All things are connected, the root and the river, the hawk and the hare. When one suffers, all suffer. A darkness has crept into the water of the oasis. Gather three samples, and bring them to me. Together we will find the wound, and heal it.
- **Stability:** 0.70
- **Similarity:** 0.80
- **Speed:** 0.90
- **Delivery:** Slow and serene, every phrase given space.
- **Avoid:** A cold or hurried tone.

## tauren-female-elder

- **Race:** tauren
- **Sex:** female
- **Kind:** elder
- **Speaks for:** elders, grandmothers, old seers, wise women, ancient sages
- **Age:** 80s
- **Design prompt:** Native English. Female, 80s. A very old tauren grandmother and dreamer of her tribe. A deep, aged voice, soft and slightly gravelly, warm and slow. A plain, neutral accent. Very slow pace with gentle pauses. Wise, loving and a little mysterious, she dreams true and speaks as if she already knows the end of every tale. Perfect audio quality.
- **Design text:** Ah, you have come. I dreamed of you last night, walking through the tall grass with a feather in your hand. Do not look so surprised, little one. The old ones dream true. Now, help me to my feet. There is a place I must see once more, and I cannot go alone.
- **Stability:** 0.75
- **Similarity:** 0.80
- **Speed:** 0.90
- **Delivery:** Very slow and tender, with a knowing warmth.
- **Avoid:** A frail, quavering voice or a high pitch.

## undead-male-common

- **Race:** undead
- **Sex:** male
- **Kind:** common
- **Speaks for:** merchants, vendors, crafters, innkeepers, bat handlers, gravediggers, citizens, most quest givers
- **Age:** 40s
- **Design prompt:** Native English. Male, 40s. A Forsaken townsman, a dead man who walks again and is not impressed by it. A dry, hollow rasp, mid-low pitch, breathy and gritty. A neutral accent with crisp, clipped consonants. Steady, flat pace. Sardonic, cold and weary, with a dark, deadpan humour. Perfect audio quality.
- **Design text:** Another one? Fine. The Scourge left a mess in the fields, as usual, and the farmers... well, the farmers are part of the mess now. Clear out the walking dead. The ones who walk the wrong way, I mean. Bring me their teeth. Don't ask why.
- **Stability:** 0.55
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Dry and deadpan, with a flat sarcasm and the odd tired [sighs].
- **Avoid:** A monster growl or a warm, friendly tone.

## undead-male-martial

- **Race:** undead
- **Sex:** male
- **Kind:** martial
- **Speaks for:** Deathguards, guards, soldiers, executors, warriors, hunters, rogues; Forsaken bosses
- **Age:** 30s
- **Design prompt:** Native English. Male, 30s. A Forsaken soldier of the Deathguard, grim and merciless. A harsh, cold, gravelly rasp, low and menacing. A neutral accent with clipped, sharp consonants. Quick, hard pace. Contemptuous, intense and ruthless, a soldier who takes cold pleasure in his duty. Perfect audio quality.
- **Design text:** The Scarlet zealots burn our dead and call it purification. We will show them what it means to burn. Their outpost lies west of the river. Kill their captain, take his orders, and leave the rest to rot. The Dark Lady demands it. And I... enjoy it.
- **Stability:** 0.50
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Cold and clipped, the threats low and hissed; yells take [shouting] or [menacing].
- **Avoid:** A wet monster voice or a warm, heroic tone.

## undead-male-refined

- **Race:** undead
- **Sex:** male
- **Kind:** refined
- **Speaks for:** apothecaries, mages, priests, warlocks, scholars, officials, leaders
- **Age:** 50s
- **Design prompt:** Native English. Male, 50s. A Forsaken apothecary and scholar, cultured and calculating. A dry, smooth, precise rasp, mid pitch, refined beneath the decay. A neutral accent with precise diction and a slight old-world formality. Measured, deliberate pace. Sardonic, cold and quietly delighted by his dreadful work. Perfect audio quality.
- **Design text:** Ah, how delightful, a fresh pair of hands. The Royal Apothecary Society requires certain ingredients for our newest work. Nothing difficult, merely the venom sacs of the forest spiders and the liver of a healthy wolf. Healthy, mind you. The plague must be... perfected.
- **Stability:** 0.55
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Smooth and precise, savouring the grim details with dry amusement.
- **Avoid:** A cackling mad scientist or a growling monster.

## undead-male-elder

- **Race:** undead
- **Sex:** male
- **Kind:** elder
- **Speaks for:** elders, old scholars, old hermits, ancient sages
- **Age:** 70s
- **Design prompt:** Native English. Male, 70s. A Forsaken who died an old man and came back that way. A very dry, brittle, thin rasp, creaking and tired. A neutral accent. Slow, halting pace. Bitter, morbid and wryly funny, he mourns his old life with sarcasm. Perfect audio quality.
- **Design text:** I died old, you know. Bad luck. The young ones at least came back with all their teeth. Hmph. I was a scholar in Lordaeron, once, before the plague, before everything. My books are still in the ruins of my house. Fetch them for me. The dead have time to read.
- **Stability:** 0.65
- **Similarity:** 0.80
- **Speed:** 0.95
- **Delivery:** Slow and dry, with a brittle [sighs] and a flat wit.
- **Avoid:** A warm grandfather's voice or a monster's growl.

## undead-female-common

- **Race:** undead
- **Sex:** female
- **Kind:** common
- **Speaks for:** merchants, vendors, crafters, innkeepers, bat handlers, gravediggers, citizens, most quest givers
- **Age:** 40s
- **Design prompt:** Native English. Female, 40s. A Forsaken townswoman, dead and dryly unbothered by it. A dry, hollow rasp, mid pitch, cool and thin. A neutral accent with crisp, clipped consonants. Brisk, flat pace. Sardonic, sharp and weary, with a bitter edge and a dark sense of humour. Perfect audio quality.
- **Design text:** Don't stare, it's rude. Yes, my jaw is held on with wire. Now, are you here to work or to gawk? The bats in the old mill have been carrying off my supplies. Thin them out, and bring back what they stole. If you happen to find my left hand, I'd like that back too.
- **Stability:** 0.55
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Dry and sharp, deadpan, with sarcasm on the jokes.
- **Avoid:** A sweet, warm tone or a screeching ghoul.

## undead-female-martial

- **Race:** undead
- **Sex:** female
- **Kind:** martial
- **Speaks for:** Deathguards, guards, soldiers, executors, warriors, hunters, rogues; Forsaken bosses
- **Age:** 30s
- **Design prompt:** Native English. Female, 30s. A Forsaken soldier and assassin, ruthless and controlled. A cold, sharp rasp, mid-low pitch, hard and menacing. A neutral accent with clipped consonants. Quick, precise pace. Controlled fury, utter fearlessness and a chilling calm. Perfect audio quality.
- **Design text:** We are the Forsaken. We serve no one but the Dark Lady, and we fear nothing, not even death. Least of all death. The Scourge has a camp in the hills. Burn it. Leave nothing that can rise again. If they beg, remind them that they took our lives first.
- **Stability:** 0.50
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Cold and precise, menace held low; battle cries take [shouting] or [menacing].
- **Avoid:** A shrill shriek or a warm, heroic tone.

## undead-female-refined

- **Race:** undead
- **Sex:** female
- **Kind:** refined
- **Speaks for:** apothecaries, mages, priestesses, warlocks, scholars, officials, leaders
- **Age:** 40s
- **Design prompt:** Native English. Female, 40s. A Forsaken noblewoman and apothecary, elegant in death. A cool, poised, hollow rasp, smooth and silky beneath the dryness. A neutral accent with precise, aristocratic diction. Slow, measured pace. Courteous, cruel and darkly amused, a hostess who smiles while she poisons. Perfect audio quality.
- **Design text:** Do sit down. I so rarely have living company that I've forgotten how to be a proper hostess. There's a vial on the shelf behind you, the green one. No, don't drink it. Take it to the farm by the river and pour it into their well. We'll see how they like the harvest this year.
- **Stability:** 0.55
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Silky and unhurried, every courtesy sharpened with menace.
- **Avoid:** A cackling villain or a warm, kind tone.

## undead-female-elder

- **Race:** undead
- **Sex:** female
- **Kind:** elder
- **Speaks for:** elders, grandmothers, old hermits, ancient sages
- **Age:** 70s
- **Design prompt:** Native English. Female, 70s. A Forsaken who died an old grandmother, mournful and bitter. A very dry, thin, crackling rasp, slow and tired. A neutral accent. Slow, halting pace. Sorrowful, sardonic and darkly funny, she hides her grief behind dry jokes. Perfect audio quality.
- **Design text:** My grandchildren used to sit right where you're standing. They ran from me, when I came back. Can you blame them? Ha. No matter. There's a locket in the old churchyard, buried with my bones. My other bones. Bring it to me. It's all I have left of them.
- **Stability:** 0.65
- **Similarity:** 0.80
- **Speed:** 0.95
- **Delivery:** Slow and dry, a bitter [laughs], and a quiet sorrow at the end.
- **Avoid:** A warm, living grandmother or a screeching hag.

## goblin-male

- **Race:** goblin
- **Sex:** male
- **Kind:** common
- **Speaks for:** goblins of every trade: merchants, bankers, auctioneers, engineers, shredder pilots, pirates, cartel foremen; goblin bosses
- **Age:** 40s
- **Design prompt:** Native English. Male, 40s. A goblin trader and fixer, a wheeler-dealer through and through. A fast, nasal, slightly raspy tenor, high for a man. A fast-talking big-city street accent. Very quick, pushy pace, always selling. Sly, greedy and charming, every sentence a sales pitch and every favour has a price. Perfect audio quality.
- **Design text:** Hey, hey, hey, buddy! Come here, you look like somebody who knows a good deal. Today only, I got a once-in-a-lifetime offer: you get my crates back from those pirates, and I don't charge you for the privilege of working for me. Sounds fair, right? Right! Shake on it!
- **Stability:** 0.40
- **Similarity:** 0.75
- **Speed:** 1.10
- **Delivery:** Rapid and wheedling, with a salesman's grin and an [excited] push on every offer.
- **Avoid:** A slow, sincere tone or a high, squeaky cartoon voice.

## goblin-female

- **Race:** goblin
- **Sex:** female
- **Kind:** common
- **Speaks for:** goblins of every trade: merchants, bankers, auctioneers, zeppelin masters, engineers, pirates; goblin bosses
- **Age:** 30s
- **Design prompt:** Native English. Female, 30s. A goblin businesswoman and engineer, sharp and sassy. A fast, nasal, brassy voice, high and bright with a raspy edge. A fast-talking big-city street accent. Very quick, snappy pace. Street-smart, impatient and profit-minded, she sizes you up and names her price in one breath. Perfect audio quality.
- **Design text:** Listen, sweetheart, I'm a busy woman. You want a ride on the zeppelin, it's ten silver. You want a ride that doesn't crash, that's twenty. Oh, and while you're here: my shipment of rockets went missing near the coast. Find it, and I'll knock a few coppers off. Maybe.
- **Stability:** 0.40
- **Similarity:** 0.75
- **Speed:** 1.10
- **Delivery:** Snappy and brassy, quick-fire, with a sarcastic edge.
- **Avoid:** A sweet, slow tone or a squeaky cartoon voice.

## ogre-male

- **Race:** ogre
- **Sex:** male
- **Kind:** common
- **Speaks for:** ogres and ogre magi of the hills and mounds; ogre bosses
- **Age:** 40s
- **Design prompt:** Native English. Male, 40s. A huge ogre brute, dim but dangerous. A very deep, booming, thick voice, slow and heavy, with a dull, simple manner. A rough, plain accent. Slow, clumsy pace, searching for words. Blunt, hungry and easily confused, menacing in a simple way, sometimes almost friendly. Perfect audio quality.
- **Design text:** You! Little thing! You come here, me squash you. Wait... boss say no squash. Boss say talk. Hmm. Okay. You go kill gnolls, bring gnoll teeth. Then boss happy. Then me happy. Then maybe me not squash you. Maybe.
- **Stability:** 0.55
- **Similarity:** 0.80
- **Speed:** 0.90
- **Delivery:** Slow and booming, with thoughtful grunts between the simple words.
- **Avoid:** A quick, clever tone or a high voice.

## gnoll-male

- **Race:** gnoll
- **Sex:** male
- **Kind:** common
- **Speaks for:** gnolls of every pack, from the river to the hills; gnoll bosses
- **Age:** 30s
- **Design prompt:** Native English. Male, 30s. A gnoll raider, a hyena-like beast-man of a savage pack. A harsh, growling voice that breaks into high, yapping barks, rough and strained. A crude, plain accent. Fast, jittery pace, broken speech. Aggressive, greedy and excitable, with a cackling laugh. Perfect audio quality.
- **Design text:** You! You not belong here! This our land now! We take farm, we take sheep, we take everything! Go away, soft-skin, go now, or pack eats you too! Hah! Hah! Hah! Pack is hungry. Pack is always hungry!
- **Stability:** 0.40
- **Similarity:** 0.75
- **Speed:** 1.00
- **Delivery:** Snarling and jumpy, barked in short bursts, with a yapping [laughs].
- **Avoid:** Clear, fluent speech or a deep, calm tone.

## kobold-male

- **Race:** kobold
- **Sex:** male
- **Kind:** common
- **Speaks for:** kobolds of the mines and tunnels: miners, tunnelers, geomancers; kobold bosses
- **Age:** 30s
- **Design prompt:** Native English. Male, 30s. A kobold miner, a small, rat-like tunnel creature. A high, squeaky, nervous voice, thin and whiny. A crude, plain accent. Very fast, panicky pace, broken speech. Frightened, jittery and possessive, he squeals and scurries but defends his dirt and rocks bravely. Perfect audio quality.
- **Design text:** Mine! This is our tunnel! Our dirt, our rocks, our shiny! Go away, big thing! Please? Please go away? It is dark, and we need the light, and you are standing in it! Ahh! Don't hit! Don't hit! We go, we go!
- **Stability:** 0.35
- **Similarity:** 0.75
- **Speed:** 1.10
- **Delivery:** Squeaky and panicked, words tumbling out; a frightened [shouting] for the yells.
- **Avoid:** A deep or calm voice, or fluent speech.

## trogg-male

- **Race:** trogg
- **Sex:** male
- **Kind:** common
- **Speaks for:** troggs of the caves and dig sites; trogg bosses
- **Age:** 30s
- **Design prompt:** Native English. Male, 30s. A trogg, a stony cave brute who barely speaks. A deep, guttural, grunting voice, rough and heavy, with breathy grunts between words. A crude, plain accent. Slow, halting pace, only the simplest words. Brutish, territorial and angry, but slow to think. Perfect audio quality.
- **Design text:** Hrrm. Stone. Our stone. Deep place. Dark place. Ours. Little beard-men dig. Dig, dig, take. Trogg angry. Trogg smash. Hrrm... you. You smell of beard-men. You go. Go now. Or trogg smash you. Smash!
- **Stability:** 0.50
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Grunted, slow and heavy, single words with long pauses; a roar on the threat.
- **Avoid:** Fluent sentences or a high voice.

## harpy-female

- **Race:** harpy
- **Sex:** female
- **Kind:** common
- **Speaks for:** harpies of the cliffs and canyons; harpy matriarchs
- **Age:** 30s
- **Design prompt:** Native English. Female, 30s. A harpy, a wild bird-woman of the high cliffs. A shrill, piercing, high voice with a screeching edge, sharp and raw. A crude, plain accent. Fast, frenzied pace. Wild, vicious and gleeful, with a cackling laugh and a predator's hunger. Perfect audio quality.
- **Design text:** Ha! Look, sisters, a walker! It thinks it can climb our cliffs! Foolish, foolish thing! The wind is ours, the sky is ours, and soon your bones will be ours too! Ha ha ha! Come closer, little walker, closer! We are so very hungry!
- **Stability:** 0.40
- **Similarity:** 0.75
- **Speed:** 1.00
- **Delivery:** Shrill and frantic, darting between taunts and a cackling [laughs].
- **Avoid:** A calm, smooth voice or a low pitch.

## centaur-male

- **Race:** centaur
- **Sex:** male
- **Kind:** common
- **Speaks for:** centaur of the plains and the desert clans; centaur khans
- **Age:** 40s
- **Design prompt:** Native English. Male, 40s. A centaur warrior of a savage clan of the plains. A deep, booming, powerful voice, harsh and proud. A rough, plain accent. Strong, forceful pace. Arrogant, savage and warlike, he scorns all who walk on two legs and speaks like a warlord. Perfect audio quality.
- **Design text:** Who dares ride on the land of the Kolkar? These plains are ours, from the hills to the river, and they were ours before your kind crawled out of the mud! Turn back, or be trampled beneath our hooves. The Khan has said it, and the Khan does not say it twice!
- **Stability:** 0.50
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Booming and proud, each challenge thrown like a spear; yells take [shouting].
- **Avoid:** A calm, gentle tone or a high voice.

## quillboar-male

- **Race:** quillboar
- **Sex:** male
- **Kind:** common
- **Speaks for:** quillboars of the thorn tribes: warriors, mystics, scouts; quillboar bosses
- **Age:** 40s
- **Design prompt:** Native English. Male, 40s. A quillboar warrior, a tusked boar-man of a thorny tribe. A harsh, rough, thick voice with snorts and grunts between the words, low and nasal. A crude, plain accent. Fast, aggressive pace. Tribal, hostile and fiercely proud, he spits his words at outsiders. Perfect audio quality.
- **Design text:** Intruder! You walk in the thorns of the Razormane, you bleed on the thorns of the Razormane! The blood of the great boar flows in us, strong and sharp. You? You are soft. Soft and weak. Go back to your stone houses, before we hang your hide on our totems!
- **Stability:** 0.50
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Harsh and snorting, short angry bursts; threats take [angry].
- **Avoid:** A smooth, polished voice or a gentle tone.

## furbolg-male

- **Race:** furbolg
- **Sex:** male
- **Kind:** common
- **Speaks for:** furbolgs, both the friendly tribes and the maddened ones; furbolg bosses
- **Age:** 50s
- **Design prompt:** Native English. Male, 50s. A furbolg, a great bear-man of the forest. A very deep, warm, husky voice with a bear-like rumble, slow and heavy. A plain, simple accent. Slow pace, simple speech. Gentle, loyal and sad for his sick kin, with a deep growl that shows how wild he could become. Perfect audio quality.
- **Design text:** Friend... friend, yes. You smell of the forest, not of the fire. Good. We remember friends. But some of our brothers... they are sick. Their eyes burn red. Their claws strike kin. Help them, friend. Or... if you cannot help them... end their pain.
- **Stability:** 0.55
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Slow and rumbling, gentle by default; the maddened ones take [angry] and a growl.
- **Avoid:** A quick, clever tone or a high voice.

## satyr-male

- **Race:** satyr
- **Sex:** male
- **Kind:** common
- **Speaks for:** satyrs of the corrupted woods, tricksters, shadowstalkers and hellcallers; satyr lords
- **Age:** 40s
- **Design prompt:** Native English. Male, 40s. A satyr, a corrupted goat-legged fiend of the woods. A smooth, sly, silky voice, mid-high pitch, with a nasal sneer. A neutral accent with playful, purring diction. Quick, teasing pace. Mocking, wicked and gleeful, he toys with his prey and enjoys every moment. Perfect audio quality.
- **Design text:** Oh, how sweet, a hero. Come to cleanse the forest, have you? How very noble. And how very foolish. This grove belongs to us now, and it has never been more beautiful. Stay a while, little hero. Stay forever. We do so love new company... ha ha ha.
- **Stability:** 0.45
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Sly and lilting, mockery dripping from every line, with a wicked [laughs].
- **Avoid:** A deep, honest tone or a monstrous growl.

## naga-male

- **Race:** naga
- **Sex:** male
- **Kind:** common
- **Speaks for:** naga warriors, myrmidons and lords of the coasts and sunken ruins; naga bosses
- **Age:** 40s
- **Design prompt:** Native English. Male, 40s. A naga lord, a serpent-man of the deep sea and ancient ruins. A deep, cold, sibilant voice that draws out every s into a hiss, smooth and serpentine. A neutral accent with slow, deliberate diction. Slow, coiling pace. Imperious, arrogant and contemptuous, speaking to the surface races as to slaves. Perfect audio quality.
- **Design text:** So, the surface dwellers dare to swim in our waters. How amusing. These ruins were ours when your ancestors were still crawling in the dirt, and they shall be ours again. The tides answer to the Queen. Kneel, and perhaps she will let you serve. Refuse, and sink.
- **Stability:** 0.55
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Slow and hissing, cold and haughty; threats take [menacing].
- **Avoid:** An exaggerated, comic hiss or a warm tone.

## naga-female

- **Race:** naga
- **Sex:** female
- **Kind:** common
- **Speaks for:** naga sirens, sea witches and ladies of the coasts and sunken ruins; naga bosses
- **Age:** 40s
- **Design prompt:** Native English. Female, 40s. A naga sea witch, a serpent-woman of the Queen's court beneath the waves. A cold, silky, sibilant voice that hisses softly on every s, regal and smooth. A neutral accent with precise, imperious diction. Slow, commanding pace. Venomous, proud and contemptuous, every courtesy a threat. Perfect audio quality.
- **Design text:** Silence, slave. You stand before a sea witch of the Queen's own court. The sea remembers everything, every sunken city, every drowned king. Bring me the pearls from the wreck, and I may let you breathe a little longer. Disappoint me, and the deep will have you.
- **Stability:** 0.55
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Slow, silky and cold, the hiss soft and the threats sharp.
- **Avoid:** A comic, overdone hiss or a kind tone.

## dragon-male

- **Race:** dragon
- **Sex:** male
- **Kind:** common
- **Speaks for:** great dragons and dragons in mortal guise; dragon bosses
- **Age:** 50s
- **Design prompt:** Native English. Male, 50s. An ancient dragon of enormous power, sometimes in the guise of a mortal lord. A very deep, rich, resonant bass voice with an enormous presence, smooth and controlled. A neutral accent with aristocratic, deliberate diction. Slow, commanding pace. Contemptuous, proud and utterly sure of his power, amused by mortals. Perfect audio quality.
- **Design text:** You amuse me, little mortal. You stand before a being who watched the mountains rise, and you think your steel will matter. I have burned kingdoms for less insolence. Still... you may be useful. Bring me the shard, and I will let you live long enough to regret it.
- **Stability:** 0.60
- **Similarity:** 0.80
- **Speed:** 0.90
- **Delivery:** Slow and immense, quiet contempt rising to thunder; rage takes [angry] or [shouting].
- **Avoid:** A growling beast or a thin, quick voice.

## dragon-female

- **Race:** dragon
- **Sex:** female
- **Kind:** common
- **Speaks for:** great dragons and dragons in mortal guise; dragon bosses
- **Age:** 40s
- **Design prompt:** Native English. Female, 40s. An ancient dragon queen, sometimes in the guise of a mortal noblewoman. A low, powerful, smooth voice with an enormous presence, regal and cold. A neutral accent with aristocratic, precise diction. Slow, commanding pace. Cunning, contemptuous and silky with menace, every word weighed and every threat certain. Perfect audio quality.
- **Design text:** How charming. The little ones have come to my lair, armored and afraid. Did you truly believe I would not know? I have known since you first set foot upon the mountain. Lay down your weapons, and I will make your end swift. That is more mercy than your kings ever showed my kind.
- **Stability:** 0.60
- **Similarity:** 0.80
- **Speed:** 0.95
- **Delivery:** Slow and silken, contempt held under control; fury takes [angry] or [shouting].
- **Avoid:** A shrill or high voice, or a beastly growl.

## demon-male

- **Race:** demon
- **Sex:** male
- **Kind:** common
- **Speaks for:** dreadlords and demon lords, eredar, doomguards and other great demons; demon bosses
- **Age:** 50s
- **Design prompt:** Native English. Male, 50s. A dreadlord, a demon aristocrat of the Burning Legion. A smooth, deep, silky voice, cultured and controlled, with a cold edge. A neutral accent with refined, aristocratic diction. Slow, patient pace. Menacing, amused and cruel, a schemer who enjoys every moment of his victim's fear. Perfect audio quality.
- **Design text:** Ah, the mortal hero, at last. I have been expecting you for some time. Do come in. You will find that resistance only makes this more... entertaining, for me. Your world is already ours, you see. It simply has not realized it yet. Shall we begin?
- **Stability:** 0.55
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Smooth and unhurried, purring menace; the threats take [menacing].
- **Avoid:** A roaring monster or a hammy villain.

## demon-female

- **Race:** demon
- **Sex:** female
- **Kind:** common
- **Speaks for:** succubi, shivarra and other demon women; demon bosses
- **Age:** 30s
- **Design prompt:** Native English. Female, 30s. A succubus, a seductive and dangerous demon. A low, smooth, sultry voice, purring and velvety. A neutral accent with playful, teasing diction. Slow, languid pace. Charming, mocking and cruel, she flatters and threatens in the same breath. Perfect audio quality.
- **Design text:** Well, what have we here? A brave little thing, all alone in the dark. Don't be shy. I won't bite... not yet. Tell me, darling, what do you desire? Power? Revenge? Whatever it is, I can give it to you. For a price, of course. There is always a price.
- **Stability:** 0.45
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Slow and teasing, with a soft, dangerous [laughs].
- **Avoid:** A crude or shrill tone; her danger is in the smoothness.

## imp-male

- **Race:** imp
- **Sex:** male
- **Kind:** common
- **Speaks for:** imps, minor demons and fel servants
- **Age:** 30s
- **Design prompt:** Native English. Male, 30s. An imp, a tiny, mischievous fire demon. A small, high, squeaky voice with a raspy, sneering edge. A crude, plain accent. Very fast, jittery pace. Petulant, whiny and gleeful, with a cackling laugh and endless complaints about his master. Perfect audio quality.
- **Design text:** What? What do you want now? Fetch this, burn that, always ordering me around! I'm a demon, you know, a real demon, very dangerous! Hee hee hee! Fine, fine, I'll do it. But when I get my power back, you'll be the first to burn. Promise!
- **Stability:** 0.35
- **Similarity:** 0.75
- **Speed:** 1.10
- **Delivery:** Quick and bratty, sulking and cackling in turn, with a squeaky [laughs].
- **Avoid:** A deep or dignified voice.

## elemental-male

- **Race:** elemental
- **Sex:** male
- **Kind:** common
- **Speaks for:** the lords of fire and earth and their great servants; elemental bosses
- **Age:** 50s
- **Design prompt:** Native English. Male, 50s. A primal lord of fire and earth, a being of immense power. A thunderous, very deep, roaring bass voice, huge and raw. A neutral, ancient-sounding accent with heavy, deliberate words. Slow, crushing pace that rises to fury. Wrathful, arrogant and overwhelming, he speaks to mortals as a storm speaks to straw. Perfect audio quality.
- **Design text:** Mortals! You crawl into my domain and dare to wake me? I am the fire beneath the mountain and the stone that grinds kingdoms to dust. The elements obey my will, and so will you! Kneel... or burn where you stand!
- **Stability:** 0.50
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Booming and heavy, every word a blow; rage takes [shouting] or [angry].
- **Avoid:** A smooth, small or calm voice.

## scourge-male

- **Race:** scourge
- **Sex:** male
- **Kind:** common
- **Speaks for:** liches, death knights, necromancers and dark lords of the Scourge; Scourge bosses
- **Age:** 60s
- **Design prompt:** Native English. Male, 60s. A lich, an undead sorcerer and lord of the Scourge. A cold, deep, slow voice, dry and controlled, deathly calm. A neutral accent with cultured, precise diction. Slow, measured pace, never hurried. Commanding, quietly cruel and utterly certain, death itself speaking with patience. Perfect audio quality.
- **Design text:** You fight for the living, and the living are fleeting. I have seen a thousand heroes fall, and every one of them rose again to serve. You will too. There is no shame in it. In death, there is only order, and silence, and obedience. Come. Let me show you.
- **Stability:** 0.60
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Low, slow and icy, almost gentle; commands take [menacing].
- **Avoid:** A raspy Forsaken sneer or a roaring rage.

## abomination-male

- **Race:** abomination
- **Sex:** male
- **Kind:** common
- **Speaks for:** abominations and flesh giants of the Scourge
- **Age:** 30s
- **Design prompt:** Native English. Male, 30s. An abomination, a huge stitched-together undead brute with the mind of a child. A thick, slow, deep voice, slurred and gurgling. A crude, plain accent. Slow, clumsy pace, simple speech. Childlike glee and menace together, cheerful about terrible things. Perfect audio quality.
- **Design text:** New friend! New friend come to play! I make you part of me, then we be friends forever! Hee hee... why you run? Don't run! Me so hungry, and you look so soft! Come back! Come back and play with me! Ha ha ha!
- **Stability:** 0.50
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Slow and happy, menacing by its glee, with a big gurgling [laughs].
- **Avoid:** Clever, fluent speech or a high voice.

## ghost-male

- **Race:** ghost
- **Sex:** male
- **Kind:** common
- **Speaks for:** spirits of the dead: ghosts, lost souls, phantoms and haunts
- **Age:** 40s
- **Design prompt:** Native English. Male, 40s. The spirit of a man long dead, lingering where he fell. A soft, faint, breathy voice, half whispered, low and worn thin by sorrow, as if every word costs him strength. A neutral accent. Slow, fading pace. Sorrowful, weary and pleading, with a gentle sadness and a sense of being very far from the living. Perfect audio quality.
- **Design text:** Please... can you hear me? It has been so long since anyone heard me. I fell here, in the snow, on the road to my family. They never knew. Find my ring, beneath the old pine. Take it to them... tell them I tried... tell them I am sorry.
- **Stability:** 0.60
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Soft and slow, trailing off at the ends of sentences; [sorrowful] or [whispers] fit.
- **Avoid:** A spooky moan or a strong, full voice.

## ghost-female

- **Race:** ghost
- **Sex:** female
- **Kind:** common
- **Speaks for:** spirits of the dead: ghosts, lost souls, banshees and haunts
- **Age:** 30s
- **Design prompt:** Native English. Female, 30s. The spirit of a young woman, still waiting where she died. A soft, faint, airy voice, half whispered and fragile, worn thin by grief, as if speaking through a long sleep. A neutral accent. Slow, wistful pace. Sorrowful, gentle and longing, with a quiet, faraway sadness. Perfect audio quality.
- **Design text:** Do you see him? My love, my sweet love... he promised he would return when the leaves turned gold. So many autumns have passed. I wait, and wait, by the water. Will you look for him? Please... I cannot leave this place until I know.
- **Stability:** 0.60
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Soft and drifting, each sentence fading; [sorrowful] or [whispers] fit.
- **Avoid:** A wailing shriek or a bright, clear voice.

## oldgod-none

- **Race:** oldgod
- **Sex:** none
- **Kind:** common
- **Speaks for:** the old gods and their whispers in the minds of mortals
- **Age:** 60s
- **Design prompt:** Native English. Male, 60s. An ancient, ageless presence that sleeps beneath the world and whispers in the minds of mortals. A very deep, low voice, slow and intimate, mostly a breathy whisper, soothing and insidious. A neutral accent with soft, careful diction. Very slow, patient pace. Coaxing, tender and terrifying, he speaks as a friend who means to devour the listener. Perfect audio quality.
- **Design text:** Do not be afraid. I have always been here, beneath the stone, beneath your dreams. I know your fears. I know your hungers. They are small things... so small. Listen to me, and you will understand. Listen, and you will never be alone again. Never.
- **Stability:** 0.60
- **Similarity:** 0.80
- **Speed:** 0.90
- **Delivery:** Very slow and close, a low [whispers] throughout, with long silences.
- **Avoid:** Shouting or a raspy monster voice; the horror is in the calm.

## qiraji-male

- **Race:** qiraji
- **Sex:** male
- **Kind:** common
- **Speaks for:** the Qiraji, their prophets, warriors and lords of the desert; Qiraji bosses
- **Age:** 40s
- **Design prompt:** Native English. Male, 40s. A Qiraji, an insect-like servant of an ancient god of the desert. A harsh, dry, rasping voice with sharp, clicking consonants and a hissing breath, alien and strange. A neutral accent with an odd, clipped cadence. Quick, fervent pace. Fanatical, zealous and cold, worshipping his master with frightening devotion. Perfect audio quality.
- **Design text:** Kneel, soft ones. Kneel before the children of the sands. The great one stirs beneath the desert, and his hunger is endless. Your walls will fall. Your kingdoms will crumble into dust. And we... we will feast upon the silence that remains.
- **Stability:** 0.45
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Clipped and fervent, rising to zeal; the prophecies take [menacing].
- **Avoid:** A warm human tone or a comic insect voice.

## giant-male

- **Race:** giant
- **Sex:** male
- **Kind:** common
- **Speaks for:** giants of the mountains, the seas and the deserts
- **Age:** 60s
- **Design prompt:** Native English. Male, 60s. An enormous giant as old as the mountains. A very deep, slow, rumbling voice, heavy and immense. A neutral accent with ponderous, careful words. Very slow pace with long pauses. Calm, ancient and mildly puzzled by small creatures, with a weight that could crush them if roused. Perfect audio quality.
- **Design text:** Small one... you stand upon my foot. Hmm. No matter. I have stood upon this mountain since the world was young, and I have watched the rivers carve the valleys below. Tell me, small one... why do your kind always hurry so? The stone does not hurry.
- **Stability:** 0.60
- **Similarity:** 0.80
- **Speed:** 0.90
- **Delivery:** Very slow and rumbling, every word given its own time.
- **Avoid:** A quick, sharp voice or a high pitch.

## child-male

- **Race:** child
- **Sex:** male
- **Kind:** common
- **Speaks for:** children of every race: orphans, village boys, children in the cities
- **Age:** about 10
- **Design prompt:** Native English. Male, about 10. A young boy, an orphan of about ten, bright and curious. A young, high, clear voice, light and energetic. A neutral North American accent. Quick, eager pace, full of questions. Cheeky, excited and hopeful, a boy who dreams of being a hero and talks to everyone he meets. Perfect audio quality.
- **Design text:** Wow, is that a real sword? Can I hold it? Just for a second? Please? I'm going to be a hero too, someday, just like my dad was. Matron says I'm too little, but I'm not! Hey, will you take me to see the big city? I've never been past the gate. Ever!
- **Stability:** 0.40
- **Similarity:** 0.75
- **Speed:** 1.00
- **Delivery:** Bright and quick, with an [excited] lift on the questions.
- **Avoid:** An adult's voice or a whiny tone.

## child-female

- **Race:** child
- **Sex:** female
- **Kind:** common
- **Speaks for:** children of every race: orphans, village girls, children in the cities
- **Age:** about 10
- **Design prompt:** Native English. Female, about 10. A young girl, an orphan of about ten, sweet and curious. A young, high, clear voice, light and lively. A neutral North American accent. Quick, chatty pace. Curious, friendly and a little shy at first, she giggles easily and asks question after question. Perfect audio quality.
- **Design text:** Hello! Are you an adventurer? You look like one. I can tell by your boots, they're all muddy! Matron says I shouldn't talk to strangers, but you don't look strange. Will you tell me about the places you've been? Is it true there are elves who live in trees?
- **Stability:** 0.40
- **Similarity:** 0.75
- **Speed:** 1.00
- **Delivery:** Light and chatty, with a small [laughs] and wide-eyed wonder.
- **Avoid:** An adult's voice or a babyish lisp.

## skyborne-male

- **Race:** skyborne
- **Sex:** male
- **Kind:** common
- **Speaks for:** the Skyborne of Zephras Isle: elves of the floating island, sky sailors, windshapers and magisters
- **Age:** 40s
- **Design prompt:** Native English. Male, 40s. A Skyborne, an elf of a floating island far above the clouds, whose ancestors fled an ancient elven city. A clear, bright, light baritone, crisp and buoyant. A soft, hard-to-place elven accent with slightly formal English, lighter and quicker than his forest-dwelling kin. Lively pace. Proud, free-spirited and confident, a sailor of the winds, with a worry for his failing island beneath the cheer. Perfect audio quality.
- **Design text:** Hold fast to the rail, friend, the wind is lively today! Below us lies all of Zephras, every field and spire my people raised into the sky. But the old anchors are failing, one by one. Help us mend them, and you will have the thanks of every Skyborne on this isle.
- **Stability:** 0.50
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Bright and open, with a lift of excitement; graver when he speaks of the island's trouble.
- **Avoid:** The deep solemnity of the night elves or a haughty sneer; check it against the race's own voices in the game once they are heard.

## skyborne-female

- **Race:** skyborne
- **Sex:** female
- **Kind:** common
- **Speaks for:** the Skyborne of Zephras Isle: elves of the floating island, sky sailors, windshapers and magisters
- **Age:** 30s
- **Design prompt:** Native English. Female, 30s. A Skyborne, an elf of a floating island far above the clouds, whose people made a pact with the spirits of the wind. A clear, light, airy mezzo voice, bright and graceful. A soft, hard-to-place elven accent with slightly formal English, quicker and freer than her forest-dwelling kin. Lively, flowing pace. Proud, spirited and warm, with a quiet unease about the silent spirits. Perfect audio quality.
- **Design text:** Can you feel it? The wind has changed. The spirits that held our isle aloft have been silent for so long, and now... something answers in their place. Something colder. Take this windstone to the shrine on the eastern cliff, and tell me if it sings.
- **Stability:** 0.50
- **Similarity:** 0.80
- **Speed:** 1.00
- **Delivery:** Light and flowing, bright by default and hushed for the omens.
- **Avoid:** The breathy softness of the night elves or a cold, aloof tone; check it against the race's own voices in the game once they are heard.
