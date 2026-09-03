// GTA V / FiveM model kataloğu — kara/beyaz liste "Model Arama" ekranı için.
// Model adları gerçek GTA model adlarıdır; hash'ler joaat (GetHashKey) ile
// hesaplanır, böylece oyun içiyle birebir eşleşir. Liste genişletilebilir.

export type ModelKind = "vehicle" | "ped" | "weapon" | "object" | "explosion";

export interface GtaModel {
  name: string;   // gerçek model adı (örn. "adder")
  label: string;  // görünen ad
  kind: ModelKind;
  hash: number;   // joaat(name)
}

/** FiveM GetHashKey ile aynı: joaat, küçük harfe çevirerek. */
export function joaat(input: string): number {
  const s = input.toLowerCase();
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = (h + s.charCodeAt(i)) >>> 0;
    h = (h + (h << 10)) >>> 0;
    h = (h ^ (h >>> 6)) >>> 0;
  }
  h = (h + (h << 3)) >>> 0;
  h = (h ^ (h >>> 11)) >>> 0;
  h = (h + (h << 15)) >>> 0;
  return h >>> 0;
}

// --- Ham ad listeleri (kind bazlı) ------------------------------------------

const VEHICLES = [
  "adder","zentorno","t20","osiris","reaper","fmj","vagner","nero","nero2","xa21",
  "tyrant","emerus","krieger","zorrusso","deveste","furia","entity2","emerus","thrax","s80",
  "banshee","banshee2","bullet","cheetah","cheetah2","comet","comet2","comet3","comet4","comet5",
  "elegy","elegy2","feltzer2","feltzer3","furoregt","gauntlet","gauntlet2","infernus","infernus2","jester",
  "jester2","jester3","kuruma","kuruma2","ninef","ninef2","penumbra","rapidgt","rapidgt2","schwarzer",
  "sultan","sultanrs","tampa2","tempesta","turismor","tyrus","verlierer2","ztype","carbonizzare","coquette",
  "rhino","apc","barracks","barracks2","barracks3","crusader","insurgent","insurgent2","insurgent3","kuruma3",
  "halftrack","khanjali","chernobog","vagrant","technical","technical2","technical3","nightshark","dune3","trailersmall2",
  "lazer","hydra","besra","hunter","savage","valkyrie","valkyrie2","buzzard","buzzard2","annihilator",
  "akula","seasparrow","havok","volatus","supervolito","nokota","molotok","pyro","starling","tula",
  "titan","cargoplane","jet","luxor","luxor2","miljet","nimbus","shamal","velum","velum2",
  "vestra","alphaz1","bombushka","howard","mogul","rogue","seabreeze","cuban800","dodo","duster",
  "faggio","faggio2","faggio3","bati","bati2","akuma","hakuchou","hakuchou2","shotaro","vindicator",
  "sanchez","sanchez2","bmx","cruiser","fixter","scorcher","tribike","tribike2","tribike3","blazer",
  "blazer2","blazer3","blazer4","blazer5","dune","dune2","dune4","dune5","bfinjection","brawler",
  "bifta","kalahari","dloader","rebel","rebel2","riata","sandking","sandking2","mesa","mesa2",
  "police","police2","police3","police4","policeb","policeold1","policeold2","policet","sheriff","sheriff2",
  "fbi","fbi2","riot","riot2","pranger","ambulance","firetruk","lguard","pbus","airtug",
]; // ~150 araç

