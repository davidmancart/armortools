package arm;

import haxe.Json;
import haxe.io.Bytes;
import iron.data.Data;
#if arm_painter
import arm.ui.UITrait;
import arm.render.Inc;
#end

class Config {

	public static var raw:TConfig = null;
	public static var keymap:Dynamic; // raw.Keymap
	public static var configLoaded = false;

	public static function load(done:Void->Void) {
		try {
			Data.getBlob('config.arm', function(blob:kha.Blob) {
				configLoaded = true;
				raw = Json.parse(blob.toString());
				done();
			});
		}
		catch(e:Dynamic) { done(); }
	}

	public static function save() {
		var path = Data.dataPath + 'config.arm';
		var bytes = Bytes.ofString(Json.stringify(raw));
		Krom.fileSaveBytes(path, bytes.getData());
	}

	// public static function reset() {}

	public static function init():TConfig {
		if (!configLoaded) {
			raw.rp_bloom = false;
			raw.rp_gi = false;
			raw.rp_motionblur = false;
			raw.rp_ssgi = true;
			raw.rp_ssr = false;
			raw.rp_supersample = 1.0;
		}

		#if arm_painter
		if (raw.undo_steps == null) raw.undo_steps = 4; // Max steps to keep
		if (raw.keymap == null) {
			raw.keymap = {};
			raw.keymap.action_paint = "left";
			raw.keymap.action_rotate = "alt+left";
			raw.keymap.action_pan = "alt+middle";
			raw.keymap.action_zoom = "alt+right";
			raw.keymap.action_rotate_light = "shift+middle";
			raw.keymap.select_material = "shift+number";
			raw.keymap.cycle_layers = "ctrl+tab";
			raw.keymap.brush_radius = "f";
			raw.keymap.brush_opacity = "shift+f";
			raw.keymap.brush_ruler = "shift";
			raw.keymap.file_new = "ctrl+n";
			raw.keymap.file_open = "ctrl+o";
			raw.keymap.file_save = "ctrl+s";
			raw.keymap.file_save_as = "ctrl+shift+s";
			raw.keymap.file_reload_assets = "ctrl+r";
			raw.keymap.edit_undo = "ctrl+z";
			raw.keymap.edit_redo = "ctrl+shift+z";
			raw.keymap.view_reset = "0";
			raw.keymap.view_front = "1";
			raw.keymap.view_back = "ctrl+1";
			raw.keymap.view_right = "3";
			raw.keymap.view_left = "ctrl+3";
			raw.keymap.view_top = "7";
			raw.keymap.view_bottom = "ctrl+7";
			raw.keymap.view_camera_type = "5";
			raw.keymap.view_orbit_left = "4";
			raw.keymap.view_orbit_right = "6";
			raw.keymap.view_orbit_top = "8";
			raw.keymap.view_orbit_bottom = "2";
			raw.keymap.view_orbit_opposite = "9";
			raw.keymap.view_distract_free = "f11";
			raw.keymap.tool_brush = "b";
			raw.keymap.tool_eraser = "e";
			raw.keymap.tool_fill = "g";
			raw.keymap.tool_decal = "d";
			raw.keymap.tool_text = "t";
			raw.keymap.tool_clone = "l";
			raw.keymap.tool_blur = "u";
			raw.keymap.tool_particle = "p";
			raw.keymap.tool_bake = "k";
			raw.keymap.tool_colorid = "c";
			raw.keymap.tool_picker = "v";
			raw.keymap.toggle_2d_view = "shift+tab";
			raw.keymap.toggle_node_editor = "tab";
			raw.keymap.import_assets = "ctrl+shift+i";
			raw.keymap.export_textures = "ctrl+shift+e";
			raw.keymap.node_search = "space";
		}
		keymap = raw.keymap;
		#end

		return raw;
	}

	public static inline function getSuperSampleQuality(f:Float):Int {
		return f == 0.25 ? 0 :
			   f == 0.5 ? 1 :
			   f == 1.0 ? 2 :
			   f == 1.5 ? 3 :
			   f == 2.0 ? 4 : 5;
	}

	public static inline function getSuperSampleSize(i:Int):Float {
		return i == 0 ? 0.25 :
			   i == 1 ? 0.5 :
			   i == 2 ? 1.0 :
			   i == 3 ? 1.5 :
			   i == 4 ? 2.0 : 4.0;
	}

	#if arm_painter
	public static function applyConfig() {
		var C = Config.raw;
		C.rp_ssgi = UITrait.inst.hssgi.selected;
		C.rp_ssr = UITrait.inst.hssr.selected;
		C.rp_bloom = UITrait.inst.hbloom.selected;
		C.rp_gi = UITrait.inst.hvxao.selected;
		C.rp_supersample = getSuperSampleSize(UITrait.inst.hsupersample.position);
		iron.object.Uniforms.defaultFilter = C.rp_supersample < 1.0 ? kha.graphics4.TextureFilter.PointFilter : kha.graphics4.TextureFilter.LinearFilter;

		var current = @:privateAccess kha.graphics4.Graphics2.current;
		if (current != null) current.end();
		
		save();
		Inc.applyConfig();
		
		if (current != null) current.begin(false);
		Context.ddirty = 2;
	}

	public static function getTextureRes():Int {
		var resHandle = UITrait.inst.resHandle;
		if (resHandle.position == 0) return 128;
		if (resHandle.position == 1) return 256;
		if (resHandle.position == 2) return 512;
		if (resHandle.position == 3) return 1024;
		if (resHandle.position == 4) return 2048;
		if (resHandle.position == 5) return 4096;
		if (resHandle.position == 6) return 8192;
		if (resHandle.position == 7) return 16384;
		return 0;
	}

	public static function getTextureResBias():Float {
		var resHandle = UITrait.inst.resHandle;
		if (resHandle.position == 0) return 16.0;
		if (resHandle.position == 1) return 8.0;
		if (resHandle.position == 2) return 4.0;
		if (resHandle.position == 3) return 2.0;
		if (resHandle.position == 4) return 1.5;
		if (resHandle.position == 5) return 1.0;
		if (resHandle.position == 6) return 0.5;
		if (resHandle.position == 7) return 0.25;
		return 1.0;
	}

	public static function getTextureResPos(i:Int):Int {
		if (i == 128) return 0;
		if (i == 256) return 1;
		if (i == 512) return 2;
		if (i == 1024) return 3;
		if (i == 2048) return 4;
		if (i == 4096) return 5;
		if (i == 8192) return 6;
		if (i == 16384) return 7;
		return 0;
	}
	#end
}

typedef TConfig = {
	@:optional var window_mode:Null<Int>; // window, fullscreen
	@:optional var window_w:Null<Int>;
	@:optional var window_h:Null<Int>;
	@:optional var window_x:Null<Int>;
	@:optional var window_y:Null<Int>;
	@:optional var window_resizable:Null<Bool>;
	@:optional var window_maximizable:Null<Bool>;
	@:optional var window_minimizable:Null<Bool>;
	@:optional var window_vsync:Null<Bool>;
	@:optional var window_scale:Null<Float>;
	@:optional var rp_supersample:Null<Float>;
	@:optional var rp_ssgi:Null<Bool>;
	@:optional var rp_ssr:Null<Bool>;
	@:optional var rp_bloom:Null<Bool>;
	@:optional var rp_motionblur:Null<Bool>;
	@:optional var rp_gi:Null<Bool>;
	// Ext
	@:optional var version:Null<Int>;
	@:optional var plugins:Array<String>;
	@:optional var undo_steps:Null<Int>;
	@:optional var keymap:Dynamic; // Map<String, String>
}
