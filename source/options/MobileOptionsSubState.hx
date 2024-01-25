package options;

class MobileOptionsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Mobile Options';
		rpcTitle = 'Mobile Options Menu'; // for Discord Rich Presence, fuck it

		#if mobile
		var option:Option = new Option('Allow Phone Screensaver', 'If checked, the phone will sleep after going inactive for few seconds', 'screensaver',
			'bool');
		option.onChange = () ->
		{
			lime.system.System.allowScreenTimeout = curOption.getValue();
		};
		addOption(option);
		#end

		var option:Option = new Option('Hitbox Position', 'If checked, the hitbox will be put at the bottom of the screen, otherwise will stay at the top.',
			'hitbox2', 'bool');
		addOption(option);

		var option:Option = new Option('Extra Controls',
			'Select how many extra buttons you prefere to have\nThey can be used for mechanics with LUA or HScript.', 'extraButtons', 'string',
			["NONE", "SINGLE", "DOUBLE"]);
		addOption(option);

		var option:Option = new Option('Dynamic Controls Color',
			'If checked, the mobile controls color will be set to the notes color in your settings.\n(have effect during gameplay only)', 'dynamicColors',
			'bool');
		addOption(option);

		var option:Option = new Option('Mobile Controls Opacity', 'How much transparent should the Mobile Controls be.', 'controlsAlpha', 'percent');
		option.scrollSpeed = 1;
		option.minValue = 0.001;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = () ->
		{
			virtualPad.alpha = curOption.getValue();
		};
		addOption(option);

		super();
	}
}
