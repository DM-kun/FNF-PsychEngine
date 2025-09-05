#!/bin/sh
# SETUP FOR MAC AND LINUX SYSTEMS!!!
# REMINDER THAT YOU NEED HAXE INSTALLED PRIOR TO USING THIS
# https://haxe.org/download
cd ..
echo Makking the main haxelib and setuping folder in same time..
mkdir ~/haxelib && haxelib setup ~/haxelib
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib install lime 8.1.2
haxelib install openfl 9.3.3
haxelib install flixel
haxelib install flixel-addons
haxelib install flixel-tools
haxelib install flxsvg
haxelib install tjson
haxelib install hxdiscord_rpc
haxelib install hxvlc --skip-dependencies
haxelib set lime 8.1.2
haxelib set openfl 9.3.3
haxelib git hscript-iris https://github.com/pisayesiwsi/hscript-iris.git dev
haxelib git flixel-animate https://github.com/MaybeMaru/flixel-animate.git main
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit.git master
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis.git 1966f8fbbbc509ed90d4b520f3c49c084fc92fd6
haxelib git grig.audio https://gitlab.com/haxe-grig/grig.audio.git main
echo Finished!