App.Fixtures.Teams = [
 	id: 1
	name: "Blue Team"
	squad_ids: [1,2]
,
	id: 2
	name: "Red Team"
	squad_ids: [3,4]
]

App.Fixtures.Squads = [
	id: 1
	name: "Squad 1"
	team_id: 1
	player_ids: [1,2,3]
,
	id: 2
	name: "Squad 2"
	team_id: 1
	player_ids: [4,5,6]
,
	id: 3
	name: "Squad 3"
	team_id: 2
	player_ids: [7,8,9]
,
	id: 4
	name: "Squad 4"
	team_id: 3
	player_ids: [10,11,12]
]

App.Fixtures.Players = [
	id: 1
	name: "Player 1"
	medal_ids: [1,2]
	weapon_ids: [1,2]
,
	id: 2
	name: "Player 2"
	medal_ids: [2,4]
	weapon_ids: [2,4]
,
	id: 3
	name: "Player 3"
	medal_ids: [5]
	weapon_ids: [1,5]
,
	id: 4
	name: "Player 4"
	medal_ids: [1,4,5]
	weapon_ids: [3,4]
,
	id: 5
	name: "Player 5"
	medal_ids: [1]
	weapon_ids: [2,5]
,
	id: 6
	name: "Player 6"
	medal_ids: [3]
	weapon_ids: [1]
,
	id: 7
	name: "Player 7"
	medal_ids: []
	weapon_ids: [4,5]
,
	id: 8
	name: "Player 8"
	medal_ids: [3,4,5]
	weapon_ids: [2]
,
	id: 9
	name: "Player 9"
	medal_ids: [1,2,3,4,5]
	weapon_ids: [4,5]
,
	id: 10
	name: "Player 10"
	medal_ids: [2,4]
	weapon_ids: [2,4]
,
	id: 11
	name: "Player 11"
	medal_ids: [1,3]
	weapon_ids: [4]
,
	id: 12
	name: "Player 2"
	medal_ids: [1]
	weapon_ids: [4,5]
]

App.Fixtures.Medals = [
	id: 1,
	name: "Bronze Star"
	player_ids: [1,4,5,9,11,12]
,
	id: 2
	name: "Silver Star"
	player_ids: [1,2,9,10]
,
	id: 3
	name: "Gold Star"
	player_ids: [6,8,9,11]
,
	id: 4
	name: "Platinum Star"
	player_ids: [2,4,7,8,9,10]
,
	id: 5
	name: "Diamond Star"
	player_ids: [3,4,5,7,8,9]
]

App.Fixtures.Weapons = [
	id: 1
	name: "Pistol"
	player_ids: [1,3,6]
,
	id: 2
	name: "Shotgun"
	player_ids: [1,2,5,8,10]
,
	id: 3
	name: "Rifle"
	player_ids: [4]
,
	id: 4
	name: "Rockets"
	player_ids: [2,4,7,9,10,11,12]
,
	id: 5
	name: "BFG"
	player_ids: [3,5,7,9,12]
]