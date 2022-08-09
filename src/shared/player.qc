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

/* all potential SendFlags bits we can possibly send */
enumflags
{
	PLAYER_TOPFRAME = PLAYER_CUSTOMFIELDSTART,
	PLAYER_BOTTOMFRAME,
	PLAYER_AMMO1,
	PLAYER_AMMO2,
	PLAYER_AMMO3,
	PLAYER_UNUSED5,
	PLAYER_UNUSED6,
	PLAYER_UNUSED7
};

class player:NSClientPlayer
{
	/* Weapon specific */
	PREDICTED_INT(glock_mag);
	PREDICTED_INT(mp5_mag);
	PREDICTED_INT(python_mag);
	PREDICTED_INT(shotgun_mag);
	PREDICTED_INT(crossbow_mag);
	PREDICTED_INT(rpg_mag);
	PREDICTED_INT(satchel_chg);
	PREDICTED_INT(cannon_mag);

	PREDICTED_INT(ammo_9mm);
	PREDICTED_INT(ammo_357);
	PREDICTED_INT(ammo_buckshot);
	PREDICTED_INT(ammo_bolt);
	PREDICTED_INT(ammo_rocket);
	PREDICTED_INT(ammo_uranium);
	PREDICTED_INT(ammo_handgrenade);
	PREDICTED_INT(ammo_satchel);
	PREDICTED_INT(ammo_tripmine);
	PREDICTED_INT(ammo_snark);
	PREDICTED_INT(ammo_hornet);

	PREDICTED_INT(ammo_m203_grenade);
	PREDICTED_INT(ammo_shotgun_state);
	PREDICTED_INT(ammo_gauss_state);
	PREDICTED_INT(ammo_gauss_volume);
	PREDICTED_INT(ammo_egon_state);
	PREDICTED_INT(ammo_rpg_state);
	PREDICTED_INT(mode_tempstate);
	PREDICTED_INT(ammo_chainsaw_state);
	PREDICTED_INT(ammo_hammer_state);

	PREDICTED_FLOAT(anim_top);
	PREDICTED_FLOAT(anim_top_time);
	PREDICTED_FLOAT(anim_top_delay);
	PREDICTED_FLOAT(anim_bottom);
	PREDICTED_FLOAT(anim_bottom_time);

#ifdef CLIENT
	virtual void(void) draw;
	virtual float() predraw;
	virtual void(void) postdraw;
	virtual void(float,float) ReceiveEntity;
	virtual void(void) PredictPreFrame;
	virtual void(void) PredictPostFrame;
#else
	virtual void(void) EvaluateEntity;
	virtual float(entity, float) SendEntity;

	int sh_insanecount;
	float sh_insanetime;
	float sh_insaneactive;
#endif
};

#ifdef CLIENT
void Weapons_AmmoUpdate(entity);
void HUD_AmmoNotify_Check(player pl);
void HUD_ItemNotify_Check(player pl);
/*
=================
player::ReceiveEntity
=================
*/
void
player::ReceiveEntity(float new, float fl)
{
	NSClientPlayer::ReceiveEntity(new, fl);

	/* animation */
	if (fl & PLAYER_TOPFRAME) {
		anim_top = readbyte();
		anim_top_time = readfloat();
		anim_top_delay = readfloat();
	}
	if (fl & PLAYER_BOTTOMFRAME) {
		anim_bottom = readbyte();
		anim_bottom_time = readfloat();
	}

	if (fl & PLAYER_AMMO1) {
		glock_mag = readbyte();
		mp5_mag = readbyte();
		python_mag = readbyte();
		shotgun_mag = readbyte();
		crossbow_mag = readbyte();
		rpg_mag = readbyte();
		satchel_chg = readbyte();
		cannon_mag = readbyte();
	}
	
	if (fl & PLAYER_AMMO2) {
		ammo_9mm = readbyte();
		ammo_357 = readbyte();
		ammo_buckshot = readbyte();
		ammo_bolt = readbyte();
		ammo_rocket = readbyte();
		ammo_uranium = readbyte();
		ammo_handgrenade = readbyte();
		ammo_satchel = readbyte();
		ammo_tripmine = readbyte();
		ammo_snark = readbyte();
		ammo_hornet = readbyte();
	}

	if (fl & PLAYER_AMMO3) {
		ammo_m203_grenade = readbyte();
		ammo_shotgun_state = readbyte();
		ammo_gauss_state = readbyte();
		ammo_gauss_volume = readbyte();
		ammo_egon_state = readbyte();
		ammo_rpg_state = readbyte();
		mode_tempstate = readbyte();
		ammo_chainsaw_state = readbyte();
		ammo_hammer_state = readbyte();
	}

	setorigin(this, origin);

	/* these only concern the current player */
	CSQC_UpdateSeat();
	if (this != pSeat->m_ePlayer)
		return;

	/* do not notify us of updates when spawning initially */
	if (fl == UPDATE_ALL)
		PredictPreFrame();

	if (fl & PLAYER_AMMO1 || fl & PLAYER_AMMO2 || fl & PLAYER_AMMO3) {
		Weapons_AmmoUpdate(this);
		HUD_AmmoNotify_Check(this);
	}

	if (fl & PLAYER_ITEMS || fl & PLAYER_HEALTH)
		HUD_ItemNotify_Check(this);
}

