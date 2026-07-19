#version 330

// From Usagi Examples
// https://github.com/brettchalupa/usagi/tree/main/examples/shader/shaders

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;

uniform float u_time;
uniform float u_scanline;
uniform vec2 u_resolution;

// Added by me (ceigey)
// Controls for curve if you really wanna mess with them.
uniform vec2 u_curve;
// 1 = don't curve, 0 = curve
uniform bool u_flat;
// Chromatic abberation
// Usagi default was 0.0015, 0.0010 sits better IMO.
// 0 = off
uniform float u_ca;
// 0.4 default
// 0 = off
uniform float u_scanline_strength;
uniform bool u_vertical_scanlines;


out vec4 finalColor;

vec2 curve(vec2 uv) {
    uv = uv * 2.0 - 1.0;
    if (!u_flat) {
        float cx = u_curve.x == 0 ? 8.0 : u_curve.x;
        float cy = u_curve.y == 0 ? 6.0 : u_curve.y;
        vec2 offset = abs(uv.yx) / vec2(cx, cy);
        uv = uv + uv * offset * offset;
    }
    return uv * 0.5 + 0.5;
}

void main() {
    vec2 uv = curve(fragTexCoord);

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        finalColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    float ca = u_ca; // 0.0010; // originally 0.0015;
    vec3 col;
    col.r = texture(texture0, uv + vec2(ca, 0.0)).r;
    col.g = texture(texture0, uv).g;
    col.b = texture(texture0, uv - vec2(ca, 0.0)).b;

    float scan = sin(uv.y * u_resolution.y * 3.14159 * 2.0);
    col *= 1.0 - u_scanline * u_scanline_strength * (0.5 - 0.5 * scan);

    if (u_vertical_scanlines) {
        float scanx = sin(uv.x * u_resolution.x * 3.14159 * 2.0);
        col *= 1.0 - u_scanline * u_scanline_strength * (0.5 - 0.5 * scanx);
    }

    vec2 v = (fragTexCoord - 0.5);
    float vig = 1.0 - dot(v, v) * 1.2;
    col *= clamp(vig, 0.0, 1.0);

    col *= 0.97 + 0.03 * sin(u_time * 6.0 + uv.y * 8.0);

    finalColor = vec4(col, 1.0);
}