const WEAPONS = [
  "weapon_pistol","weapon_pistol_mk2","weapon_combatpistol","weapon_appistol","weapon_pistol50","weapon_snspistol",
  "weapon_snspistol_mk2","weapon_heavypistol","weapon_vintagepistol","weapon_flaregun","weapon_marksmanpistol","weapon_revolver",
  "weapon_revolver_mk2","weapon_doubleaction","weapon_ceramicpistol","weapon_navyrevolver","weapon_gadgetpistol","weapon_microsmg",
  "weapon_smg","weapon_smg_mk2","weapon_assaultsmg","weapon_combatpdw","weapon_machinepistol","weapon_minismg",
  "weapon_assaultrifle","weapon_assaultrifle_mk2","weapon_carbinerifle","weapon_carbinerifle_mk2","weapon_advancedrifle","weapon_specialcarbine",
  "weapon_specialcarbine_mk2","weapon_bullpuprifle","weapon_bullpuprifle_mk2","weapon_compactrifle","weapon_militaryrifle","weapon_heavyrifle",
  "weapon_mg","weapon_combatmg","weapon_combatmg_mk2","weapon_gusenberg","weapon_pumpshotgun","weapon_pumpshotgun_mk2",
  "weapon_sawnoffshotgun","weapon_assaultshotgun","weapon_bullpupshotgun","weapon_musket","weapon_heavyshotgun","weapon_dbshotgun",
  "weapon_autoshotgun","weapon_combatshotgun","weapon_sniperrifle","weapon_heavysniper","weapon_heavysniper_mk2","weapon_marksmanrifle",
  "weapon_marksmanrifle_mk2","weapon_rpg","weapon_grenadelauncher","weapon_grenadelauncher_smoke","weapon_minigun","weapon_firework",
  "weapon_railgun","weapon_hominglauncher","weapon_compactlauncher","weapon_rayminigun","weapon_grenade","weapon_bzgas",
  "weapon_molotov","weapon_stickybomb","weapon_proxmine","weapon_snowball","weapon_pipebomb","weapon_ball",
  "weapon_smokegrenade","weapon_flare","weapon_knife","weapon_nightstick","weapon_hammer","weapon_bat",
  "weapon_golfclub","weapon_crowbar","weapon_bottle","weapon_dagger","weapon_hatchet","weapon_machete",
  "weapon_switchblade","weapon_battleaxe","weapon_poolcue","weapon_wrench","weapon_flashlight","weapon_stungun",
]; // ~90 silah

const PEDS = [
  "a_m_y_business_01","a_m_m_business_01","a_f_y_business_01","a_f_m_business_02","a_m_y_hipster_01","a_f_y_hipster_02",
  "a_m_y_beach_01","a_f_y_beach_01","a_m_y_skater_01","a_m_m_farmer_01","a_m_y_golfer_01","a_f_y_yoga_01",
  "s_m_y_cop_01","s_f_y_cop_01","s_m_y_swat_01","s_m_m_snowcop_01","s_m_y_sheriff_01","s_f_y_sheriff_01",
  "s_m_m_paramedic_01","s_m_y_fireman_01","s_m_y_ranger_01","s_f_y_ranger_01","s_m_m_security_01","s_m_y_prisguard_01",
  "s_m_m_pilot_01","s_m_y_pilot_01","s_m_y_airworker","s_m_m_dockwork_01","s_m_y_construct_01","s_m_y_construct_02",
  "s_m_m_gardener_01","s_m_y_garbage","s_m_y_dealer_01","s_m_m_chemsec_01","s_m_m_ciasec_01","s_m_m_fibsec_01",
  "g_m_y_ballaeast_01","g_m_y_ballaorig_01","g_m_y_famca_01","g_m_y_famdnf_01","g_m_y_lost_01","g_m_y_lost_02",
  "g_m_y_mexgoon_01","g_m_y_salvagoon_01","g_m_y_aztecas_01","g_m_y_korean_01","g_m_m_armboss_01","g_m_m_chiboss_01",
  "mp_m_freemode_01","mp_f_freemode_01","player_zero","player_one","player_two","ig_michael",
  "ig_franklin","ig_trevor","ig_lamardavis","ig_lestercrest","ig_amandatownley","ig_jimmydisanto",
  "a_c_chop","a_c_cat_01","a_c_deer","a_c_cow","a_c_boar","a_c_coyote",
  "a_c_rottweiler","a_c_shepherd","a_c_pug","a_c_rabbit_01","a_c_chickenhawk","a_c_rat",
]; // ~72 ped

