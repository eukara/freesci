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

#ifdef CLIENT
var string g_cannon_spr;
#endif

typedef enum
{
	CANNON_FIREBOTH,
	CANNON_FIRELEFT,
	CANNON_FIRERIGHT,
	CANNON_RELOAD,
	CANNON_DEPLOY,
	CANNON_PUTAWAY,
	CANNON_IDLE1,
	CANNON_IDLE2
} cannonAnims_t;

void
w_cannon_precache(void)
{
#ifdef SERVER
	Sound_Precache("weapon_cannon.shoot");
#else
	precache_model("models/v_cannon.mdl");
	precache_model("models/p_cannon.mdl");
	g_cannon_spr = spriteframe("sprites/w_cannon.spr", 0, 0.0f);
#endif
}

void
w_cannon_updateammo(player pl)
{
	Weapons_UpdateAmmo(pl, pl.cannon_mag, pl.ammo_buckshot, -1);
}

string
w_cannon_pmodel(player pl)
{
	return "models/p_cannon.mdl";
}

string
w_cannon_deathmsg(void)
{
	return "%s killed %s with handcannon.";
}

void
w_cannon_reload(player pl)
{
	if (pl.w_attack_next > 0) {
		return;
	}
	if (pl.cannon_mag >= 2) {
		return;
	}
	if (!pl.ammo_buckshot) {
		return;
	}

	Weapons_ViewAnimation(pl, CANNON_RELOAD);

#ifdef SERVER
	Weapons_ReloadWeapon(pl, player::cannon_mag, player::ammo_buckshot, 2);
#endif

	pl.w_attack_next = 3.0f;
	pl.w_idle_next = 3.0f;
}

int
w_cannon_pickup(player pl, int new, int startammo)
{
#ifdef SERVER

	if (new) {
		pl.cannon_mag = 2;
	} else {
		if (pl.ammo_buckshot < 125) {
			pl.ammo_buckshot = bound(0, pl.ammo_buckshot + 2, 125);
		} else {
			return (0);
		}
	}
#endif
	return (1);
}

void
w_cannon_draw(player pl)
{
	Weapons_SetModel("models/v_cannon.mdl");
	Weapons_ViewAnimation(pl, CANNON_DEPLOY);
}

void
w_cannon_holster(player pl)
{
	Weapons_ViewAnimation(pl, CANNON_PUTAWAY);
}

void
w_cannon_primary(player pl)
{

	if (pl.w_attack_next > 0.0) {
		return;
	}

	if (pl.cannon_mag != 2 && cvar("sh_hchorror") != 1) {
		w_cannon_reload(pl);
		return;
	}

#ifdef CLIENT
	View_SetMuzzleflash(MUZZLE_SMALL);
#else
	int dmg;
	dmg = Skill_GetValue("plr_cannon", 5);
	TraceAttack_FireBullets(20, pl.origin + pl.view_ofs, dmg, [0.08716,0.04362], WEAPON_CANNON);

	if (cvar("sh_hchorror") != 1)
	pl.cannon_mag -= 2;

	Sound_Play(pl, CHAN_WEAPON, "weapon_cannon.shoot");
	Weapons_UpdateAmmo(pl, pl.cannon_mag, pl.ammo_buckshot, __NULL__);
#endif
	Weapons_ViewPunchAngle(pl, [-5,0,0]);
	Weapons_ViewAnimation(pl, CANNON_FIREBOTH);

	if (cvar("sh_hchorror") != 1) {
		pl.w_attack_next = 1.5f;
		pl.w_idle_next = 2.5f;
	} else {
		pl.w_attack_next = 0.5f;
		pl.w_idle_next = 0.5f;
	}

	if (self.flags & FL_CROUCHING)
		Animation_PlayerTop(pl, ANIM_CR_SHOOTSHOTGUN, 0.41f);
	else
		Animation_PlayerTop(pl, ANIM_SHOOTSHOTGUN, 0.5f);
}

