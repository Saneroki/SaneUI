-- Abilities' full screen with Sane Macros and the action bars as windows: Core and Abilities from their TOCs, the game's
-- action bars standing in (the lab has none), four wide ones stacked and touching and a tall one. Drag a macro from
-- the list onto a bar.
-- In the console LabMacros is the module's table, LabBars.Full() brings the full screen again.
for _, name in ipairs({ "PlayerFrame", "TargetFrame", "FocusFrame", "PetFrame", "PlayerCastingBarFrame",
                        "OverlayPlayerCastingBarFrame", "MirrorTimerContainer", "PartyFrame", "CompactRaidFrameContainer" }) do
    CreateFrame("Frame", name, UIParent)
end
local create = CreateFrame
CreateFrame = function(kind, name, parent, template, ...)
    if template == "SecureGroupHeaderTemplate" then template = nil end -- not in the lab
    local frame = create(kind, name, parent, template, ...)
    -- Abilities' Bar 1 hands its buttons to a secure handler (Bar1.lua): the lab keeps no references.
    if type(template) == "string" and template:find("SecureHandler") and not frame.SetFrameRef then
        frame.SetFrameRef = function() end
    end
    return frame
end
SecureHandlerSetFrameRef = function() end
RegisterUnitWatch, UnregisterUnitWatch = function(frame) frame:Show() end, function() end
RegisterStateDriver, UnregisterStateDriver = function() end, function() end
ClearOverrideBindings, SetOverrideBinding, SetOverrideBindingClick = function() end, function() end, function() end
SecureCmdOptionParse = function() return nil end
GetBindingKey = function() end

-- The game's bars: frames that know their size, each with its twelve buttons.
local function Bar(name, prefix, across, rows, x, y)
    local bar = CreateFrame("Frame", name, UIParent)
    bar:SetSize(across * 40, rows * 40)
    bar:SetPoint("BOTTOM", UIParent, "BOTTOM", x, y)
    bar.actionButtons = {}
    for index = 1, 12 do
        local button = CreateFrame("Button", prefix .. index, bar)
        button:SetSize(36, 36)
        local column, row = (index - 1) % across, math.floor((index - 1) / across)
        button:SetPoint("TOPLEFT", bar, "TOPLEFT", column * 40 + 2, -row * 40 - 2)
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetColorTexture(0.3, 0.26, 0.18, 1)
        bar.actionButtons[index] = button
    end
    bar:Show()
    return bar
end
Bar("MainActionBar", "ActionButton", 12, 1, 0, 8)
Bar("MultiBar7", "MultiBar7Button", 12, 1, 0, 48)
Bar("MultiBar6", "MultiBar6Button", 12, 1, 0, 88)
Bar("MultiBar5", "MultiBar5Button", 12, 1, 0, 128)
Bar("MultiBarRight", "MultiBarRightButton", 1, 12, 600, 100)

-- Two of the game's macros, marked W under yours.
GetNumMacros = function() return 2, 0 end
GetMacroInfo = function(index)
    if index == 1 then return "Mount", 132261, "/use Horse" end
    if index == 2 then return "Hearth", 134414, "/use Hearthstone" end
end

