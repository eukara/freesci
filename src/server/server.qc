/*
 * Copyright (c) 2016-2023 Marco Cawthorne <marco@icculus.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF MIND, USE, DATA OR PROFITS, WHETHER
 * IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
 * OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

void
Game_InitRules(void)
{
	g_chosen_mode = autocvar_sh_realistic;

	switch (autocvar_sh_realistic) {
	case SHMODE_STANDARD:
		g_grMode = spawn(SHGameHunt);
		break;
	case SHMODE_STEALTH:
		g_grMode = spawn(SHGameStealth);
		break;
	case SHMODE_SLAUGHTER:
		g_grMode = spawn(SHGameSlaughter);
		break;
	case SHMODE_LIVEINFEAR:
		g_grMode = spawn(SHGameFear);
		break;
	case SHMODE_MADNESS:
		g_grMode = spawn(SHGameMadness);
		break;
	case SHMODE_INVASION:
		g_grMode = spawn(SHGameInvasion);
		break;
	default:
		g_grMode = spawn(HLGameRules);
	}
}

void
Game_Worldspawn(void)
{
	precache_model("models/player.mdl");
	precache_model("models/w_weaponbox.mdl");
	Sound_Precache("Player.FlashLightOff");
	Sound_Precache("Player.FlashLightOn");

	EntityDef_Precache("weapon_crowbar");
	EntityDef_Precache("weapon_9mmhandgun");
	EntityDef_Precache("weapon_357");
	EntityDef_Precache("weapon_9mmAR");
	EntityDef_Precache("weapon_shotgun");
	EntityDef_Precache("weapon_crossbow");
	EntityDef_Precache("weapon_rpg");
	EntityDef_Precache("weapon_gauss");
	EntityDef_Precache("weapon_egon");
	EntityDef_Precache("weapon_hornetgun");
	EntityDef_Precache("weapon_handgrenade");
	EntityDef_Precache("weapon_satchel");
	EntityDef_Precache("weapon_tripmine");
	EntityDef_Precache("weapon_snark");
	EntityDef_Precache("weapon_handcannon");
	EntityDef_Precache("weapon_chainsaw");
	EntityDef_Precache("weapon_hammer");

	Player_Precache();
	SHData_Parse(mapname);
	FX_Corpse_Init();
}
