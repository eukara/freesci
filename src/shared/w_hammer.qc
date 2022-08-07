/*
 * Copyright (c) 2016-2020 Marco Cawthorne <marco@icculus.org>
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
var string g_hammer_spr;
#endif

enum
{
	HAMMER_IDLE1,
	HAMMER_DRAW,
	HAMMER_HOLSTER,
	HAMMER_ATTACK1,
	HAMMER_ATTACK2,
	HAMMER_IDLE2,
	HAMMER_IDLE3,
	HAMMER_HOLSTER2,
	HAMMER_HOLSTER3
};

void w_hammer_precache(void)
{
#ifdef SERVER
	Sound_Precache("weapon_hammer.hit");
	Sound_Precache("weapon_hammer.hitflesh");
	Sound_Precache("weapon_hammer.miss");
#else
	precache_model("models/p_hammer.mdl");
	precache_model("models/v_hammer.mdl");
	g_hammer_spr = spriteframe("sprites/hammer.spr", 0, 0.0f);
#endif
}

void w_hammer_updateammo(player pl)
{
	Weapons_UpdateAmmo(pl, -1, -1, -1);
}
string w_hammer_pmodel(player pl)
{
	return "models/p_hammer.mdl";
}
string w_hammer_deathmsg(void)
{
	return "%s killed %s with hammer.";
}

void w_hammer_draw(player pl)
{
	Weapons_SetModel("models/v_hammer.mdl");
	Weapons_ViewAnimation(pl, HAMMER_DRAW);
}

void w_hammer_holster(player pl)
{
	Weapons_ViewAnimation(pl, HAMMER_HOLSTER);
}
void w_hammer_primary(player pl)
{

	if (!pl.w_attack_next) {
		/* Hack */
		if (pl.ammo_hammer_state != 1) {
			Weapons_ViewAnimation(pl, HAMMER_HOLSTER2);
			pl.ammo_hammer_state = 1;
			pl.w_attack_next = 0.5f;
		}
	}
	pl.w_idle_next = 2.5f;
}
void w_hammer_secondary(player pl)
{

	if (!pl.w_attack_next) {
		/* Hack */
		if (pl.ammo_hammer_state != 2) {
			Weapons_ViewAnimation(pl, HAMMER_HOLSTER3);
			pl.ammo_hammer_state = 2;
			pl.w_attack_next = 0.5f;
		}
	}
	pl.w_idle_next = 2.5f;
}
void w_hammer_reload(player pl)
{
	
}
void w_hammer_release(player pl)
{

	if (pl.w_attack_next) {
		return;
	}

#ifdef SERVER
	int hdmg;
	int hitsound = 0;
	vector src = pl.origin + pl.view_ofs;
	makevectors(pl.v_angle);
	traceline(src, src + v_forward * 64, FALSE, self);
#endif

	if (pl.ammo_hammer_state == 1) {
	#ifdef SERVER
		if (trace_ent.takedamage) {
			if (trace_ent.iBleeds) {
				FX_Blood(trace_endpos, [1,0,0]);
			}
			hitsound = floor(random(1, 2));

			/* players only take half damage */
			hdmg = Skill_GetValue("plr_hammer", 50);

			Damage_Apply(trace_ent, self, hdmg, WEAPON_HAMMER, DMG_BLUNT);

			if (trace_ent.classname == "monster_scientist") {
				trace_ent.movetype = MOVETYPE_TOSS;
				trace_ent.velocity = v_forward * 768 + v_up * 256;
			} else if (trace_ent.classname == "player") {
				trace_ent.velocity = v_forward * 768 + v_up * 256;
			}
		} else {
			if (trace_fraction < 1.0) {
				hitsound = 2;
			}
		}
	#endif
		Weapons_ViewAnimation(pl, HAMMER_ATTACK1);
		pl.w_attack_next = 1.0f;

		if (self.flags & FL_CROUCHING)
			Animation_PlayerTop(pl, ANIM_CR_SHOOTCROWBAR, 0.41f);
		else
			Animation_PlayerTop(pl, ANIM_SHOOTCROWBAR, 0.5f);
	} else if (pl.ammo_hammer_state == 2) {
#ifdef SERVER
		if (trace_ent.takedamage) {
			if (trace_ent.iBleeds) {
				FX_Blood(trace_endpos, [1,0,0]);
			}
			hitsound = floor(random(1, 2));
			hdmg = Skill_GetValue("plr_hammeralt", 200);
			Damage_Apply(trace_ent, self, hdmg, WEAPON_HAMMER, DMG_BLUNT);
		} else {
			if (trace_fraction < 1.0) {
				hitsound = 2;
			}   
		}
#endif
		Weapons_ViewAnimation(pl, HAMMER_ATTACK2);
		pl.w_attack_next = 0.75f;

		if (self.flags & FL_CROUCHING)
			Animation_PlayerTop(pl, ANIM_CR_SHOOTCROWBAR, 0.41f);
		else
			Animation_PlayerTop(pl, ANIM_SHOOTCROWBAR, 0.5f);
	}

#ifdef SERVER
	if (pl.ammo_hammer_state > 0) {
		string snd = "weapon_hammer.miss";
		switch (hitsound) {
		case 1:
			snd = "weapon_hammer.hitflesh";
			break;
		case 2:
			snd = "weapon_hammer.hit";
			break;
		}
		Sound_Play(pl, CHAN_WEAPON, snd);
	}
#endif

	/* Reset the hack */
	pl.ammo_hammer_state = 0;

	/* Pure cosmetics start here */
	if (pl.w_idle_next) {
		return;
	}

	int r = floor(random(0,3));
	switch (r) {
	case 0:
		Weapons_ViewAnimation(pl, HAMMER_IDLE1);
		break;
	case 1:
		Weapons_ViewAnimation(pl, HAMMER_IDLE2);
		break;
	case 2:
		Weapons_ViewAnimation(pl, HAMMER_IDLE3);
		break;
	}
	pl.w_idle_next = 10.0f;
}

float w_hammer_aimanim(player pl)
{
	return pl.flags & FL_CROUCHING ? ANIM_CR_AIMCROWBAR : ANIM_AIMCROWBAR;
}

void w_hammer_hudpic(player pl, int s, vector pos, float a)
{
#ifdef CLIENT
	if (s) {
		drawsubpic(pos, [170,45], g_hammer_spr, [0,48/256], [170/256,45/256], g_hud_color, a, DRAWFLAG_ADDITIVE);
	} else {
		drawsubpic(pos, [170,45], g_hammer_spr, [0,0], [170/256,45/256], g_hud_color, a, DRAWFLAG_ADDITIVE);
	}
#endif
}

weapon_t w_hammer =
{
	.name		= "hammer",
	.id		= ITEM_HAMMER,
	.slot		= 0,
	.slot_pos	= 1,
	.draw		= w_hammer_draw,
	.holster	= w_hammer_holster,
	.primary	= w_hammer_primary,
	.secondary	= w_hammer_secondary,
	.reload		= w_hammer_reload,
	.release	= w_hammer_release,
	.postdraw	= __NULL__,
	.precache	= w_hammer_precache,
	.pickup		= __NULL__,
	.updateammo	= w_hammer_updateammo,
	.wmodel		= __NULL__,
	.pmodel		= w_hammer_pmodel,
	.deathmsg	= w_hammer_deathmsg,
	.aimanim	= w_hammer_aimanim,
	.hudpic		= w_hammer_hudpic
};
