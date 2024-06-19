# Dark-Basic-Pro
Dark Basic Pro is an open source BASIC programming language for creating Windows applications and games. The solution requires Microsoft DirectX SDK (August 2007).

Over the years, Dark Basic Pro produced many first and third party plugins which we have made free thanks to permission from third party developers.

[DarkPHYSICS V1](http://fstore.thegamecreators.com/DarkBasicPro/DarkPhysics_v1.zip) & 
[DarkPHYSICS Update 105](http://fstore.thegamecreators.com/DarkBasicPro/DarkPhysics_Update_105.zip)

Notes:

1. The Synergy Editor assumes DBPro is directly installed in the default folder for 32-bit program files on the OS drive: "C:\Program Files (x86)\Dark-Basic-Pro\". To change this behavior open the file "Editor\Synergy Editor.cfg" and change the value of the "DBPLocation" property accordingly. The value of the "DBPLocation" property in the 090216 and 120216 binary releases has a placeholder value used on development that most likely will need to be changed.

2. The default folder destination assumed by plug-in installers might differ from the actual folder where the installation sits on. When prompted by an installer to choose a different destination do it accordingly.

# Instructions
1. Go Under the Latest Build Folder
2. Create a folder under: C:\Programs Files (x86) called "Dark-Basic-Pro"
3. Dump the contents of the Latest Build Folder inside the "Dark-Basic-Pro" folder.
4. Run the Launch.exe file *AS ADMINISTRATOR* to open the Dark Basic Pro code editor.
![alt text](https://github.com/streamitwrong/Dark-Basic-Pro/blob/Initial-Files/launch%20run%20as%20admin.png?raw=true)
5. Go under Tools > Options
![alt text](https://github.com/streamitwrong/Dark-Basic-Pro/blob/Initial-Files/options%20screenshot.png?raw=true)
6. Change the path from C:\Programs Files (x86)\Dark-Basic-Pro\Compiler\DBPCompiler.exe to "C:\Program Files (x86)\Dark-Basic-Pro\Compiler\DBPCompiler.exe" (Removing the s from Programs) and Click Apply then OK.
![alt text](https://github.com/streamitwrong/Dark-Basic-Pro/blob/Initial-Files/fix%20compiler%20path.jpg?raw=true)
7. The build keyword process will run automatically and find the .ini keyword files as allowed commands the compiler will allow.

![alt text](https://github.com/streamitwrong/Dark-Basic-Pro/blob/Initial-Files/build%20keyword%20process.png?raw=true)
8. Enjoy!
