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

#include "scianims.h"

/* all custom SendFlags bits we can possibly send */
enumflags
{
	PLAYER_TOPFRAME = PLAYER_CUSTOMFIELDSTART,
	PLAYER_BOTTOMFRAME
};

class SHPlayer:HLPlayer
{
	void(void) SHPlayer;

	/* insanity */
	PREDICTED_FLOAT(sh_insanetime)
	PREDICTED_FLOAT(sh_insaneactive)

	virtual bool IsScientist(void);
	virtual void Physics_Jump(void);
	virtual void UpdatePlayerAnimation(float);

	/* insanity overrides */
	virtual float Physics_MaxSpeed(void);
	virtual void Physics_InputPreMove(void);
	virtual void Physics_InputPostMove(void);
	virtual void Physics_SetViewParms(void);
	virtual void Physics_Crouch(void);

#ifdef CLIENT
	////virtual void(void) draw;
	//virtual float() predraw;
	//virtual void(void) postdraw;
	virtual void UpdatePlayerAttachments(bool);
	virtual void ReceiveEntity(float,float);
	virtual void PredictPreFrame(void);
	virtual void PredictPostFrame(void);
#else
	virtual void EvaluateEntity(void);
	virtual float SendEntity(entity, float);
	virtual void Save(float);
	virtual void Restore(string,string);

	int sh_insanecount;
#endif
};

void
SHPlayer::SHPlayer(void)
{
	sh_insanetime = 0;
	sh_insaneactive = 0;
}

void
SHSciAnim_PlayerUpdate(NSClientPlayer playerTarget)
{
	bool useTopAnim;
	SHPlayer pl = (SHPlayer)playerTarget;

	if (pl.anim_top_delay <= 0.0f) {
		useTopAnim = false;
	} else {
		useTopAnim = true;
	}

	if (vlen(pl.velocity) == 0) {
		pl.frame = SCIANIM_IDLE1;
	} else if (vlen(pl.velocity) < 150) {
		pl.frame = SCIANIM_WALK;
	} else if (vlen(pl.velocity) > 150) {
		pl.frame = SCIANIM_RUN;
	}

	if (useTopAnim) {
		pl.frame = pl.anim_top;
	}

	pl.baseframe = 0;
	pl.basebone = 0;
	pl.frame1time = pl.anim_top_time;
}

bool
SHPlayer::IsScientist(void)
{
#ifdef CLIENT
	float myTeam = getplayerkeyfloat(this.entnum-1, "*team");
#else
	float myTeam = team;
#endif

	return myTeam == 1 ? true : false;
}

#ifndef PHY_VIEWPOS
	#define PHY_VIEWPOS [0,0,28]
#endif

#ifndef PHY_VIEWPOS_CROUCHED
	#define PHY_VIEWPOS_CROUCHED [0,0,12]
#endif
#ifndef PHY_HULL_MIN
	#define PHY_HULL_MIN [-16,-16,-36]
#endif

#ifndef PHY_HULL_MAX
	#define PHY_HULL_MAX [16,16,36]
#endif

#ifndef PHY_HULL_CROUCHED_MIN
	#define PHY_HULL_CROUCHED_MIN [-16,-16,-18]
#endif

#ifndef PHY_HULL_CROUCHED_MAX
	#define PHY_HULL_CROUCHED_MAX [16,16,18]
#endif


void
SHPlayer::Physics_Crouch(void)
{
	if (IsScientist() == true) {
		view_ofs = PHY_VIEWPOS + [0,0, 36];
		return;
	}

	super::Physics_Crouch();
}

void
SHPlayer::Physics_SetViewParms(void)
{
	vector bboxOffset = g_vec_null;

	if (IsScientist() == true) {
		bboxOffset = [0, 0, 36];
	}

	if (IsCrouching()) {
		mins = PHY_HULL_CROUCHED_MIN;
		maxs = PHY_HULL_CROUCHED_MAX;
		view_ofs = PHY_VIEWPOS_CROUCHED;
	} else {
		mins = PHY_HULL_MIN;
		maxs = PHY_HULL_MAX;
		view_ofs = PHY_VIEWPOS;
	}
	SetSize(mins + bboxOffset, maxs + bboxOffset);
}

void
SHPlayer::UpdatePlayerAnimation(float timelength)
{
	if (IsScientist() == true) {
		SHSciAnim_PlayerUpdate(this);
	} else {
		/* calculate our skeletal progression */
		Animation_PlayerUpdate(this);
	}

	/* advance animation timers */
	Animation_TimerUpdate(this, timelength);
}

