#version 450

uniform vec2 screenSizeInv;

in vec2 pos;

out vec2 texCoord;
out vec4 offset;

#if defined(HLSL) || defined(METAL) || defined(SPIRV)
#define V_DIR(v) -(v)
#else
#define V_DIR(v) v
#endif

void main() {
	// Scale vertex attribute to [0-1] range
	const vec2 madd = vec2(0.5, 0.5);
	texCoord = pos.xy * madd + madd;
	#if defined(HLSL) || defined(METAL) || defined(SPIRV)
	texCoord.y = 1.0 - texCoord.y;
	#endif

	// Neighborhood Blending Vertex Shader
	offset = screenSizeInv.xyxy * vec4(1.0, 0.0, 0.0, V_DIR(1.0)) + texCoord.xyxy;
	gl_Position = vec4(pos.xy, 0.0, 1.0);
}