/*
=================
player::PredictPostFrame

Save the last valid server values away in the _net variants of each field
so we can roll them back later.
=================
*/
void
player::PredictPreFrame(void)
{
	NSClientPlayer::PredictPreFrame();

	SAVE_STATE(glock_mag);
	SAVE_STATE(mp5_mag);
	SAVE_STATE(python_mag);
	SAVE_STATE(shotgun_mag);
	SAVE_STATE(crossbow_mag);
	SAVE_STATE(rpg_mag);
	SAVE_STATE(satchel_chg);
	SAVE_STATE(cannon_mag);

	SAVE_STATE(ammo_9mm);
	SAVE_STATE(ammo_357);
	SAVE_STATE(ammo_buckshot);
	SAVE_STATE(ammo_bolt);
	SAVE_STATE(ammo_rocket);
	SAVE_STATE(ammo_uranium);
	SAVE_STATE(ammo_handgrenade);
	SAVE_STATE(ammo_satchel);
	SAVE_STATE(ammo_tripmine);
	SAVE_STATE(ammo_snark);
	SAVE_STATE(ammo_hornet);

	SAVE_STATE(ammo_m203_grenade);
	SAVE_STATE(ammo_shotgun_state);
	SAVE_STATE(ammo_gauss_state);
	SAVE_STATE(ammo_gauss_volume);
	SAVE_STATE(ammo_egon_state);
	SAVE_STATE(ammo_rpg_state);
	SAVE_STATE(mode_tempstate);
	SAVE_STATE(ammo_chainsaw_state);
	SAVE_STATE(ammo_hammer_state);

	SAVE_STATE(anim_top);
	SAVE_STATE(anim_top_time);
	SAVE_STATE(anim_top_delay);
	SAVE_STATE(anim_bottom);
	SAVE_STATE(anim_bottom_time);
}

/*
=================
player::PredictPostFrame

Where we roll back our values to the ones last sent/verified by the server.
=================
*/
void
player::PredictPostFrame(void)
{
	NSClientPlayer::PredictPostFrame();

	ROLL_BACK(glock_mag);
	ROLL_BACK(mp5_mag);
	ROLL_BACK(python_mag);
	ROLL_BACK(shotgun_mag);
	ROLL_BACK(crossbow_mag);
	ROLL_BACK(rpg_mag);
	ROLL_BACK(satchel_chg);
	ROLL_BACK(cannon_mag);

	ROLL_BACK(ammo_9mm);
	ROLL_BACK(ammo_357);
	ROLL_BACK(ammo_buckshot);
	ROLL_BACK(ammo_bolt);
	ROLL_BACK(ammo_rocket);
	ROLL_BACK(ammo_uranium);
	ROLL_BACK(ammo_handgrenade);
	ROLL_BACK(ammo_satchel);
	ROLL_BACK(ammo_tripmine);
	ROLL_BACK(ammo_snark);
	ROLL_BACK(ammo_hornet);

	ROLL_BACK(ammo_m203_grenade);
	ROLL_BACK(ammo_shotgun_state);
	ROLL_BACK(ammo_gauss_state);
	ROLL_BACK(ammo_gauss_volume);
	ROLL_BACK(ammo_egon_state);
	ROLL_BACK(ammo_rpg_state);
	ROLL_BACK(mode_tempstate);
	ROLL_BACK(ammo_chainsaw_state);
	ROLL_BACK(ammo_hammer_state);

	ROLL_BACK(anim_top);
	ROLL_BACK(anim_top_time);
	ROLL_BACK(anim_top_delay);
	ROLL_BACK(anim_bottom);
	ROLL_BACK(anim_bottom_time);
}