#ifdef CLIENT
void
SHPlayer::UpdatePlayerAttachments(bool visible)
{
	if (IsScientist()) {
		p_model.modelindex = 0;
		return;
	}

	super::UpdatePlayerAttachments(visible);
}

/*
=================
player::ReceiveEntity
=================
*/
void
SHPlayer::ReceiveEntity(float new, float flChanged)
{
	/* the generic client attributes */
	NSClientPlayer::ReceiveEntity(new, flChanged);

	/* animation */
	READENTITY_BYTE(anim_top, PLAYER_TOPFRAME)
	READENTITY_FLOAT(anim_top_time, PLAYER_TOPFRAME)
	READENTITY_FLOAT(anim_top_delay, PLAYER_TOPFRAME)
	READENTITY_BYTE(anim_bottom, PLAYER_BOTTOMFRAME)
	READENTITY_FLOAT(anim_bottom_time, PLAYER_BOTTOMFRAME)

	READENTITY_FLOAT(sh_insanetime, PLAYER_BOTTOMFRAME)
	READENTITY_FLOAT(sh_insaneactive, PLAYER_BOTTOMFRAME)

	setorigin(this, origin);

	/* these only concern the current player */
	CSQC_UpdateSeat();
	if (this != pSeat->m_ePlayer)
		return;

	/* do not notify us of updates when spawning initially */
	if (flChanged == UPDATE_ALL)
		PredictPreFrame();

	if (flChanged & PLAYER_AMMOTYPES) {
		HUD_AmmoNotify_Check(this);
	}

	if (flChanged & PLAYER_ITEMS || flChanged & PLAYER_HEALTH)
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
SHPlayer::PredictPreFrame(void)
{
	/* the generic client attributes */
	super::PredictPreFrame();

	SAVE_STATE(sh_insanetime)
	SAVE_STATE(sh_insaneactive)
}

/*
=================
player::PredictPostFrame

Where we roll back our values to the ones last sent/verified by the server.
=================
*/
void
SHPlayer::PredictPostFrame(void)
{
	/* the generic client attributes */
	super::PredictPostFrame();

	ROLL_BACK(sh_insanetime)
	ROLL_BACK(sh_insaneactive)
}

#else
void
SHPlayer::Save(float handle)
{
	super::Save(handle);

	/* insanity */
	SaveFloat(handle, "sh_insanetime", sh_insanetime);
	SaveFloat(handle, "sh_insaneactive", sh_insaneactive);
}

void
SHPlayer::Restore(string strKey, string strValue)
{
	switch (strKey) {
	case "sh_insanetime":
		sh_insanetime = ReadFloat(strValue);
		break;
	case "sh_insaneactive":
		sh_insaneactive = ReadFloat(strValue);
		break;
	default:
		super::Restore(strKey, strValue);
	}
}

void
SHPlayer::EvaluateEntity(void)
{
	/* the generic client attributes */
	super::EvaluateEntity();

	EVALUATE_FIELD(sh_insanetime, PLAYER_BOTTOMFRAME)
	EVALUATE_FIELD(sh_insaneactive, PLAYER_BOTTOMFRAME)
}

/*
=================
player::SendEntity
=================
*/
float
SHPlayer::SendEntity(entity ePEnt, float flChanged)
{
	/* don't broadcast invisible players */
	if (IsFakeSpectator() && ePEnt != this)
		return (0);
	if (!GetModelindex() && ePEnt != this)
		return (0);

	flChanged = OptimiseChangedFlags(ePEnt, flChanged);

	/* the generic client attributes */
	NSClientPlayer::SendEntity(ePEnt, flChanged);

	SENDENTITY_BYTE(anim_top, PLAYER_TOPFRAME)
	SENDENTITY_FLOAT(anim_top_time, PLAYER_TOPFRAME)
	SENDENTITY_FLOAT(anim_top_delay, PLAYER_TOPFRAME)
	SENDENTITY_BYTE(anim_bottom, PLAYER_BOTTOMFRAME)
	SENDENTITY_FLOAT(anim_bottom_time, PLAYER_BOTTOMFRAME)

	SENDENTITY_FLOAT(sh_insanetime, PLAYER_BOTTOMFRAME)
	SENDENTITY_FLOAT(sh_insaneactive, PLAYER_BOTTOMFRAME)

	return (1);
}
#endif
