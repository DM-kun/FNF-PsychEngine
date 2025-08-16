@echo off
color 0a
cd ..
@echo on
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib install lime 8.1.2
haxelib install openfl 9.3.3
haxelib install flixel
haxelib install flixel-addons
haxelib install flixel-tools
haxelib install tjson
haxelib install hxdiscord_rpc
haxelib install hxvlc --skip-dependencies
haxelib set lime 8.1.2
haxelib set openfl 9.3.3
haxelib git hscript-iris https://github.com/pisayesiwsi/hscript-iris.git dev
haxelib git flixel-animate https://github.com/MaybeMaru/flixel-animate.git main
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit.git master
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis.git main
haxelib git grig.audio https://gitlab.com/haxe-grig/grig.audio.git main
echo Finished!
pause