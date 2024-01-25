package states;

import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import mod_support_stuff.FullyModState;
import mod_support_stuff.MainMenuJson;
import haxe.Json;
import mod_support_stuff.SwitchModSubstate;
import mod_support_stuff.MenuOptions;

@:enum abstract MainMenuItemAlignment(String) {
	public var LEFT = "left";
	public var CENTER = "center";
	public var MIDDLE = "middle";
	public var RIGHT = "right";
}
class MainMenuState extends FullyModState {

	public override function className() {return "MainMenuState";}
	public var mainMenuScript:Script;
	public var curSelected:Int = 0;
	public var versionShit:FlxText;
	public var menuItems:MainMenuOptions;

	// JSON SETTINGS
	public var alignment:MainMenuItemAlignment = CENTER;
	public var bgScroll:Bool = true;
	public var flickerColor:FlxColor = 0xFFFD719B;
	public var defaultBehaviour:Bool = true;
	public var autoCamPos:Bool = true;
	private var _autoPos:Bool = true;

	public var optionShit:MenuOptions = new MenuOptions();
	public var options(get, set):MenuOptions;
	function get_options() {return optionShit;};
	function set_options(o) {return optionShit = o;};

	public var magenta:FlxSprite;
	public var camFollow:FlxObject;
	public var backButton:FlxClickableSprite;
	public var fallBackBG:FlxSprite;
	public var bg:FlxSprite;
	public var mouseControls:Bool = Settings.engineSettings.data.menuMouse;

	public var factor(get, never):Float;

