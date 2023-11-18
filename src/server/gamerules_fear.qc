void
SHGameFear::SHGameFear(void)
{

}


void
SHGameFear::ScientistKill(NSClientPlayer pp, entity sci)
{
	player pl = (player)pp;

	if (pl.IsScientist() == true) {
		pl.frags++;
	} else {
		pl.frags--;
	}
}

string
SHGameFear::Title(void)
{
	return ("Stealth");
}