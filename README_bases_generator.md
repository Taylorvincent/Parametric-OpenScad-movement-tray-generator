# Parametric OpenScad Bases generator
![Bases generator](main_bases.png "Bases generator")

This is an [OpenScad](http://openscad.org/index.html) script that can generate square bases for Old school warhammer base system.

The script is absolutely parametric and can generate a custom square bases of any size (hollowed or solid) with slotta hole.

# Parameters

<img src="base_parameter.png" alt=parameter width="300" >

Extra features (hollow bases):

- `magnets_pipe_wall` — when magnets are enabled, a pipe hangs from the underside of the top so the magnet has something to press-fit into; this sets its wall thickness.
- `texture_top`, `texture_grain`, `texture_density`, `texture_seed` — grainy random texture on the top surface (same seed reproduces the same texture).
- `support_ribs`, `rib_width` — X-shaped ribs from the magnet pipe out to the corners, stiffening the hollow underside.

## Some example 

Slotta

<img src="base_a.png" alt=base_a width="300" >
<img src="base_b.png" alt=base_b width="300" >
<img src="base_c.png" alt=base_c width="300" >

Plain

<img src="base_d.png" alt=base_d width="300" >
