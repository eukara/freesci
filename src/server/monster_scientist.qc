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

/*QUAKED monster_scientist (0 0.8 0.8) (-16 -16 0) (16 16 72)

HALF-LIFE (1998) ENTITY

Scientist

*/

enum
{
	SCIA_WALK,
	SCIA_WALKSCARED,
	SCIA_RUN,
	SCIA_RUNSCARED,
	SCIA_RUNLOOK,
	SCIA_180LEFT,
	SCIA_180RIGHT,
	SCIA_FLINCH,
	SCIA_PAIN,
	SCIA_PAINLEFT,
	SCIA_PAINRIGHT,
	SCIA_PAINLEGLEFT,
	SCIA_PAINLEGRIGHT,
	SCIA_IDLE1,
	SCIA_IDLE2,
	SCIA_IDLE3,
	SCIA_IDLE4,
	SCIA_IDLE5,
	SCIA_IDLE6,
	SCIA_SCARED_END,
	SCIA_SCARED1,
	SCIA_SCARED2,
	SCIA_SCARED3,
	SCIA_SCARED4,
	SCIA_PANIC,
	SCIA_FEAR1,
	SCIA_FEAR2,
	SCIA_CRY,
	SCIA_SCI1,
	SCIA_SCI2,
	SCIA_SCI3,
	SCIA_DIE_SIMPLE,
	SCIA_DIE_FORWARD1,
	SCIA_DIE_FORWARD2,
	SCIA_DIE_BACKWARD,
	SCIA_DIE_HEADSHOT,
	SCIA_DIE_GUTSHOT,
	SCIA_LYING1,
	SCIA_LYING2,
	SCIA_DEADSIT,
	SCIA_DEADTABLE1,
	SCIA_DEADTABLE2,
	SCIA_DEADTABLE3
};

class monster_scientist:NSTalkMonster
{
	void(void) monster_scientist;

	/* override */
	virtual void(void) SeeThink;
	virtual float(void) GetWalkSpeed;
	virtual float(void) GetChaseSpeed;
	virtual float(void) GetRunSpeed;
	virtual void(void) PanicFrame;

	virtual void(void) Spawned;
	virtual void(void) Respawn;
	virtual void(void) Pain;
	virtual void(void) Death;
	virtual void(void) PlayerUse;
	virtual void(void) TalkPanic;
	virtual int(void) AnimIdle;
	virtual int(void) AnimWalk;
	virtual int(void) AnimRun;

	virtual int(void) AttackMelee;
	virtual void(void) AttackNeedle;

	virtual void(void) FallNoise;

	virtual void(string, string) SpawnKey;
};


/* Players scare scientists if they see them in Stealth Hunting */
void
monster_scientist::SeeThink(void)
{
	/* let's call the original monster SeeThink function */
	super::SeeThink();

	/* don't do anything if they're already scared */
	if (m_iFlags & MONSTER_FEAR)
	return;

	/* don't do anything if we're in the wrong gamemode */
	if not (g_chosen_mode == SHMODE_STEALTH)
	return;

	/* iterate over all players */
	for (entity e = world; (e = find(e, ::classname, "player"));) {
		/* is that player visible? then scare the scientist! */
		if (Visible(e)) {
			m_iFlags |= MONSTER_FEAR;
			return;
		}
	}
}

/* scientist's speed is controlled via cvar */
void
monster_scientist::PanicFrame(void)
{
	super::PanicFrame();
	input_movevalues = [6 * cvar("sh_scispeed"), 0, 0];
}

float
monster_scientist::GetWalkSpeed(void)
{
	super::GetWalkSpeed();
	return 1.6 * cvar("sh_scispeed");
}

float
monster_scientist::GetChaseSpeed(void)
{
	super:: GetChaseSpeed();
	return 6 * cvar("sh_scispeed");
}

float
monster_scientist::GetRunSpeed(void)
{
	super::GetRunSpeed();
	return 3.5 * cvar("sh_scispeed");
}