	function get_factor() {
		return Math.min(650 / optionShit.length, 100);
	}
	override function normalCreate()
	{
		super.normalCreate();
		
		reloadModsState = true;
		
		var canJson = false;
		var jsonPath = Paths.json("mainMenu", 'mods/${Settings.engineSettings.data.selectedMod}'); // load default main menu, copy from Friday Night Funkin' mod to create your own.
		if (canJson = Assets.exists(jsonPath)) {
			var parsedJson:MainMenuJson = null;
			try {
				parsedJson = Json.parse(Assets.getText(jsonPath));
			} catch(e) {
				LogsOverlay.trace('Failed to parse MainMenu.json located at ${Assets.getPath(jsonPath)}\n${e.details()}');
				canJson = false;
			}
			if (canJson) {
				if (parsedJson.alignment != null) alignment = parsedJson.alignment;
				if (parsedJson.options == null || parsedJson.options.length <= 0) {
					canJson = false;
				}
				if (parsedJson.flickerColor != null) {
					var f = FlxColor.fromString(parsedJson.flickerColor);
					if (f != null)
						flickerColor = f;
				}
				if (parsedJson.bgScroll != null) bgScroll = parsedJson.bgScroll;
				if (parsedJson.defaultBehaviour != null) defaultBehaviour = parsedJson.defaultBehaviour;
				if (parsedJson.autoCamPos != null) autoCamPos = parsedJson.autoCamPos;
				if (parsedJson.autoPos != null) _autoPos = parsedJson.autoPos;
				var isDevMode = CoolUtil.isDevMode();
				for(o in parsedJson.options) {
					if (isDevMode || !o.devModeOnly) {
						optionShit.add(o.name.toLowerCase(), function() {
							mainMenuScript.executeFunc(o.callback);
						}, Paths.getSparrowAtlas(o.image), o.staticAnim, o.selectedAnim).direct = o.instant;
					}
				}
			}
		}
		
		if (!canJson) {
			optionShit.add('story mode', function() {
				mainMenuScript.executeFunc("onStoryMode");
			}, Paths.getSparrowAtlas('FNF_main_menu_assets'), 'story mode basic', 'story mode white');
			optionShit.add('freeplay', function() {
				mainMenuScript.executeFunc("onFreeplay");
			}, Paths.getSparrowAtlas('FNF_main_menu_assets'), 'freeplay basic', 'freeplay white');
			optionShit.add('mods', function() {
				mainMenuScript.executeFunc("onMods");
			}, Paths.getSparrowAtlas('FNF_main_menu_assets'), 'mods basic', 'mods white');
			if (ModSupport.modMedals[Settings.engineSettings.data.selectedMod] != null
			&& ModSupport.modMedals[Settings.engineSettings.data.selectedMod].medals != null
			&& ModSupport.modMedals[Settings.engineSettings.data.selectedMod].medals.length > 0) {
				optionShit.add('medals', function() {
					mainMenuScript.executeFunc("onMedals");
				}, Paths.getSparrowAtlas('FNF_main_menu_assets'), 'medals basic', 'medals white');
			}
			optionShit.add('donate', function() {
				mainMenuScript.executeFunc("onDonate");
			}, Paths.getSparrowAtlas('FNF_main_menu_assets'), 'donate basic', 'donate white').direct = true;
			optionShit.add('credits', function() {
				mainMenuScript.executeFunc("onCredits");
			}, Paths.getSparrowAtlas('FNF_main_menu_assets'), 'credits basic', 'credits white');
			optionShit.add('options', function() {
				mainMenuScript.executeFunc("onOptions");
			}, Paths.getSparrowAtlas('FNF_main_menu_assets'), 'options basic', 'options white');

			if (Settings.engineSettings.data.developerMode) {
				optionShit.insert(4, 'toolbox', function() {
					mainMenuScript.executeFunc("onToolbox");
				}, Paths.getSparrowAtlas('FNF_main_menu_assets'), 'toolbox basic', 'toolbox white');
			}
		}
			
		mainMenuScript = Script.create('${Paths.modsPath}/${Settings.engineSettings.data.selectedMod}/ui/MainMenuState');
		var valid = true;
		if (mainMenuScript == null) {
			valid = false;
			mainMenuScript = new DummyScript();
		}
		mainMenuScript.setVariable("create", function() {});
		mainMenuScript.setVariable("addOption", optionShit.add);
		mainMenuScript.setVariable("removeOption", optionShit.remove);
		mainMenuScript.setVariable("insertOption", optionShit.insert);
		mainMenuScript.setVariable("update", function(elapsed:Float) {});
		mainMenuScript.setVariable("beatHit", function(curBeat:Int) {});
		mainMenuScript.setVariable("stepHit", function(curStep:Int) {});
		mainMenuScript.setVariable("onSelect", function(obj:MenuOption) {});
		mainMenuScript.setVariable("onSelectEnd", function(obj:MenuOption) {});
		mainMenuScript.setVariable("state", this);

		/**
		 * OPTIONS CALLBACKS THAT CAN BE OVERRIDEN
		 */
		mainMenuScript.setVariable("onStoryMode", function() {
			FlxG.switchState(new StoryMenuState());
		});
		mainMenuScript.setVariable("onFreeplay", function() {
			FlxG.switchState(new FreeplayState());
		});
		mainMenuScript.setVariable("onMods", function() {
			FlxG.switchState(new ModMenuState());
		});
		mainMenuScript.setVariable("onMedals", function() {
			FlxG.switchState(new MedalsState());
		});
		mainMenuScript.setVariable("onDonate", function() {
			#if linux
				Sys.command('/usr/bin/xdg-open', ["https://ninja-muffin24.itch.io/funkin", "&"]);
			#else
				FlxG.openURL('https://ninja-muffin24.itch.io/funkin');
			#end
		});
		mainMenuScript.setVariable("onCredits", function() {
			FlxG.switchState(new CreditsState());
		});
		mainMenuScript.setVariable("onOptions", function() {
			OptionsMenu.fromFreeplay = false;
			FlxG.switchState(new OptionsMenu(0, -FlxG.camera.scroll.y * 0.18));
		});
		mainMenuScript.setVariable("onToolbox", function() {
			FlxG.switchState(new ToolboxMain());
		});



		ModSupport.setScriptDefaultVars(mainMenuScript, Settings.engineSettings.data.selectedMod, {});
		if (valid) {
			mainMenuScript.setScriptObject(this);
			mainMenuScript.loadFile();
		}
		mainMenuScript.executeFunc("create");

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Main Menu", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		CoolUtil.playMenuMusic();

		fallBackBG = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFFFFFFFF, true);
		fallBackBG.color = 0xFFFDE871;
		fallBackBG.scrollFactor.set();
		add(fallBackBG);

