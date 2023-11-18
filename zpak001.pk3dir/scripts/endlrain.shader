streetglass
{

if $programs
	polygonOffset 1
	diffusemap "textures/sfx/mirror.tga"
	normalmap "textures/sfx/mirror_n.tga"

	{
		program lightmapped_reflect
		map $reflection
	}
	{
		map textures/sfx/reflection.tga
		blendFunc filter
		tcGen environment
	}
else
	portal
endif
}