void
w_cannon_secondary(player pl)
{

	if (pl.w_attack_next > 0.0) {
		return;
	}

	if (!pl.cannon_mag && cvar("sh_hchorror") != 1) {
		w_cannon_reload(pl);
		return;
	}

	Weapons_ViewPunchAngle(pl, [-5,0,0]);

#ifdef SERVER
	int dmg;
	dmg = Skill_GetValue("plr_cannon", 5);
	TraceAttack_FireBullets(10, pl.origin + pl.view_ofs, dmg, [0.08716,0.04362], WEAPON_CANNON);

	if (cvar("sh_hchorror") != 1)
	pl.cannon_mag--;

	Sound_Play(pl, CHAN_WEAPON, "weapon_cannon.shoot");
#endif

	if (pl.cannon_mag == 2) {
		Weapons_ViewAnimation(pl, CANNON_FIRELEFT);
	} else {
		Weapons_ViewAnimation(pl, CANNON_FIRERIGHT);
	}

	if (cvar("sh_hchorror") != 1) {
		pl.w_attack_next = 1.5f;
		pl.w_idle_next = 2.5f;
	} else {
		pl.w_attack_next = 0.5f;
		pl.w_idle_next = 0.5f;
	}

	if (self.flags & FL_CROUCHING)
		Animation_PlayerTop(pl, ANIM_CR_SHOOTSHOTGUN, 0.41f);
	else
		Animation_PlayerTop(pl, ANIM_SHOOTSHOTGUN, 0.5f);
}
void
w_cannon_release(player pl)
{

	/* auto-reload if need be */
	if (pl.w_attack_next <= 0.0)
	if (pl.cannon_mag == 0 && pl.ammo_buckshot > 0) {
		Weapons_Reload(pl);
		return;
	}

	if (pl.w_idle_next > 0.0) {
		return;
	}

	int r = floor(random(0,2));
	switch (r) {
	case 0:
		Weapons_ViewAnimation(pl, CANNON_IDLE1);
		break;
	case 1:
		Weapons_ViewAnimation(pl, CANNON_IDLE2);
		break;
	}

	pl.w_idle_next = 8.0f;
}

void
w_cannon_crosshair(player pl)
{
#ifdef CLIENT
	static vector cross_pos;
	cross_pos = g_hudmins + (g_hudres / 2) + [-12,-12];
	drawsubpic(cross_pos, [24,24], g_cross_spr, [48/128,24/128], [0.1875, 0.1875], [1,1,1], 1, DRAWFLAG_NORMAL);
	HUD_DrawAmmo1();
	HUD_DrawAmmo2();
	vector aicon_pos = g_hudmins + [g_hudres[0] - 48, g_hudres[1] - 42];
	drawsubpic(aicon_pos, [24,24], g_hud7_spr, [72/256,72/128], [24/256, 24/128], g_hud_color, pSeatLocal->m_flAmmo2Alpha, DRAWFLAG_ADDITIVE);
#endif
}

float
w_cannon_aimanim(player pl)
{
	return pl.flags & FL_CROUCHING ? ANIM_CR_AIMSHOTGUN : ANIM_AIMSHOTGUN;
}

void
w_cannon_hudpic(player pl, int s, vector pos, float a)
{
#ifdef CLIENT
	vector hud_col;

	if (pl.cannon_mag == 0 && pl.ammo_buckshot == 0)
		hud_col = [1,0,0];
	else
		hud_col = g_hud_color;

	if (s) {
		drawsubpic(pos, [170,45], g_cannon_spr, [0,48/256], [170/256,45/256], g_hud_color, a, DRAWFLAG_ADDITIVE);
	} else {
		drawsubpic(pos, [170,45], g_cannon_spr, [0,0], [170/256,45/256], g_hud_color, a, DRAWFLAG_ADDITIVE);
	}

	HUD_DrawAmmoBar(pos, pl.ammo_buckshot, MAX_A_BUCKSHOT, a);
#endif
}

weapon_t
w_cannon =
{
	.name		= "handcannon",
	.id			= ITEM_CANNON,
	.slot		= 2,
	.slot_pos	= 3,
	.draw		= w_cannon_draw,
	.holster	= w_cannon_holster,
	.primary	= w_cannon_primary,
	.secondary	= w_cannon_secondary,
	.reload		= w_cannon_reload,
	.release	= w_cannon_release,
	.postdraw	= w_cannon_crosshair,
	.precache	= w_cannon_precache,
	.pickup		= w_cannon_pickup,
	.updateammo	= w_cannon_updateammo,
	.wmodel		= __NULL__,
	.pmodel		= w_cannon_pmodel,
	.deathmsg	= w_cannon_deathmsg,
	.aimanim	= w_cannon_aimanim,
	.hudpic		= w_cannon_hudpic
};