Lab.TOC("src/Core/SaneUI.toc")
-- A part of Core's set Icons, as the compiler writes it (rows of the real set): Sane Macros' picture window.
do
    local S = SaneUI.Core.Data.Add(1, "Icons", { game = "forever", hash = "00000000", build = 0, key = "int",
        fields = { "name", "classes", "spells", "items", "itemClasses" },
        types = { "text", "list int", "list int", "list int", "list int" }, patches = {} })
    for key, row in pairs({
    [132333] = "0\t\tAbility_Warrior_BattleShout\t1\t5242\03012318",
    [132334] = "0\t\tAbility_Warrior_BloodFrenzy\t1\t1329555",
    [132335] = "0\t\tAbility_Warrior_BullRush",
    [132336] = "0\t\tAbility_Warrior_Challange\t1\0303\0304\t12327\03014251\03019306\03020230",
    [132337] = "0\t\tAbility_Warrior_Charge\t1\t100\03012285",
    [132338] = "0\t\tAbility_Warrior_Cleave\t1\t845\03012329",
    [132339] = "0\t\tAbility_Warrior_CommandingShout",
    [132340] = "0\t\tAbility_Warrior_DecisiveStrike\t1\0304\t1464\03012862\03014179",
    [132341] = "0\t\tAbility_Warrior_DefensiveStance\t1\t71\0307376",
    [132342] = "0\t\tAbility_Warrior_Devastate\t1\t402927",
    [132343] = "0\t\tAbility_Warrior_Disarm\t1\t676\03012313",
    [132344] = "0\t\tAbility_Warrior_EndlessRage",
    [132345] = "0\t\tAbility_Warrior_FocusedRage\t\t29787",
    [132346] = "0\t\tAbility_Warrior_ImprovedDisciplines",
    [132347] = "0\t\tAbility_Warrior_InnerRage\t1\0302\t12792\03020375",
    [132348] = "0\t\tAbility_Warrior_Intervene",
    [132349] = "0\t\tAbility_Warrior_OffensiveStance\t1\t2457\03021156",
    [132350] = "0\t\tAbility_Warrior_PunishingBlow\t1\0304\t694\03013877",
    [132112] = "0\t\tAbility_Druid_AquaticForm\t11\t1066\0305421",
    [132113] = "0\t\tAbility_Druid_BalanceofPower",
    [132114] = "0\t\tAbility_Druid_Bash\t11\t5211\03016940",
    [132115] = "0\t\tAbility_Druid_CatForm\t11\t768\0303025",
    [132116] = "0\t\tAbility_Druid_CatFormAttack\t\t\t276338\t2",
    [132117] = "0\t\tAbility_Druid_ChallangingRoar\t11\t5209",
    [132118] = "0\t\tAbility_Druid_Cower\t3\03011\t1513\0301747",
    [132119] = "0\t\tAbility_Druid_Cyclone\t\t\t232454\030274030\030221262\t7\03015",
    [132120] = "0\t\tAbility_Druid_Dash\t3\03011\t1850\03019596",
    [132121] = "0\t\tABILITY_DRUID_DEMORALIZINGROAR\t3\03011\t99\03016858\03019578\t3476\030278098\t12",
    [132122] = "0\t\tAbility_Druid_Disembowel\t4\03011\t1822\03014156\t254859\t12",
    [132123] = "0\t\tAbility_Druid_Dreamstate",
    [136006] = "0\t\tSpell_Nature_AbolishMagic\t3\0308\03011\t604\0305176\03012606\03016814\03019590\t21180\03012803\0309313\0309365\03013320\030288337\t0\0304\0307\03012",
    [136007] = "0\t\tSpell_Nature_Acid_01\t\t\t7080\03011514\t7\03012",
    [136008] = "0\t\tSpell_Nature_AgitatingTotem\t\t\t210253\030276893\t0\03012",
    [136009] = "0\t\tSpell_Nature_AncestralGuardian\t1\t18499\03020500",
    [136010] = "0\t\tSpell_Nature_AstralRecal\t7\t556",
    [136011] = "0\t\tSpell_Nature_AstralRecalGroup\t8\t29441\t9596\03012804\t7\03012",
    [136012] = "0\t\tSpell_Nature_BloodLust\t1\0307\t23881\030425336",
    [136013] = "0\t\tSpell_Nature_Brilliance",
    [136014] = "0\t\tSpell_Nature_CallStorm\t7\t16120",
    [136015] = "0\t\tSpell_Nature_ChainLightning\t7\t421",
    [136016] = "0\t\tSpell_Nature_CorrosiveBreath\t\t\t6464\t0",
    [136017] = "0\t\tSpell_Nature_CrystalBall\t11\t16864\t273027\t4",
    [136018] = "0\t\tSpell_Nature_Cyclone\t7\03011\t8232\03016914\t7081\0309597\t7\03012",
    [136019] = "0\t\tSpell_Nature_DiseaseCleansingTotem\t7\t8170",
    [136020] = "0\t\tSpell_Nature_Drowsy\t3\t19801",
    [136021] = "0\t\tSpell_Nature_DryadDispelMagic",
    [132282] = "0\t\tAbility_Rogue_Ambush\t1\0302\0304\t78\0308676\03012282\03014079\03020189",
    [132283] = "0\t\tAbility_Rogue_BladeTwisting",
    [132284] = "0\t\tAbility_Rogue_BloodyEye",
    [132285] = "0\t\tAbility_Rogue_CheatDeath",
    [132286] = "0\t\tAbility_Rogue_DeadenedNerves",
    [132287] = "0\t\tAbility_Rogue_Disembowel",
    [132288] = "0\t\tAbility_Rogue_Disguise\t\t\t206159\t12",
    [132289] = "0\t\tAbility_Rogue_Distract\t4\t1725\03014084",
    [135868] = "0\t\tSpell_Holy_Absolution",
    [135869] = "0\t\tSpell_Holy_ArcaneIntellect\t8\t23028",
    [135870] = "0\t\tSpell_Holy_ArdentDefender",
    [135871] = "0\t\tSpell_Holy_AshesToAshes\t1\t12975",
    [135872] = "0\t\tSpell_Holy_AuraMastery",
    [135873] = "0\t\tSpell_Holy_AuraOfLight\t2\t7294\03020091",
    [135874] = "0\t\tSpell_Holy_AvengersShield",
    [135875] = "0\t\tSPELL_HOLY_AVENGINEWRATH",
    [135271] = "0\t\tINV_Sword_01\t\t1289682\t17142\03013053\03022228\t2\03012",
    [135272] = "0\t\tINV_Sword_02\t\t\t1982\0303822\0304468\03011723\t2\03012",
    [135273] = "0\t\tINV_Sword_03\t\t\t13044\0306174\0307170\t2",
    [135274] = "0\t\tINV_Sword_04\t\t\t727\0302850\0303572\0304567\0306967\0306984\t2\03012",
    [135275] = "0\t\tINV_Sword_05\t1\t12290\t23456\03023467\030234553\030234579\030272684\030272859\t2",
    [135276] = "0\t\tINV_Sword_06\t\t\t5321\0309602\03015221\03018957\0301194\0302128\t2\03012",
    [135277] = "0\t\tINV_Sword_07\t\t\t18583\03018584\030279259\03012782\03013043\0301387\t2",
    [135278] = "0\t\tINV_Sword_08\t\t1311087\t2000\03015255\t2",
    [135279] = "0\t\tINV_Sword_09\t\t\t18488\030228696\030275916\t2\03012",
    [135280] = "0\t\tINV_Sword_10\t\t\t2801\0308190\0309718\0309719\0303209\0305813\t2\03015",
    [132392] = "0\t\tINV_Axe_01\t\t196\t20149\030273809\030274485\030826\0305459\0306979\t2\03012",
    [132393] = "0\t\tINV_Axe_02\t3\t19381\03020574\t870\03018828\030234554\030235476\030272592\0302299\t2",
    [132394] = "0\t\tINV_Axe_03\t\t\t9459\03012975\0307942\03015234\0302025\t2",
    [132395] = "0\t\tINV_Axe_04\t\t\t15424\030274430\030285328\0301639\0302073\0306966\t2",
    [132396] = "0\t\tINV_Axe_05\t\t17041\t12774\t2",
    [133068] = "0\t\tINV_Helmet128",
    [133069] = "0\t\tINV_Helmet_01\t\t\t21669\03012018\030220819\030220820\030220821\030220822\t4",
    [133070] = "0\t\tINV_Helmet_02\t\t\t21999\030226860\030226869\03012620\03016731\0301282\t4\03015",
    [133071] = "0\t\tINV_Helmet_03\t\t\t5819\03023251\030227067\030227080\030272491\0301624\t4",
    [133072] = "0\t\tINV_Helmet_04\t\t\t21360\03022097\03023020\030227002\030227013\030227021\t4",
    [133073] = "0\t\tINV_Helmet_05\t\t\t2245\03016465\03016474\03016478\030231538\030231562\t4",
    [132624] = "0\t\tINV_Chest_Chain\t\t\t1488\0301717\0303416\0303844\030271098\030914\t4",
    [132625] = "0\t\tINV_Chest_Chain_03\t\t\t16466\03022060\030226886\030231563\030231581\030272775\t4\03015",
    [132626] = "0\t\tINV_Chest_Chain_04\t\t\t21370\03015048\03016525\03022874\03023292\030227070\t4",
    [132627] = "0\t\tINV_Chest_Chain_05\t\t8737\t6642\030220826\030220827\030220828\030223078\0307538\t4",
    [132628] = "0\t\tINV_Chest_Chain_06\t\t\t13123\03015045\03015047\03016425\030272734\0301677\t4",
    [132629] = "0\t\tINV_Chest_Chain_07\t\t\t12641\0306972\0307133\0308367\03010328\030220844\t4",
    [134712] = "0\t\tINV_POTION_01\t\t6501\t737\0301970\0303828\0304030\0304823\0304941\t0\0304\03012",
    [134713] = "0\t\tINV_Potion_02\t\t\t2456\0304342\030274373\t0\0307\03012",
    [134714] = "0\t\tINV_Potion_03\t\t\t7070\03011412\03011413\t0\0307\03012",
    [134715] = "0\t\tINV_Potion_04\t\t\t5251\0305634\0307667\030287976\t0\03012",
    [134716] = "0\t\tINV_Potion_05\t\t\t6624\03018294\03022151\t0\03012",
    [134717] = "0\t\tINV_Potion_06\t\t\t2834\0303236\0303237\0303383\0303508\0306052\t0\03012",
    [134718] = "0\t\tINV_Potion_07\t\t\t223914\03018603\03020008\t0\03012",
    [134719] = "0\t\tINV_Potion_08\t\t\t18240\0302858\0303384\0305017\0305143\0305400\t0\0307\03012",
    [134720] = "0\t\tINV_Potion_09\t\t\t1450\0306051\03010290\03013460\030248930\t0\0307\03012",
    [134721] = "0\t\tINV_Potion_10\t\t\t223912\0305460\0305588\0305619\0305639\0305732\t0\03012",
    [133943] = "0\t\tINV_Misc_Food_01",
    [133944] = "0\t\tINV_Misc_Food_02\t\t\t2688\0303418\0304809\03012343\03016205\03016208\t0\03012\03015",
    [133945] = "0\t\tINV_Misc_Food_03\t\t\t3927\03017406\t0",
    [133946] = "0\t\tINV_Misc_Food_04",
    [133947] = "0\t\tINV_Misc_Food_05",
    [133948] = "0\t\tINV_MISC_FOOD_06\t\t\t2070\03012218\030252023\t0",
    [134561] = "0\t\tINV_Ore_Adamantium",
    [134562] = "0\t\tINV_Ore_Adamantium_01",
    [134563] = "0\t\tINV_Ore_Arcanite_01\t\t\t228191\t12",
    [134564] = "0\t\tINV_Ore_Arcanite_02\t\t\t8244\03011904\0304838\0304611\0305493\0306442\t4\0307\03012",
    [134565] = "0\t\tINV_Ore_Cobalt",
    [132887] = "0\t\tINV_Fabric_Felcloth_Ebon",
    [132888] = "0\t\tINV_Fabric_FelRag\t\t\t14256\t7",
    [132889] = "0\t\tINV_Fabric_Linen_01\t\t\t2589\030231903\0305122\t7\03012\03015",
    [132890] = "0\t\tINV_Fabric_Linen_02\t\t\t2996\03012293\t7\03012",
    [132224] = "0\t\tAbility_Mount_BlackDireWolf\t\t578\030579\030580\0306654\03022724\03023250\t12330\03018245\03018796\0301041\0301132\0305668\t15",
    [132225] = "0\t\tAbility_Mount_BlackPanther\t\t10787\03010792\03010793\03016055\03022723\03023219\t18242\0308629\030211498\03016304\0308627\0308628\t12\03015",
    [132226] = "0\t\tAbility_Mount_Charger\t\t23214\0301296534",
    [132227] = "0\t\tABILITY_MOUNT_COCKATRICEMOUNT",
    [132228] = "0\t\tABILITY_MOUNT_COCKATRICEMOUNT_BLACK",
    [132229] = "0\t\tABILITY_MOUNT_COCKATRICEMOUNT_BLUE",
    [236681] = "0\t\tAchievement_Reputation_01",
    [236682] = "0\t\tAchievement_Reputation_02",
    [236683] = "0\t\tAchievement_Reputation_03",
    [236684] = "0\t\tAchievement_Reputation_04",
    [236685] = "0\t\tAchievement_Reputation_05",
    [236686] = "0\t\tAchievement_Reputation_06",
    [134140] = "0\t\tINV_Misc_Gift_01\t\t\t5043\0309363\0309537\03014646\03014647\03014648\t0\03012\03015",
    [134141] = "0\t\tINV_Misc_Gift_02\t\t\t5046\03022133\t0\03015",
    [134142] = "0\t\tINV_Misc_Gift_03\t\t\t281680\0305044\0305857\03022131\030172070\t0\03012\03015",
    [132930] = "0\t\tINV_FISHINGCHAIR\t\t1225479\0301262998\t279966\t0",
    [132328] = "0\t\tAbility_Tracking\t3\03011\t1494\0305225\t267223\t12",
    [134148] = "0\t\tINV_Misc_GroupLooking",
    [134149] = "0\t\tINV_Misc_GroupNeedMore",
    [136240] = "0\t\tTrade_Alchemy\t\t2259\t249410\030270877\t7\03015",
    [136241] = "0\t\tTrade_BlackSmithing\t\t2018\t270878\t15",
    [136242] = "0\t\tTrade_BrewPoison\t\t2842\t210056\t12",
    [136243] = "0\t\tTrade_Engineering\t\t4036\0301221012\0301226206\0301226207\0301226208\0301226209\t270881\t15",
    [136244] = "0\t\tTrade_Engraving\t\t7411\t22227\t12",
    [136245] = "0\t\tTrade_Fishing\t\t7620\0307738\t19979\0305567\t4\03015",
    [135776] = "0\t\tSpell_Fire_BlueCano",
    [135777] = "0\t\tSpell_Fire_BlueFire",
    [135778] = "0\t\tSpell_Fire_BlueFireNova",
    [135779] = "0\t\tSpell_Fire_BlueFireward",
    [135780] = "0\t\tSpell_Fire_BlueFlameBolt",
    [135781] = "0\t\tSpell_Fire_BlueFlameBreath",
    }) do S.rows[key] = row end