void
monster_scientist::FallNoise(void)
{
	Sound_Speak(this, "monster_scientist.fall");
}

int
monster_scientist::AttackMelee(void)
{
	/* visual */
	AnimPlay(61);
	m_flAttackThink = m_flAnimTime;
	/* TODO set needle sub-model
	SetBody(this, "", "geomset 0 5\n"); */

	float r = random();

	/* make them say something extremely fitting, thanks eukara */
	if (r < 0.33)
		Sentence("!SC_CUREA");
	else if (r < 0.66)
		Sentence("!SC_CUREB");
	else
		Sentence("!SC_CUREC");

	/* functional */
	ScheduleThink(AttackNeedle, 1.0f);
	return (1);
}

/* set these globals for scientist's poison
 * a little messy but it works */
.NSTimer poisonTimer;
.entity poisonSource;
.float OldTargetHealth;

/* a function for poison that slowly kills the target */
static void
monster_scientist_NeedleAttack(entity target)
{
	bool isDead = false;
	bool isHealed = false;

	/* if increase in target's health, then they are cured */
	if (target.OldTargetHealth > 0) {
		if (target.OldTargetHealth < target.health) {
			isDead = true; // misleading but less code
			isHealed = true;
			target.flags &= ~FL_NOTARGET;
		}
	}

	if (isHealed != true)
	Damage_Apply(target, target.poisonSource, 10, 0, DMG_POISON);

	/* since corpses have "health" do an extra check */
	if (target.health <= 0)
		isDead = true;
	if (target.solid == SOLID_CORPSE)
		isDead = true;

	if (isDead) {
		/* the attacker laughs at a sucessful kill if they're not dead */
		if (target.poisonSource.solid != SOLID_CORPSE)
			if (isHealed == false) // don't laugh if the victim is cured
			Sound_Speak(target.poisonSource, "monster_scientist.laugh");

		target.poisonTimer.StopTimer();
	}

	/* update our health value for next cycle */
	target.OldTargetHealth = target.health;
}

void
monster_scientist::AttackNeedle(void)
{
	/* implement our special function so we know who are we attacking */
	static void AttackNeedle_PoisonDamage(void) {
		monster_scientist_NeedleAttack(self);
	}

	/* look for our victim */
	traceline(origin, m_eEnemy.origin, FALSE, this);


	/* if the entity can't take damage, don't bother */
	if (trace_fraction >= 1.0 || trace_ent.takedamage != DAMAGE_YES) {
		return;
	}

	/* trace to see if the target is in front of us, if not then fail attack */
	if (vlen(origin - m_eEnemy.origin) < 96) {
		/* set the timer for the poison
		 * flag the vitcim so they aren't attacked again (unless Invasion) */
		if not (g_chosen_mode == SHMODE_INVASION) {
			trace_ent.flags |= FL_NOTARGET;
		}
		trace_ent.poisonSource = this;
		trace_ent.poisonTimer = trace_ent.poisonTimer.ScheduleTimer(trace_ent, AttackNeedle_PoisonDamage, 3.0f, true);

		/* apply our poison attack to the victim */
		monster_scientist_NeedleAttack(trace_ent);
	}
}

/* TODO someday these will use the ACT system */
int
monster_scientist::AnimIdle(void)
{
	return SCIA_IDLE1;
}

int
monster_scientist::AnimWalk(void)
{
	return SCIA_WALK;
}

int
monster_scientist::AnimRun(void)
{
	return SCIA_RUN;
}

