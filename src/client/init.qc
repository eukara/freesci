/*
 * Copyright (c) 2016-2021 Marco Cawthorne <marco@icculus.org>
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

/*
=================
ClientGame_Init

Comparable to worldspawn in SSQC in that it's mostly used for precaches
=================
*/
void
ClientGame_Init(float apilevel, string enginename, float engineversion)
{
	Obituary_Init();
	registercommand("+sciscore");
	registercommand("-sciscore");
	registercommand("chooseteam");
}

bool
ClientGame_IsUsingVGUI(void)
{
	/* FTE has a bug with _ infokeys, so we'll accept both formats in case
	   that gets fixed in the future :/ */
	if (getplayerkeyfloat(player_localnum, "vgui_menus") == 1)
		return true;
	if (getplayerkeyfloat(player_localnum, "_vgui_menus") == 1)
		return true;

	return false;
}

void VGUI_ShowMOTD(void);
void CMD_ChooseTeam(void);
void
ClientGame_InitDone(void)
{
	if (serverkeyfloat("sv_playerslots") > 1)
		VGUI_ShowMOTD();
}

void
ClientGame_RendererRestart(string rstr)
{
	precache_model("models/shell.mdl");
	precache_model("models/shotgunshell.mdl");

	/* there's also muzzleflash.spr, but that's just MUZZLE_SMALL again */
	MUZZLE_RIFLE = (int)getmodelindex("sprites/muzzleflash1.spr");
	MUZZLE_SMALL = (int)getmodelindex("sprites/muzzleflash2.spr");
	MUZZLE_WEIRD = (int)getmodelindex("sprites/muzzleflash3.spr");

	Damage_Precache();
	Obituary_Precache();

	FX_Blood_Init();
	FX_BreakModel_Init();
	FX_Explosion_Init();
	FX_GibHuman_Init();
	FX_Spark_Init();
	FX_Impact_Init();
	FX_GaussBeam_Init();

	BEAM_TRIPMINE = particleeffectnum("weapon_tripmine.beam");
}