end
-- The scene is about Sane Macros and the bars: our spellbook and talents stay off its full screen, as in a game without
-- what ours are made after (Abilities.lua, ns.Serves; the lab's book has no paging controls).
C_SpellBook = C_SpellBook or {}
C_SpellBook.IsSpellBookItemLooseFlyoutMember = false
local abilities = Lab.TOC("src/Abilities/SaneUI_Abilities.toc")
LabMacros = abilities.Macros

local PICTURES = { ["Shield Block"] = 132110, ["Victory Rush"] = 132342, ["Shield Slam"] = 134951, Slam = 132340 }
C_Spell = C_Spell or {}
C_Spell.GetSpellTexture = function(name) return PICTURES[name] end
C_Spell.DoesSpellExist = function(name) return PICTURES[name] ~= nil end

LabBars = { Full = function() abilities.Screen.Fill() end }
Lab.OnLogin(function()
    local Book = LabMacros.Book
    if not Book.All()[1] then
        local tank = Book.New("Tank")
        for _, name in ipairs({ "Shield Block", "Victory Rush", "Shield Slam", "Slam" }) do
            tank.steps[#tank.steps + 1] = Book.Step("spell", name)
        end
        Book.New("Mouse heal")
        for _, name in ipairs({ "Hi", "Thanks", "Sit", "Follow", "HP Potion" }) do Book.FromGame(name, "/" .. name:lower()) end
    end
    abilities.Screen.Fill()
end)