#else
void
player::EvaluateEntity(void)
{
	NSClientPlayer::EvaluateEntity();

	/* animation */
	if (anim_bottom_net != anim_bottom || anim_bottom_time != anim_bottom_time_net)
		SendFlags |= PLAYER_BOTTOMFRAME;
	if (anim_top_net != anim_top || anim_top_time != anim_top_time_net || anim_top_delay != anim_top_delay_net)
		SendFlags |= PLAYER_TOPFRAME;

	/* ammo 1 type updates */
	if (ATTR_CHANGED(glock_mag))
		SendFlags |= PLAYER_AMMO1;
	else if (ATTR_CHANGED(mp5_mag))
		SendFlags |= PLAYER_AMMO1;
	else if (ATTR_CHANGED(python_mag))
		SendFlags |= PLAYER_AMMO1;
	else if (ATTR_CHANGED(shotgun_mag))
		SendFlags |= PLAYER_AMMO1;
	else if (ATTR_CHANGED(crossbow_mag))
		SendFlags |= PLAYER_AMMO1;
	else if (ATTR_CHANGED(rpg_mag))
		SendFlags |= PLAYER_AMMO1;
	else if (ATTR_CHANGED(satchel_chg))
		SendFlags |= PLAYER_AMMO1;
	else if (ATTR_CHANGED(cannon_mag))
		SendFlags |= PLAYER_AMMO1;

	/* ammo 2 type updates */
	if (ATTR_CHANGED(ammo_9mm))
		SendFlags |= PLAYER_AMMO2;
	else if (ATTR_CHANGED(ammo_357))
		SendFlags |= PLAYER_AMMO2;
	else if (ATTR_CHANGED(ammo_buckshot))
		SendFlags |= PLAYER_AMMO2;
	else if (ATTR_CHANGED(ammo_bolt))
		SendFlags |= PLAYER_AMMO2;
	else if (ATTR_CHANGED(ammo_rocket))
		SendFlags |= PLAYER_AMMO2;
	else if (ATTR_CHANGED(ammo_uranium))
		SendFlags |= PLAYER_AMMO2;
	else if (ATTR_CHANGED(ammo_handgrenade))
		SendFlags |= PLAYER_AMMO2;
	else if (ATTR_CHANGED(ammo_satchel))
		SendFlags |= PLAYER_AMMO2;
	else if (ATTR_CHANGED(ammo_tripmine))
		SendFlags |= PLAYER_AMMO2;
	else if (ATTR_CHANGED(ammo_snark))
		SendFlags |= PLAYER_AMMO2;
	else if (ATTR_CHANGED(ammo_hornet))
		SendFlags |= PLAYER_AMMO2;

	/* ammo 3 type updates */
	if (ATTR_CHANGED(ammo_m203_grenade))
		SendFlags |= PLAYER_AMMO3;
	else if (ATTR_CHANGED(ammo_shotgun_state))
		SendFlags |= PLAYER_AMMO3;
	else if (ATTR_CHANGED(ammo_gauss_state))
		SendFlags |= PLAYER_AMMO3;
	else if (ATTR_CHANGED(ammo_gauss_volume))
		SendFlags |= PLAYER_AMMO3;
	else if (ATTR_CHANGED(ammo_egon_state))
		SendFlags |= PLAYER_AMMO3;
	else if (ATTR_CHANGED(ammo_rpg_state))
		SendFlags |= PLAYER_AMMO3;
	else if (ATTR_CHANGED(mode_tempstate))
		SendFlags |= PLAYER_AMMO3;
	else if (ATTR_CHANGED(ammo_chainsaw_state))
		SendFlags |= PLAYER_AMMO3;
	else if (ATTR_CHANGED(ammo_hammer_state))
		SendFlags |= PLAYER_AMMO3;

	SAVE_STATE(glock_mag);
	SAVE_STATE(mp5_mag);
	SAVE_STATE(python_mag);
	SAVE_STATE(shotgun_mag);
	SAVE_STATE(crossbow_mag);
	SAVE_STATE(rpg_mag);
	SAVE_STATE(satchel_chg);
	SAVE_STATE(cannon_mag);

	SAVE_STATE(ammo_9mm);
	SAVE_STATE(ammo_357);
	SAVE_STATE(ammo_buckshot);
	SAVE_STATE(ammo_bolt);
	SAVE_STATE(ammo_rocket);
	SAVE_STATE(ammo_uranium);
	SAVE_STATE(ammo_handgrenade);
	SAVE_STATE(ammo_satchel);
	SAVE_STATE(ammo_tripmine);
	SAVE_STATE(ammo_snark);
	SAVE_STATE(ammo_hornet);

	SAVE_STATE(ammo_m203_grenade);
	SAVE_STATE(ammo_shotgun_state);
	SAVE_STATE(ammo_gauss_state);
	SAVE_STATE(ammo_gauss_volume);
	SAVE_STATE(ammo_egon_state);
	SAVE_STATE(ammo_rpg_state);
	SAVE_STATE(mode_tempstate);
	SAVE_STATE(ammo_chainsaw_state);
	SAVE_STATE(ammo_hammer_state);

	SAVE_STATE(anim_top);
	SAVE_STATE(anim_top_time);
	SAVE_STATE(anim_top_delay);
	SAVE_STATE(anim_bottom);
	SAVE_STATE(anim_bottom_time);
}