		var menuBGPath = Paths.image('menuBG');
		if (Assets.exists(Paths.image('menuBG', 'mods/${Settings.engineSettings.data.selectedMod}'))) {
			menuBGPath = Paths.image('menuBG', 'mods/${Settings.engineSettings.data.selectedMod}');
		}
		var menuDesatPath = Paths.image('menuDesat');
		if (Assets.exists(Paths.image('menuDesat', 'mods/${Settings.engineSettings.data.selectedMod}'))) {
			menuDesatPath = Paths.image('menuDesat', 'mods/${Settings.engineSettings.data.selectedMod}');
		}
		bg = new FlxSprite(-80).loadGraphic(menuBGPath);
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.18;
		bg.setGraphicSize(Std.int(bg.width * 1.2));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);
		

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).loadGraphic(menuDesatPath);
		magenta.scrollFactor.x = 0;
		magenta.scrollFactor.y = 0.18;
		magenta.setGraphicSize(Std.int(magenta.width * 1.2));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = true;
		magenta.color = flickerColor;
		add(magenta);
		// magenta.scrollFactor.set();

		menuItems = new MainMenuOptions();
		add(menuItems);


		// troll
		for (i=>option in optionShit.members)
		{
			var menuItem:MainMenuItem = new MainMenuItem(0, (FlxG.height / optionShit.length * i) + (FlxG.height / (optionShit.length * 2)));
			menuItem.frames = option.frames;
			menuItem.animation.addByPrefix('idle', option.idle, option.idleFPS == null ? 24 : option.idleFPS);
			menuItem.animation.addByPrefix('selected', option.selected, option.selectedFPS == null ? 24 : option.selectedFPS);
			menuItem.animation.play('idle');
			menuItem.updateHitbox();
			menuItem.ID = i;
			menuItem.autoPos = _autoPos;
			menuItem.screenCenter(X);
			menuItem.scrollFactor.set(0, 1 / (optionShit.length));
			menuItem.scale.set(factor / menuItem.height, factor / menuItem.height);
			menuItem.y -= menuItem.height / 2;
			menuItem.antialiasing = true;
			menuItems.add(menuItem);
		}

		var psychVer:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		psychVer.scrollFactor.set();
		psychVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(psychVer);
		var fnfVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		fnfVer.scrollFactor.set();
		fnfVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(fnfVer);
		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		addVirtualPad(UP_DOWN, A_B_E);

		super.create();

		FlxG.camera.follow(camFollow, null, 9);
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
				changeItem(-1);

			if (controls.UI_DOWN_P)
				changeItem(1);

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;

					if (ClientPrefs.data.flashing)
						FlxFlicker.flicker(magenta, 1.1, 0.15, false);

					FlxFlicker.flicker(menuItems.members[curSelected], 1, 0.06, false, false, function(flick:FlxFlicker)
					{
						switch (optionShit[curSelected])
						{
							case 'story_mode':
								MusicBeatState.switchState(new StoryMenuState());
							case 'freeplay':
								MusicBeatState.switchState(new FreeplayState());

							#if MODS_ALLOWED
							case 'mods':
								MusicBeatState.switchState(new ModsMenuState());
							#end

							#if ACHIEVEMENTS_ALLOWED
							case 'awards':
								MusicBeatState.switchState(new AchievementsMenuState());
							#end

							case 'credits':
								MusicBeatState.switchState(new CreditsState());
							case 'options':
								MusicBeatState.switchState(new OptionsState());
								OptionsState.onPlayState = false;
								if (PlayState.SONG != null)
								{
									PlayState.SONG.arrowSkin = null;
									PlayState.SONG.splashSkin = null;
									PlayState.stageUI = 'normal';
								}
						}
					});

					for (i in 0...menuItems.members.length)
					{
						if (i == curSelected)
							continue;
						FlxTween.tween(menuItems.members[i], {alpha: 0}, 0.4, {
							ease: FlxEase.quadOut,
							onComplete: function(twn:FlxTween)
							{
								menuItems.members[i].kill();
							}
						});
					}
				}
			}
			else if (controls.justPressed('debug_1') || virtualPad.buttonE.justPressed)
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
		}

		super.update(elapsed);
	}

	function changeItem(huh:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));
		menuItems.members[curSelected].animation.play('idle');
		menuItems.members[curSelected].updateHitbox();
		menuItems.members[curSelected].screenCenter(X);

		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.members[curSelected].animation.play('selected');
		menuItems.members[curSelected].centerOffsets();
		menuItems.members[curSelected].screenCenter(X);

		camFollow.setPosition(menuItems.members[curSelected].getGraphicMidpoint().x,
			menuItems.members[curSelected].getGraphicMidpoint().y - (menuItems.length > 4 ? menuItems.length * 8 : 0));
	}
}
