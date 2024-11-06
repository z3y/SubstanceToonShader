import lib-sampler.glsl
import lib-emissive.glsl
import lib-utils.glsl
import lib-pbr.glsl

//: param auto channel_basecolor 
uniform SamplerSparse basecolor_tex;
//: param auto channel_roughness
uniform SamplerSparse roughness_tex;

//: param custom {
//:  "default": [1.0, 1.0, 1.0],
//:  "label": "Light Color",
//:  "widget": "color"
//: }
uniform vec3 light_color;

//: param custom {
//:  "default": [0.82, 0.76, 0.85],
//:  "label": "Shadow Color",
//:  "widget": "color"
//: }
uniform vec3 shadow_color;

//: param custom { 
//:  "default": 0.5, 
//:   "min": 0.0,
//:   "max": 1.0,
//:   "label": "Shadow Border" 
//: } 
uniform float shadow_border;

//: param custom { 
//:  "default": 0.1, 
//:   "min": 0.0,
//:   "max": 1.0,
//:   "label": "Shadow Blur" 
//: } 
uniform float shadow_blur;

//: param custom { 
//:  "default": false,
//:   "label": "Emission Multiply Base" 
//: } 
uniform bool emission_multiply_base;

//: param custom {
//:  "default": [90.0, 90.0, 12.54],
//:  "label": "Light Direction", "min": -180, "max": 180
//: }
uniform vec3 light_direction;

//: param custom { 
//:  "default": false,
//:   "label": "Specular" 
//: } 
uniform bool specular_enabled;

//: param custom { 
//:  "default": 0.5, 
//:   "min": 0.0,
//:   "max": 1.0,
//:   "label": "Specular Border" 
//: } 
uniform float specular_border;

//: param custom { 
//:  "default": 0.1, 
//:   "min": 0.0,
//:   "max": 1.0,
//:   "label": "Specular Blur" 
//: } 
uniform float specular_blur;

#define saturate(x) clamp(x, 0.0, 1.0)

float lilTooningNoSaturateScale(float aascale, float value, float border, float blur, float borderRange)
{
    float borderMin = saturate(border - blur * 0.5 - borderRange);
    float borderMax = saturate(border + blur * 0.5);
    return (value - borderMin) / saturate(borderMax - borderMin + fwidth(value) * aascale);
}

void shade(V2F inputs) {
    vec3 normalWS = computeWSNormal(inputs.tex_coord, inputs.tangent, inputs.bitangent, inputs.normal);
    vec3 albedo = getBaseColor(basecolor_tex, inputs.sparse_coord);
    vec3 lightColor = light_color * vec3(sqrt(0.5));
    vec3 color = lightColor;
    vec3 emission = pbrComputeEmissive(emissive_tex, inputs.sparse_coord);
    // color += emission;
    vec3 lightDirection = normalize(light_direction);
    vec2 lns;
    lns.xy = vec2(saturate(dot(normalWS, lightDirection) * 0.5 + 0.5));
    lns.x = lilTooningNoSaturateScale(1, lns.x, shadow_border, shadow_blur, 0.0);
    lns.y = lilTooningNoSaturateScale(0, lns.y, shadow_border, shadow_blur, 0.08);

    lns = saturate(lns);

    color = mix(color, mix(color * shadow_color, color, vec3(lns.x)), 1.0);
    vec3 shadow_border_color = vec3(1,0,0);
    color = mix(color, lightColor, lns.y * shadow_border_color);

    float NoL = saturate(dot(normalWS, lightDirection));
    vec3 viewDirectionWS = getEyeVec(inputs.position);
    vec3 halfVector = normalize(lightDirection + viewDirectionWS);
    float LoH = saturate(dot(lightDirection, halfVector));
	float NoH = saturate(dot(normalWS, halfVector));

    float roughness = getRoughness(roughness_tex, inputs.sparse_coord);
    roughness = max((roughness * roughness), 0.002);

	vec3 specular = saturate(lilTooningNoSaturateScale(1, pow(NoH, 1.0 / roughness), specular_border, specular_blur, 0.0)) * lightColor;

    color *= albedo;
    if (emission_multiply_base)
    {
        emission *= albedo;
    }
    // color += emission;
    if (specular_enabled)
    {
        specularShadingOutput(specular);
    }
    emissiveColorOutput(emission);
    diffuseShadingOutput(color);
}

/*
MIT License

Copyright (c) 2020-2024 lilxyzw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/