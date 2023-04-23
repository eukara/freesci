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

class HLGameRules:CGameRules
{
	int m_iScientistsAlive;

	float m_flRestockTimer;
	float m_flBreakRespawnTimer;

	/* client */
	virtual void(NSClientPlayer) PlayerSpawn;
	virtual void(NSClientPlayer) PlayerDeath;
	virtual void(NSClientPlayer) PlayerPostFrame;
	virtual void(NSClientPlayer, entity) ScientistKill;
	virtual void(void) RegisterSciDeath;

	virtual void(NSClientPlayer) LevelDecodeParms;
	virtual void(NSClientPlayer) LevelChangeParms;
	virtual void(void) LevelNewParms;
	virtual void(void) FrameStart;
	virtual bool(void) IsMultiplayer;
	virtual void(void) RestartRound;

	virtual void(void) CountScientists;

	void(void) HLGameRules;
	virtual void(void) InitPostEnts;
};

class SHTeamRules:HLGameRules
{
	int m_iKillsTeam1;
	int m_iKillsTeam2;

	int m_iScoreTeam1;
	int m_iScoreTeam2;

	void(void) SHTeamRules;

	virtual void(void) RestartRound;
	virtual void(NSClientPlayer) PlayerSpawn;
	virtual bool(void) IsTeamplay;
	virtual void(void) AddTeam1Kill;
	virtual void(void) AddTeam2Kill;
	virtual void(void) RemoveTeam1Kill;
	virtual void(void) RemoveTeam2Kill;
	virtual void(void) RegisterSciDeathHuntTeam;
	virtual void(NSClientPlayer, entity) ScientistKill;
	virtual void(NSClientPlayer, entity) ScientistKillFear;
	virtual void(void) InitPostEnts;
};

/* Standard Hunting (0):
	Round-based competitive killing where scientists are always running around. Scientists don't respawn.
*/
class SHGameHunt:SHTeamRules
{
	void(void) SHGameHunt;
};

/* Stealth Hunting (1):
	Round-based competitive killing where scientists stand or walk around, but will run in fear if they see the player. Scientists don't respawn. Similar to deer hunting.
*/
class SHGameStealth:SHTeamRules
{
	void(void) SHGameStealth;
};

/* Traditional Slaughter (2):
	Casual killing where scientists treat the player same as in Single Player. Scientists respawn. I suggest we just leave teams out on this one?
*/
class SHGameSlaughter:HLGameRules
{
	void(void) SHGameSlaughter;
};

/* Live in Fear (3):
	Unique round-based gamemode where players have to only kill an evil randomly selected player controlled scientist causing chaos. Those who kill good scientists are punished with lost points. The evil scientist gains one point from every kill (NPC or Players). Scientists respawn.
*/
class SHGameFear:HLGameRules
{
	void(void) SHGameFear;
};

/* Madness (4):
	Unique gamemode where scientists attack themselves and the players. Scientists inject players and NPCs only once with a poison that slowly drains their health to 0. The scientists also play a sound (sh/hide_laugh.wav) when they get a sucessful kill and are still alive. Scientists respawn.
*/
class SHGameMadness:HLGameRules
{

	void(void) SHGameMadness;
};

typedef enum
{
	SHMODE_STANDARD = 0,
	SHMODE_STEALTH,
	SHMODE_SLAUGHTER,
	SHMODE_LIVEINFEAR,
	SHMODE_MADNESS
} shmode_e;

var shmode_e autocvar_sv_realistic = SHMODE_SLAUGHTER;
var shmode_e g_chosen_mode;