void
monster_scientist::TalkPanic(void)
{
	/* it's annoying and prevents the laugh in these gamemodes */
	if (g_chosen_mode == SHMODE_MADNESS || g_chosen_mode == SHMODE_INVASION)
	return;

	int r = floor(random(0,30));

	switch (r) {
	case 1:
		Sentence("!SC_SCARED1"); //scientist/stopattacking
		break;
	case 2:
		Sentence("!SC_SCARED2"); //scientist/youinsane
		break;
	case 3:
		Sentence("!SC_PLFEAR0"); //scientist/whatyoudoing
		break;
	case 4:
		Sentence("!SC_PLFEAR2"); //scientist/madness
		break;
	case 5:
		Sentence("!SC_PLFEAR3"); //scientist/noplease
		break;
	case 6:
		Sentence("!SC_PLFEAR4"); //scientist/getoutofhere
		break;
	case 7:
		Sentence("!SC_FEAR3"); //scientist/dontwantdie
		break;
	case 8:
		Sentence("!SC_FEAR4"); //scientist/getoutalive
		break;
	case 9:
		Sentence("!SC_FEAR5"); //scientist/startle3
		break;
	case 10:
		Sentence("!SC_FEAR6"); //scientist/startle4
		break;
	case 11:
		Sentence("!SC_FEAR7"); //scientist/startle5
		break;
	case 12:
		Sentence("!SC_FEAR8"); //scientist/startle6
		break;
	case 13:
		Sentence("!SC_FEAR9"); //scientist/startle7
		break;
	case 14:
		Sentence("!SC_FEAR10"); //scientist/startle8
		break;
	case 15:
		Sentence("!SC_FEAR11"); //scientist/startle9
		break;
	case 16:
		Sentence("!SC_FEAR12"); //scientist/startle1
		break;
	default:
		Sentence("!SC_SCREAM"); //scientist/sci_fear15
	}

	m_flNextSentence = time + 2.0 + random(0,3);
}

void
monster_scientist::PlayerUse(void)
{
	if (spawnflags & MSF_PREDISASTER) {
		Sentence("!SC_POK");
		return;
	}

	if (m_iFlags & MONSTER_FEAR) {
		bprint(PRINT_HIGH, sprintf("I'm not following you evil person!\n"));
		return;
	}

	super::OnPlayerUse();
}

void
monster_scientist::Pain(void)
{
	/* make everyone on edge */
	WarnAllies();

	if (m_flAnimTime > time) {
		return;
	}

	if (random() < 0.25f) {
		return;
	}

	if (IsAlive() == true) {
		Sound_Speak(this, "monster_scientist.pain");
		SetFrame(SCIA_FLINCH + floor(random(0, 6)));
		m_iFlags |= MONSTER_FEAR;
		m_flAnimTime = time + 0.25f;
	}
}

void
monster_scientist::Death(void)
{
	bool deathcheck = false;
	HLGameRules rules = (HLGameRules)g_grMode;

	/* upset everyone */
	if not (g_chosen_mode == SHMODE_MADNESS || g_chosen_mode == SHMODE_INVASION)
	StartleAllies();

	if (IsAlive() == true) {
		SetFrame(SCIA_DIE_SIMPLE + floor(random(0, 6)));
		rules.ScientistKill((player)g_dmg_eAttacker, (entity)this);

		Plugin_PlayerObituary(g_dmg_eAttacker, this, g_dmg_iWeapon, g_dmg_iHitBody, g_dmg_iDamage);
		Sound_Speak(this, "monster_scientist.die");
		deathcheck = true;
	}

	/* now mark our state as 'dead' */
	super::Death();

	/* now we'll tell our kill function about it, since we're now legally dead */
	if (deathcheck == true) {
		rules.RegisterSciDeath();
	}

	/* will not respawn by themselves in these modes */
	if (g_chosen_mode == SHMODE_STANDARD || g_chosen_mode == SHMODE_STEALTH || g_chosen_mode == SHMODE_INVASION)
		return;

	ScheduleThink(Respawn, 10.0f);
}