const OBJECTS = [
  "prop_gold_bar","prop_cash_pile_01","prop_cash_pile_02","prop_money_bag_01","prop_anim_cash_pile_01","prop_ld_cash_pile_01",
  "prop_barrier_work05","prop_barrier_work06a","prop_roadcone01a","prop_roadcone02a","prop_mp_cone_01","prop_boxpile_07d",
  "prop_container_ld","prop_container_ldpe","prop_crate_01a","prop_crate_02a","prop_barrel_01a","prop_barrel_02a",
  "prop_bench_01a","prop_bin_01a","prop_bin_08a","prop_dumpster_01a","prop_dumpster_02a","prop_dumpster_3a",
  "prop_beach_parasol_01","prop_beachflag_le","prop_tree_birch_01","prop_tree_birch_02","prop_tree_cedar_01","prop_tree_cedar_02",
  "prop_tree_oak_01","prop_tree_maple_01","prop_tree_pine_01","prop_bush_lrg_01","prop_palm_fan_02_a","prop_palm_sm_01d",
  "prop_ld_test_01","prop_snow_flag_01","prop_flag_ls","prop_fnclink_02crnr1","prop_fncwood_16d","prop_paddapping_02",
  "prop_toilet_01","prop_portaloo_01a","prop_sign_road_01a","prop_traffic_01a","prop_traffic_lda","prop_streetlight_01",
]; // ~48 nesne (ağaç/prop/exploit prop dahil)

const EXPLOSIONS = [
  "EXP_TAG_GRENADE","EXP_TAG_GRENADELAUNCHER","EXP_TAG_STICKYBOMB","EXP_TAG_MOLOTOV","EXP_TAG_ROCKET","EXP_TAG_TANKSHELL",
  "EXP_TAG_HI_OCTANE","EXP_TAG_CAR","EXP_TAG_PLANE","EXP_TAG_PETROL_PUMP","EXP_TAG_BIKE","EXP_TAG_DIR_STEAM",
  "EXP_TAG_DIR_FLAME","EXP_TAG_DIR_WATER_HYDRANT","EXP_TAG_DIR_GAS_CANISTER","EXP_TAG_BOAT","EXP_TAG_SHIP_DESTROY","EXP_TAG_TRUCK",
  "EXP_TAG_BULLET","EXP_TAG_SMOKEGRENADELAUNCHER","EXP_TAG_SMOKEGRENADE","EXP_TAG_BZGAS","EXP_TAG_FLARE","EXP_TAG_GAS_CANISTER",
  "EXP_TAG_EXTINGUISHER","EXP_TAG_PROGRAMMABLEAR","EXP_TAG_TRAIN","EXP_TAG_BARREL","EXP_TAG_PROPANE","EXP_TAG_BLIMP",
  "EXP_TAG_DIR_FLAME_EXPLODE","EXP_TAG_TANKER","EXP_TAG_PLANE_ROCKET","EXP_TAG_VEHICLE_BULLET","EXP_TAG_GAS_TANK","EXP_TAG_FIREWORK",
  "EXP_TAG_SNOWBALL","EXP_TAG_PROXMINE","EXP_TAG_VALKYRIE_CANNON","EXP_TAG_RAILGUN","EXP_TAG_ORBITAL_CANNON","EXP_TAG_EMP_LAUNCHER",
]; // ~42 patlama

function build(names: string[], kind: ModelKind): GtaModel[] {
  const seen = new Set<string>();
  const out: GtaModel[] = [];
  for (const n of names) {
    const key = n.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    out.push({ name: key, label: prettify(n), kind, hash: joaat(key) });
  }
  return out;
}

function prettify(name: string): string {
  return name
    .replace(/^weapon_/, "")
    .replace(/^prop_/, "")
    .replace(/^exp_tag_/i, "")
    .replace(/[_]+/g, " ")
    .replace(/\b\w/g, (c) => c.toUpperCase())
    .trim();
}

export const GTA_MODELS: GtaModel[] = [
  ...build(VEHICLES, "vehicle"),
  ...build(PEDS, "ped"),
  ...build(WEAPONS, "weapon"),
  ...build(OBJECTS, "object"),
  ...build(EXPLOSIONS, "explosion"),
];

export const MODEL_KIND_META: Record<ModelKind, { label: string; tab: string }> = {
  vehicle: { label: "Araç", tab: "Arabalar" },
  ped: { label: "Ped", tab: "Peds" },
  weapon: { label: "Silah", tab: "Silahlar" },
  object: { label: "Nesne", tab: "Nesneler" },
  explosion: { label: "Patlama", tab: "Patlamalar" },
};

export function countByKind(): Record<string, number> {
  const c: Record<string, number> = { all: GTA_MODELS.length };
  for (const m of GTA_MODELS) c[m.kind] = (c[m.kind] ?? 0) + 1;
  return c;
}
