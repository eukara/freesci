void
SHGameHunt::RegisterSciDeath(void)
{
	super::RegisterSciDeath();

	if (m_iScientistsAlive > 0)
		return;

	switch (g_chosen_mode) {
	case SHMODE_STANDARD:
		if (m_iKillsTeam1 > m_iKillsTeam2) {
			m_iScoreTeam1++;
			env_message_broadcast("Red team has won!");
		} else if (m_iKillsTeam1 > m_iKillsTeam2) {
			m_iScoreTeam2++;
			env_message_broadcast("Blue team has won!");
		} else {
			env_message_broadcast("Both teams are tied!");
		}

		forceinfokey(world, "teamscore_1", sprintf("%i", m_iScoreTeam1));
		forceinfokey(world, "teamscore_2", sprintf("%i", m_iScoreTeam2));
		think = RestartRound;
		nextthink = time + 5.0f;
		break;
	}
}

void
SHGameHunt::SHGameHunt(void)
{

}