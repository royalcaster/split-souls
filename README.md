# split-souls

## Table of Contents
- [Excalidraw](#excalidraw)
- [How to build](#how-to-build)
- [Navigation](#navigation)

## Excalidraw

* Open the file `docs/split-souls.excalidraw` in [Excalidraw](https://excalidraw.com/)
* Make changes (the things you added to the game)
* Save the file to the same path
* optional: take screenshots and add it in this `README.md`

## How to build

* Go to "actions" tab in GitHub Repo
* Choose debug or release build in the left panel
* Click "Run workflow" on the right and choose platform
* Wait for the build to finish.

## Navigation
![alt text](./docs/img/navigation.png "Title")

## Multiplayer Versions: 

# How to execute the game in multiplayer mode? (two players in the same network, without external server)
1. make sure you have the script Game_local_multiplayer.gd connected to the Game.tscn scene and player_1.gd connected to the scene
2. player 1 (host) has to get his ip address by typing "ipconfig" in his commandline
3. he copies the address ("Drahtlos LAN Adapter WLAN" - "IPv4")
4. he goes to file Game_local_multiplayer.gd and pastes it in the function "_on_join_pressed"
5. player 2 (client) also goes to the same file and pastes the ip address of player 1 (host) 
(note: instead of step 3 & 4 you can just commit & push your changes so that you both have the same code)
6. both players execute the game
7. player 1 clicks "host" first and afterwards player 2 clicks "join"

# How to execute the game in testing mode? (one player with two windows, without external server - for testing & debugging)
1. make sure you have the script Game_local_multiplayer.gd connected to the Game.tscn scene and player_1.gd connected to the scene
2. go to file to Game_local_multiplayer.gd and paste this "127.0.0.1" in the function "_on_join_pressed"
3. execute the game in the godot editor (first window)
4. open another instance of godot ("Godot_v4.4-stable_win64.exe") and select the game by clicking once (DO NOT OPEN IT) 
5. click on "Run" in the right panel => a second window should be opened 
6. select one window and click host first, and then join in the other window

# How to execute the game with the Noray server (one or two players in same/different networks)
Note: for some networks it might not work that two instances work in the same network
1. make sure you have the script Game.gd connected to the Game.tscn scene and player_1.gd connected to the scene
2. execute the game in the godot editor (first window)
3. if you are trying it alone, open another instance of godot ("Godot_v4.4-stable_win64.exe") and select the game by clicking once (DO NOT OPEN IT)
	OR the other person executes the game
4. player one copys their OID and gives it to the second player; player one hits "HOST"
5. player two pastes the OID and hits "JOIN" 
