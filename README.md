### BRDF and Subsurface Scattering
* GPU Gems 3 - https://developer.nvidia.com/gpugems/gpugems3/part-iii-rendering/chapter-14-advanced-techniques-realistic-real-time-skin
* Pre-Integrated Skin Shading - https://huangx916.github.io/2019/06/08/sss/

### Translucency 
* Real-Time Realistic Skin Translucency: http://iryoku.com/translucency/

Fake function in Testing:
```cpp
half3 transColor = 0;
transColor.r = 0.7 * (d - 1) * (d - 1) + 0.3;
transColor.gb = exp(- d * d / 0.03);
```