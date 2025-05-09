# Split Souls

## How to create a release

A GitHub action workflow is set up for automatic release creation. Whenever a commit with a version tag (e.g. v1.0.0) gets pushed, an executable build will be created.

To do this you have do 
* tag your commit
`git tag v<version>`

* then commit
`git commit`

* then push specific tag to remote repository
`git push origin v<version>`

`<version>` has to be replaced with a [semantic versioning](https://semver.org/) string like `1.0.0`

## How to execute the game in multiplayer mode? (two players in the same network)

1. player 1 (host) has to get his ip address by typing "ipconfig" in his commandline
2. he copies the address ("Drahtlos LAN Adapter WLAN" - "IPv4")
3. he goes to file multiplayer_test.gd and pastes it in the function "_on_join_pressed"
4. player 2 (client) also goes to the same file and pastes the ip address of player 1 (host) 
(note: instead of step 3 & 4 you can just commit & push your changes so that you both have the same code)
5. both players execute the game
6. player 1 clicks "host" first and afterwards player 2 clicks "join"

## How to execute the game in testing mode? (one player with two windows - for testing & debugging)
1. go to file to multiplayer_test.gd and paste this "127.0.0.1" in the function "_on_join_pressed"
2. execute the game in the godot editor (first window)
3. open another instance of godot ("Godot_v4.4-stable_win64.exe") and select the game by clicking once (DO NOT OPEN IT) 
4. click on "Run" in the right panel => a second window should be opened 
5. select one window and click host first, and then join in the other window