/*
=================
player::SendEntity
=================
*/
float
player::SendEntity(entity ePEnt, float flChanged)
{
	/* don't broadcast invisible players */
	if (IsFakeSpectator() && ePEnt != this)
		return (0);
	if (!GetModelindex() && ePEnt != this)
		return (0);

	flChanged = OptimiseChangedFlags(ePEnt, flChanged);

	WriteByte(MSG_ENTITY, ENT_PLAYER);
	WriteFloat(MSG_ENTITY, flChanged);

	NSClientPlayer::SendEntity(ePEnt, flChanged);

	if (flChanged & PLAYER_TOPFRAME) {
		WriteByte(MSG_ENTITY, anim_top);
		WriteFloat(MSG_ENTITY, anim_top_time);
		WriteFloat(MSG_ENTITY, anim_top_delay);
	}
	if (flChanged & PLAYER_BOTTOMFRAME) {
		WriteByte(MSG_ENTITY, anim_bottom);
		WriteFloat(MSG_ENTITY, anim_bottom_time);
	}

	if (flChanged & PLAYER_AMMO1) {
		WriteByte(MSG_ENTITY, glock_mag);
		WriteByte(MSG_ENTITY, mp5_mag);
		WriteByte(MSG_ENTITY, python_mag);
		WriteByte(MSG_ENTITY, shotgun_mag);
		WriteByte(MSG_ENTITY, crossbow_mag);
		WriteByte(MSG_ENTITY, rpg_mag);
		WriteByte(MSG_ENTITY, satchel_chg);
		WriteByte(MSG_ENTITY, cannon_mag);
	}

	if (flChanged & PLAYER_AMMO2) {
		WriteByte(MSG_ENTITY, ammo_9mm);
		WriteByte(MSG_ENTITY, ammo_357);
		WriteByte(MSG_ENTITY, ammo_buckshot);
		WriteByte(MSG_ENTITY, ammo_bolt);
		WriteByte(MSG_ENTITY, ammo_rocket);
		WriteByte(MSG_ENTITY, ammo_uranium);
		WriteByte(MSG_ENTITY, ammo_handgrenade);
		WriteByte(MSG_ENTITY, ammo_satchel);
		WriteByte(MSG_ENTITY, ammo_tripmine);
		WriteByte(MSG_ENTITY, ammo_snark);
		WriteByte(MSG_ENTITY, ammo_hornet);
	}

	if (flChanged & PLAYER_AMMO3) {
		WriteByte(MSG_ENTITY, ammo_m203_grenade);
		WriteByte(MSG_ENTITY, ammo_shotgun_state);
		WriteByte(MSG_ENTITY, ammo_gauss_state);
		WriteByte(MSG_ENTITY, ammo_gauss_volume);
		WriteByte(MSG_ENTITY, ammo_egon_state);
		WriteByte(MSG_ENTITY, ammo_rpg_state);
		WriteByte(MSG_ENTITY, mode_tempstate);
		WriteByte(MSG_ENTITY, ammo_chainsaw_state);
		WriteByte(MSG_ENTITY, ammo_hammer_state);
	}

	return (1);
}
#endif
