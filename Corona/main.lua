-- SoX plugin API reference
-- local sox = require('plugin.sox')

-- sox.init([params]) - init the plugin, returns true on success.
-- params - optional params for SoX configuration.
-- params.verbosity - log levels: 'none', 'fail', 'warn', 'report', 'debug', 'debug_more', 'debug_most'. Warn is default.
-- params.temporary_directory -- path to temporay directory, used by some effects.
-- params.buffer_size - size (in bytes) used for blocks of sample data.
-- params.input_buffer_size - size (in bytes) used for blocks of input sample data.
-- params.use_threads - boolean, set to true to use threading.

-- sox.quit() - release plugin resources, if needed.

-- sox.process(params) - apply effects to an input file and write to the output file.
-- params.input - path to the input file.
-- params.output - path to the output file.
-- params.effects - the chain of effects to be applied. Each entry is a table
--   effect.name - name of the effect.
--   effect.params - (optional) parameters for the effect.

display.setStatusBar(display.HiddenStatusBar)

local json = require('json')
local widget = require('widget')
local sox = require('plugin.sox')

display.setDefault('background', 1)

local xl, xr, y = display.contentWidth * .25, display.contentWidth * .75, display.contentCenterY
local w, h = display.contentWidth * 0.4, 50

widget.newButton{
	x = xl, y = y - 200,
	width = w, height = h,
	label = 'init()',
	onRelease = function()
		print('init()')
		local success = sox.init{
			verbosity = 'debug_most',
			temporary_directory = system.pathForFile(nil, system.TemporaryDirectory),
			buffer_size = 32768,
			input_buffer_size = 32768,
			use_threads = true
		}
		if not success then
			print('Failed to init the sox plugin.')
		end
	end}

widget.newButton{
	x = xr, y = y - 200,
	width = w, height = h,
	label = 'quit()',
	onRelease = function()
		print('quit()')
		sox.quit()
	end}

widget.newButton{
	x = xl, y = y - 120,
	width = w, height = h,
	label = 'Play original',
	onRelease = function()
		local audio_file = audio.loadSound('sample.wav', system.ResourceDirectory)
		if audio_file then
			print('Audio file started.')
			audio.play(audio_file, {onComplete = function()
				print('Audio file ended.')
				audio.dispose(audio_file)
			end})
		else
			print('Audio file does not exist')
		end
	end}

widget.newButton{
	x = xr, y = y - 120,
	width = w, height = h,
	label = 'Play result',
	onRelease = function()
		local audio_file = audio.loadSound('result.wav', system.DocumentsDirectory)
		if audio_file then
			print('Audio file started.')
			audio.play(audio_file, {onComplete = function()
				print('Audio file ended.')
				audio.dispose(audio_file)
			end})
		else
			print('Audio file does not exist')
		end
	end}

widget.newButton{
	x = xl, y = y - 40,
	width = w, height = h,
	label = 'Contrast 50',
	onRelease = function()
		sox.process{
			input = system.pathForFile('sample.wav', system.ResourceDirectory),
			output = system.pathForFile('result.wav', system.DocumentsDirectory),
			effects = {
				{name = 'contrast', params = '50'}
			}
		}
	end}

widget.newButton{
	x = xr, y = y - 40,
	width = w, height = h,
	label = 'Normalize',
	onRelease = function()
		sox.process{
			input = system.pathForFile('sample.wav', system.ResourceDirectory),
			output = system.pathForFile('result.wav', system.DocumentsDirectory),
			effects = {
				{name = 'gain', params = '-n'}
			}
		}
	end}

widget.newButton{
	x = xl, y = y + 40,
	width = w, height = h,
	label = 'Trim',
	onRelease = function()
		sox.process{
			input = system.pathForFile('sample.wav', system.ResourceDirectory),
			output = system.pathForFile('result.wav', system.DocumentsDirectory),
			effects = {
				{name = 'trim', params = '3 6'}
			}
		}
	end}

widget.newButton{
	x = xr, y = y + 40,
	width = w, height = h,
	label = 'Norm + Cont',
	onRelease = function()
		sox.process{
			input = system.pathForFile('sample.wav', system.ResourceDirectory),
			output = system.pathForFile('result.wav', system.DocumentsDirectory),
			effects = {
				{name = 'gain', params = '-n'},
				{name = 'contrast', params = '50'}
			}
		}
	end}
