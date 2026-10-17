# Names

How the voices say the lore names in the game's texts. The voice tool reads this file and turns it into the
voice service's pronunciation dictionary, so every voice says a name the same way, and the way the game's own
voices say it in its cinematics and its voiced characters.

Each table row is one rule:

- **Name:** the name exactly as the game's texts write it, with their apostrophes and capitals.
- **Say:** the alias, a respelling the voices read right: plain syllables, hyphens between them, the stressed
  syllable in capitals. The tool drops the hyphens and lowercases all but the first letter (tel-DRASS-ill
  becomes Teldrassill), so the capitals are only for the reader, and a respelling must also read right as a
  word.
- **IPA:** the sound in the International Phonetic Alphabet, General American. It is optional and used only
  by the newest models, which read phoneme rules; the others use the alias.
- **Note:** where the pronunciation comes from, another way the game's voices say it, or "unsure".

Matching is case-sensitive and by whole words: Kaldorei does not change kaldorei, and Elune does not change
Elune'ara. A name the texts write in two ways needs a row for each. A name followed by 's (Onyxia's Lair)
still counts as the name, and a row of several words (Zug zug) is matched as a whole. Plain English names the
voices already read right (Ironforge, Stormwind, Thunder Bluff) have no row.

The list is a starting point: every name is checked by ear in the voice trial, and a row that sounds wrong is
fixed here. To add a name, put a row in its table in alphabetical order, with the name as the texts write it,
its respelling and, when known, its IPA; say in the note where it was heard, or write "unsure".

## Places

| Name | Say | IPA | Note |
| --- | --- | --- | --- |
| Aerie | AIR-ee | ˈɛɹi | Aerie Peak |
| Ahn'Qiraj | ahn kee-RAHZH | ˌɑn kiˈɹɑʒ | |
| Al'Ameth | al-a-METH | ˌæləˈmɛθ | Lake Al'Ameth; unsure |
| Aldrassil | al-DRASS-ill | ælˈdɹæsɪl | |
| Alterac | ALL-ter-ack | ˈɔltɚæk | |
| Andorhal | AN-dor-hall | ˈændɔɹhɔl | |
| Arathi | a-RATH-ee | əˈɹæθi | as the game's staff gave it |
| Astranaar | AS-tra-nar | ˈæstɹəˌnɑɹ | |
| Atal'Hakkar | AH-tahl HAH-kar | ˌɑtɑl ˈhɑkɑɹ | the Sunken Temple |
| Auberdine | aw-ber-DEEN | ˌɔbɚˈdin | |
| Azeroth | AZ-er-oth | ˈæzɚɑθ | as in the cinematics |
| Azshara | az-SHAR-a | æzˈʃɑɹə | the zone and the queen alike |
| Batol | ba-TOLE | bəˈtoʊl | Grim Batol; unsure |
| Caer | KAIR | kɛɹ | Caer Darrow |
| Dalaran | DAL-a-ran | ˈdæləɹæn | the game's voices say both; later ones DAHL-a-rahn |
| Darnassus | dar-NASS-us | dɑɹˈnæsəs | |
| Desolace | DESS-o-lace | ˈdɛsəˌleɪs | not "desolate" |
| Dolanaar | DOH-la-nar | ˈdoʊləˌnɑɹ | unsure |
| Draenor | DRAN-or | ˈdɹænɔɹ | the game's voices also say DRAY-nor; unsure |
| Durotar | DOOR-o-tar | ˈdʊɹoʊtɑɹ | also heard DUR-o-tar; unsure |
| Eldre'Thalas | EL-dreh tha-lahs | ˈɛldɹə θəˌlɑs | Dire Maul; unsure |
| Elune'ara | eh-LOON-ar-a | əˈlunɑɹə | Lake Elune'ara; unsure |
| Elwynn | EL-win | ˈɛlwɪn | |
| Feralas | feh-RAHL-us | fɚˈɑləs | as the game's staff gave it; also heard FAIR-a-las |
| Gadgetzan | GADJ-et-zan | ˈɡædʒətˌzæn | |
| Gilneas | GIL-nee-us | ˈɡɪlniəs | |
| Gnomeregan | NOHM-re-gahn | ˈnoʊmɹəɡɑn | also heard no-MAIR-e-gan; unsure |
| Grom'gol | GROM-gole | ˈɡɹɑmɡoʊl | |
| Hyjal | HIGH-jahl | ˈhaɪdʒɑl | unsure |
| Jaedenar | JAY-deh-nar | ˈdʒeɪdəˌnɑɹ | |
| Jintha'Alor | JIN-tha a-LOR | ˈdʒɪnθə əˈlɔɹ | unsure |
| Kalimdor | KAL-im-dor | ˈkælɪmdɔɹ | |
| Karazhan | kair-a-ZAHN | ˌkɛɹəˈzɑn | |
| Kargath | KAR-gath | ˈkɑɹɡæθ | the Badlands outpost and the warlord |
| Kharanos | KAR-a-nohs | ˈkɑɹəˌnoʊs | |
| Khaz | KAHZ | kɑz | Khaz Modan |
| Kraul | KRAWL | kɹɔl | Razorfen Kraul |
| Krol'Dok | KROHL-dok | ˈkɹoʊldɑk | new in this client; unsure |
| Kul Tiras | KOOL TEER-us | ˈkul ˈtɪɹəs | |
| Loch | LOCK | lɑk | Loch Modan |
| Lordaeron | LOR-deh-ron | ˈlɔɹdəɹɑn | also heard lor-DAIR-on |
| Maraudon | MOR-a-don | ˈmɔɹədɑn | as the game's staff say it |
| Modan | mo-DAHN | moʊˈdɑn | Khaz Modan and Loch Modan; also heard MOH-dan |
| Mojache | mo-HAH-chay | moʊˈhɑtʃeɪ | Camp Mojache; unsure |
| Morogh | MOR-oh | ˈmɔɹoʊ | Dun Morogh, as in the dwarf intro; the gh is silent |
| Mor'shan | MOR-shan | ˈmɔɹʃæn | |
| Mulgore | MUL-gor | ˈmʌlɡɔɹ | |
| Naxxramas | NAX-ra-mus | ˈnæksɹəməs | |
| Nordrassil | nor-DRASS-ill | nɔɹˈdɹæsɪl | |
| Orgrimmar | OR-grim-ar | ˈɔɹɡɹɪmɑɹ | |
| Quel'Thalas | KWEL-tha-lahs | ˈkwɛlθəˌlɑs | |
| Rut'theran | root THAIR-an | ˌɹut ˈθɛɹən | unsure |
| Scholomance | SKOH-loh-mance | ˈskoʊloʊˌmæns | as the game's staff gave it |
| Shen'dar | shen-DAR | ʃɛnˈdɑɹ | new in this client; unsure |
| Shen'Dralas | shen-DRAH-lus | ʃɛnˈdɹɑləs | new in this client; unsure |
| Silithus | SILL-ith-us | ˈsɪlɪθəs | |
| Stratholme | STRATH-olm | ˈstɹæθoʊlm | |
| Stromgarde | STROM-gard | ˈstɹɑmɡɑɹd | |
| Tanaris | ta-NAIR-iss | təˈnɛɹɪs | also heard TAN-a-ris |
| Taurajo | tor-AH-ho | tɔˈɹɑhoʊ | Camp Taurajo; unsure |
| Teldrassil | tel-DRASS-ill | tɛlˈdɹæsɪl | as in the night elf intro; the game's staff once gave TEL-druh-sill |
| Thelsamar | THEL-sa-mar | ˈθɛlsəˌmɑɹ | |
| Thendal | THEN-dal | ˈθɛndəl | new in this client; unsure |
| Theramore | THAIR-a-more | ˈθɛɹəˌmɔɹ | |
| Tirisfal | TEER-iss-fahl | ˈtɪɹɪsfɑl | as the game's staff gave it |
| Tyr | TEER | tɪɹ | Tyr's Hand |
| Uldaman | OOL-da-mahn | ˈʊldəˌmɑn | |
| Ulduar | OOL-doo-ar | ˈulduˌɑɹ | |
| Uldum | ool-DOOM | ˌulˈdum | |
| Undermine | UN-der-mine | ˈʌndɚˌmaɪn | the goblin capital, stressed first, not like the verb; only the IPA can fix the stress |
| Un'Goro | un-GO-ro | ʌnˈɡoʊɹoʊ | as the game's staff gave it |
| Valanaar | VAL-a-nar | ˈvæləˌnɑɹ | new in this client; unsure |
| Zandalar | ZAN-da-lar | ˈzændəˌlɑɹ | |
| Zephras | ZEF-rus | ˈzɛfɹəs | Zephras Isle, new in this client; unsure |
| Zul'Aman | ZOOL a-mahn | ˈzul əˌmɑn | |
| Zul'Farrak | zool fa-RAHK | ˌzul fəˈɹɑk | |
| Zul'Gurub | zool goo-ROOB | ˌzul ɡuˈɹub | also heard zool-GOO-rub; unsure |

## People

| Name | Say | IPA | Note |
| --- | --- | --- | --- |
| Aegwynn | AYG-win | ˈeɪɡwɪn | |
| Aku'mai | AH-koo-my | ˈɑkuˌmaɪ | |
| Al'Akir | al-ah-KEER | ˌɑlɑˈkɪɹ | |
| Alexstrasza | al-ex-STRAHZ-a | ˌælɛkˈstɹɑzə | |
| Alleria | a-LEER-ee-a | əˈlɪɹiə | |
| Anduin | AN-doo-in | ˈænduɪn | |
| Antonidas | an-toh-NEE-dus | ˌæntoʊˈnidəs | |
| Anub'Rekhan | a-NOOB REK-an | əˈnub ˈɹɛkən | |
| Archaedas | ar-KAY-dus | ɑɹˈkeɪdəs | |
| Archimonde | AR-ki-mond | ˈɑɹkɪmɑnd | |
| Arthas | AR-thus | ˈɑɹθəs | |
| Arugal | AR-oo-gal | ˈæɹuɡæl | unsure |
| Azuregos | AZH-ur-gohs | ˈæʒɚɡoʊs | |
| Balnazzar | BAL-na-zar | ˈbælnəˌzɑɹ | |
| Blaumeux | bloh-MUH | bloʊˈmʌ | unsure |
| Bolvar | BOHL-var | ˈboʊlvɑɹ | |
| Cairne | KAIRN | kɛɹn | |
| Cenarius | seh-NAR-ee-us | səˈnɑɹiəs | |
| Cho'gall | cho-GALL | tʃoʊˈɡɔl | |
| Chromaggus | kro-MAG-us | kɹoʊˈmæɡəs | |
| C'Thun | kuh-THOON | kəˈθun | |
| Drakkisath | DRAK-i-sath | ˈdɹækɪsæθ | |
| Drek'Thar | DREK-thar | ˈdɹɛkθɑɹ | |
| Durotan | DOOR-o-tan | ˈdʊɹoʊtæn | also heard DUR-o-tan; unsure |
| Eitrigg | EE-trig | ˈitɹɪɡ | |
| Eranikus | eh-RAN-i-kus | əˈɹænɪkəs | |
| Executus | eg-ZEK-yoo-tus | ɛɡˈzɛkjətəs | Majordomo Executus |
| Fandral | FAN-drul | ˈfændɹəl | |
| Fordragon | for-DRAG-on | fɔɹˈdɹæɡən | |
| Garona | ga-ROH-na | ɡəˈɹoʊnə | |
| Gul'dan | GOOL-dahn | ˈɡuldɑn | |
| Hakkar | HAH-kar | ˈhɑkɑɹ | also heard HACK-ar; unsure |
| Hamuul | ha-MOOL | həˈmul | |
| Heigan | HAY-gun | ˈheɪɡən | unsure |
| Illidan | ILL-i-dun | ˈɪlɪdən | |
| Immol'thar | IM-ol-thar | ˈɪmoʊlθɑɹ | unsure |
| Jaina | JAY-na | ˈdʒeɪnə | |
| Jin'do | JIN-doh | ˈdʒɪndoʊ | |
| Kael'thas | KAYL-thas | ˈkeɪlθæs | |
| Katrana | ka-TRAH-na | kəˈtɹɑnə | Lady Katrana Prestor; unsure |
| Kel'Thuzad | KEL THOO-zahd | ˈkɛlˌθuzɑd | |
| Khadgar | KAD-gar | ˈkædɡɑɹ | |
| Kil'jaeden | kil-JAY-den | kɪlˈdʒeɪdən | |
| Korth'azz | KORTH-ahz | ˈkɔɹθɑz | |
| Loatheb | LOH-theb | ˈloʊθɛb | |
| Lothar | LOH-thar | ˈloʊθɑɹ | |
| Maexxna | MAKES-na | ˈmeɪksnə | unsure |
| Magatha | ma-GATH-a | məˈɡæθə | unsure |
| Magni | MAG-nee | ˈmæɡni | |
| Maiev | MY-ev | ˈmaɪɛv | |
| Malfurion | mal-FYOOR-ee-on | mælˈfjʊɹiən | |
| Mal'Ganis | mal-GAN-is | mælˈɡænɪs | |
| Malygos | MAL-i-gohs | ˈmælɪɡoʊs | |
| Mankrik | MAN-krik | ˈmæŋkɹɪk | |
| Mannoroth | MAN-o-roth | ˈmænəɹɑθ | |
| Medivh | meh-DEEV | məˈdiv | |
| Mekkatorque | MEK-a-tork | ˈmɛkəˌtɔɹk | |
| Menethil | MEN-eh-thil | ˈmɛnəθɪl | also Menethil Harbor |
| Mograine | mo-GRAIN | moʊˈɡɹeɪn | |
| Muradin | MOOR-a-din | ˈmʊɹədɪn | unsure |
| Nathanos | NATH-a-nohs | ˈnæθəˌnoʊs | |
| Nefarian | neh-FAIR-ee-an | nəˈfɛɹiən | |
| Neltharion | nel-THAR-ee-on | nɛlˈθɑɹiən | |
| Ner'zhul | ner-ZOOL | nɛɹˈzul | |
| Nesingwary | NESS-ing-wair-ee | ˈnɛsɪŋˌwɛɹi | also Nesingwary's Expedition |
| Nozdormu | noz-DOR-moo | nɑzˈdɔɹmu | |
| Onyxia | oh-NIX-ee-a | oʊˈnɪksiə | |
| Ragnaros | RAG-na-rohs | ˈɹæɡnəɹoʊs | |
| Remulos | REM-yoo-lohs | ˈɹɛmjəloʊs | unsure |
| Rexxar | REX-ar | ˈɹɛksɑɹ | |
| Sargeras | sar-GAIR-us | sɑɹˈɡɛɹəs | |
| Saurfang | SOUR-fang | ˈsaʊɚfæŋ | also heard SORE-fang; unsure |
| Sen'jin | SEN-jin | ˈsɛndʒɪn | also Sen'jin Village |
| Shandris | SHAN-dris | ˈʃændɹɪs | |
| Skeram | SKEH-rum | ˈskɛɹəm | unsure |
| Sylvanas | sil-VAH-nus | sɪlˈvɑnəs | also heard sil-VAN-us |
| Talaanis | ta-LAH-nis | təˈlɑnɪs | new in this client; unsure |
| Terenas | TAIR-a-nus | ˈtɛɹənəs | |
| Thaurissan | THOR-i-sun | ˈθɔɹɪsən | Emperor Dagran Thaurissan; also the Ruins of Thaurissan |
| Theradras | THAIR-a-dras | ˈθɛɹədɹæs | |
| Thunderaan | THUN-der-ahn | ˈθʌndɚɑn | |
| Tirion | TEER-ee-on | ˈtɪɹiən | |
| Tortheldrin | tor-THEL-drin | tɔɹˈθɛldɹɪn | |
| Turalyon | too-RAL-yun | tʊˈɹæljən | |
| Tyrande | ti-RAHN-da | təˈɹɑndə | also heard ti-RAND |
| Uther | OO-ther | ˈuθɚ | |
| Vaelastrasz | VAY-la-strahz | ˈveɪləˌstɹɑz | |
| Varimathras | vair-i-MATH-rus | ˌvɛɹɪˈmæθɹəs | |
| Vek'lor | VEK-lor | ˈvɛklɔɹ | |
| Vek'nilash | VEK-ni-lash | ˈvɛknɪlæʃ | |
| Vol'jin | VOHL-jin | ˈvoʊldʒɪn | |
| Wrynn | RIN | ɹɪn | Anduin and Varian Wrynn |
| Xavius | ZAY-vee-us | ˈzeɪviəs | |
| Ysera | ee-SAIR-a | iˈsɛɹə | unsure |
| Ysondre | ee-SON-dray | iˈsɑndɹeɪ | unsure |
| Zul'jin | ZOOL-jin | ˈzuldʒɪn | |

## Peoples and gods

| Name | Say | IPA | Note |
| --- | --- | --- | --- |
| Agamaggan | ag-a-MAG-an | ˌæɡəˈmæɡən | |
| Aggramar | AG-gra-mar | ˈæɡɹəˌmɑɹ | |
| Al'Aketh | al-a-KETH | ˌæləˈkɛθ | new in this client; unsure |
| Amani | a-MAH-nee | əˈmɑni | |
| Aman'Thul | ah-man-THOOL | ˌɑmænˈθul | |
| An'she | AHN-shay | ˈɑnʃeɪ | the sun |
| Anubisath | a-NOO-bi-sath | əˈnubɪsæθ | |
| Aqir | a-KEER | əˈkɪɹ | |
| Atal'ai | AH-tah-lie | ˈɑtɑˌlaɪ | unsure |
| Draenei | DRAN-eye | ˈdɹænaɪ | the game's voices also say DRAY-nye |
| draenei | DRAN-eye | ˈdɹænaɪ | as the texts write it mid-sentence |
| Elune | eh-LOON | əˈlun | |
| Eonar | EE-oh-nar | ˈioʊnɑɹ | |
| Eredar | AIR-a-dar | ˈɛɹədɑɹ | |
| furbolg | FUR-bolg | ˈfɝbɑlɡ | |
| Gelkis | GHEL-kis | ˈɡɛlkɪs | hard g |
| gnoll | NOLL | nɑl | the g is silent |
| Gordunni | gor-DOO-nee | ɡɔɹˈduni | |
| Gurubashi | goo-roo-BAH-shee | ˌɡuɹuˈbɑʃi | |
| Kaldorei | kal-DOR-eye | kælˈdɔɹaɪ | the night elves |
| Khaz'goroth | KAHZ go-ROTH | ˌkɑz ɡəˈɹɑθ | |
| Kolkar | KOHL-kar | ˈkoʊlkɑɹ | |
| Loa | LO-ah | ˈloʊə | |
| Magram | MAG-ram | ˈmæɡɹæm | |
| Malorne | ma-LORN | məˈlɔɹn | |
| Mu'sha | MOO-shah | ˈmuʃɑ | the moon |
| naga | NAH-ga | ˈnɑɡə | |
| Nathrezim | nath-REZ-im | næθˈɹɛzɪm | the dreadlords; unsure |
| Nerubian | neh-ROO-bee-an | nəˈɹubiən | |
| Norgannon | NOR-ga-non | ˈnɔɹɡəˌnɑn | |
| N'Zoth | en-ZOTH | ənˈzɔθ | |
| Qiraji | kee-RAH-zhee | kiˈɹɑʒi | |
| Quel'dorei | kwel-DOR-eye | kwɛlˈdɔɹaɪ | the high elves; also heard KWEL-dor-eye |
| quilboar | KWILL-bore | ˈkwɪlbɔɹ | |
| Shadra | SHAD-ra | ˈʃædɹə | |
| Shen'dorei | shen-DOR-eye | ʃɛnˈdɔɹaɪ | new in this client; unsure |
| Shen'dralar | shen-DRAH-lar | ʃɛnˈdɹɑlɑɹ | |
| Shu'halo | shoo-HAH-loh | ʃuˈhɑloʊ | |
| Silithid | SILL-ith-id | ˈsɪlɪθɪd | |
| silithid | SILL-ith-id | ˈsɪlɪθɪd | as the texts write it mid-sentence |
| Sin'dorei | sin-DOR-eye | sɪnˈdɔɹaɪ | |
| Tauren | TOR-en | ˈtɔɹən | |
| tauren | TOR-en | ˈtɔɹən | as the texts write it mid-sentence |
| Yogg-Saron | YOG sa-RAWN | ˈjɑɡ səˈɹɔn | |
| Zandalari | zan-da-LAR-ee | ˌzændəˈlɑɹi | |

## Words

| Name | Say | IPA | Note |
| --- | --- | --- | --- |
| Aka'Magosh | AH-ka ma-GOSH | ˈɑkə məˈɡɑʃ | |
| Al diel shala | al dee-YEL SHAH-la | ɑl diˈjɛl ˈʃɑlə | unsure |
| Ande'thoras-ethil | AHN-day THOR-as eh-THEEL | ˈɑndeɪ ˈθɔɹəs ɛˈθil | unsure |
| Atiesh | a-TEESH | əˈtiʃ | |
| Cenarion | seh-NAR-ee-on | səˈnɑɹiən | the Cenarion Circle |
| Dabu | DAH-boo | ˈdɑbu | |
| Darnassian | dar-NASS-ee-an | dɑɹˈnæsiən | |
| Elune-Adore | eh-LOON a-DOR | əˈlun əˈdɔɹ | unsure |
| Eredun | air-a-DOON | ˌɛɹəˈdun | |
| Frostmourne | FROST-morn | ˈfɹɔstmɔɹn | |
| Hakkari | hah-KAR-ee | hɑˈkɑɹi | unsure |
| Ishnu-alah | ISH-noo a-LAH | ˈɪʃnu əˈlɑ | |
| Kalimag | KAL-i-mag | ˈkælɪmæɡ | |
| Kirin Tor | KEER-in TOR | ˈkɪɹɪn ˈtɔɹ | |
| Lok'tar | LOHK-tar | ˈloʊktɑɹ | |
| mon | MAHN | mɑn | troll speech, not Monday |
| ogar | OH-gar | ˈoʊɡɑɹ | Lok'tar ogar |
| Quel'Serrar | KWEL-seh-rar | ˈkwɛlsəˌɹɑɹ | |
| Shan'do | SHAHN-doh | ˈʃɑndoʊ | |
| Shorel'aran | shor-el-AR-an | ˌʃɔɹɛlˈɑɹən | |
| Sulfuras | SUL-fur-us | ˈsʌlfɚəs | |
| Swobu | SWOH-boo | ˈswoʊbu | |
| Taur-ahe | TOR AH-heh | tɔɹˈɑhɛ | |
| Taz'dingo | TAHZ-din-go | ˈtɑzdɪŋɡoʊ | |
| Thalassian | tha-LASS-ee-an | θəˈlæsiən | |
| Thero'shan | THAIR-oh-shahn | ˈθɛɹoʊʃɑn | unsure |
| Throm-ka | THROM-kah | ˈθɹɑmkɑ | the texts may also write Throm-Ka |
| Zandali | zan-DAH-lee | zænˈdɑli | |
| Zug zug | ZUG zug | ˈzʌɡ zʌɡ | |