void
monster_scientist::Respawn(void)
{
	HLGameRules rules = (HLGameRules)g_grMode;

	/* don't spawn if we're hitting scimax */
	if (serverkeyfloat("sci_count") >= serverkeyfloat("sv_scimax"))
		return;

	super::Respawn();

	/* unset notarget for attacking scientists
	 * TODO in the future we shouldn't have to mess with flags this way */
	flags &= ~FL_NOTARGET;

	if not (g_chosen_mode == SHMODE_MADNESS || g_chosen_mode == SHMODE_INVASION)
	m_iFlags |= MONSTER_CANFOLLOW;
	
	/* attack EVERYONE */
	if (g_chosen_mode == SHMODE_MADNESS)
		m_iAlliance = MAL_ROGUE;

	/* attack anyone but aliens */
	if (g_chosen_mode == SHMODE_INVASION)
		m_iAlliance = MAL_ALIEN;

	/* scientists are always afraid in standard hunting
	 * and scialert mode */ 
	if (autocvar_sh_scialert || g_chosen_mode == SHMODE_STANDARD || g_chosen_mode == SHMODE_MADNESS || g_chosen_mode == SHMODE_INVASION) {
		m_iFlags |= MONSTER_FEAR;
	}

	m_iBody = floor(random(1,5));

	SetSkin(0);

	switch (m_iBody) {
		case 1:
			m_flPitch = 105;
			netname = "Walter";
			break;
		case 2:
			m_flPitch = 100;
			netname = "Einstein";
			break;
		case 3:
			m_flPitch = 95;
			netname = "Luther";
			SetSkin(1);
			break;
		default:
			m_flPitch = 100;
			netname = "Slick";
	}

	/* recount to update sciscore and so on */
	rules.CountScientists();
}

void
monster_scientist::SpawnKey(string strKey, string strValue)
{
	switch (strKey) {
	case "body":
		SetBody(stoi(strValue) + 1);
		break;
	default:
		super::SpawnKey(strKey, strValue);
	}
}

void
monster_scientist::Spawned(void)
{
	if (spawnflags & MSF_PREDISASTER) {
		m_talkAsk = "";
		m_talkPlayerAsk = "!SC_PQUEST";
		m_talkPlayerGreet = "!SC_PHELLO";
		m_talkPlayerIdle = "!SC_PIDLE";
	} else {
		m_talkAsk = "!SC_QUESTION";
		m_talkPlayerAsk = "!SC_QUESTION";
		m_talkPlayerGreet = "!SC_HELLO";
		m_talkPlayerIdle = "!SC_PIDLE";
	}

	m_talkAnswer = "!SC_ANSWER";
	m_talkAllyShot = "!SC_PLFEAR";
	m_talkGreet = "!SC_HELLO";
	m_talkIdle = "!SC_IDLE";
	m_talkHearing = "!SC_HEAR";
	m_talkSmelling = "!SC_SMELL";
	m_talkStare = "!SC_STARE";
	m_talkSurvived = "!SC_WOUND";
	m_talkWounded = "!SC_MORTAL";

	/* they seem to use predisaster lines regardless of disaster state */
	m_talkPlayerWounded1 = "!SC_CUREA";
	m_talkPlayerWounded2 = "!SC_CUREB";
	m_talkPlayerWounded3 = "!SC_CUREC";
	m_talkUnfollow = "!SC_WAIT";
	m_talkFollow = "!SC_OK";
	m_talkStopFollow = "!SC_STOP";
	m_iBody = -1;

	model = "models/scientist.mdl";
	base_mins = [-16,-16,0];
	base_maxs = [16,16,72];
	base_health = Skill_GetValue("scientist_health", 20);

	super::Spawned();

	Sound_Precache("monster_scientist.die");
	Sound_Precache("monster_scientist.pain");
	Sound_Precache("monster_scientist.laugh");
	Sound_Precache("monster_scientist.fall");

	/* has the body not been overriden, etc. choose a character for us */
	if (m_iBody == -1) {
		SetBody((int)floor(random(1,5)));
	}

	switch (m_iBody) {
	case 1:
		m_flPitch = 105;
		netname = "Walter";
		break;
	case 2:
		m_flPitch = 100;
		netname = "Einstein";
		break;
	case 3:
		m_flPitch = 95;
		netname = "Luther";
		SetSkin(1);
		break;
	default:
		m_flPitch = 100;
		netname = "Slick";
	}
}

void
monster_scientist::monster_scientist(void)
{

}
