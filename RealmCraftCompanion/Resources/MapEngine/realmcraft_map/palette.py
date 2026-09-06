"""Original schematic colors, not textures from the game."""
import json
from pathlib import Path
import numpy as np

NAMES = {int(k): v for k, v in json.loads(Path(__file__).with_name('blocks.json').read_text()).items()}


def color(name):
    exact = {'air': '#000000', 'cave_air': '#000000', 'water': '#377ca9',
             'lava': '#f68431', 'grass_block': '#79a64d', 'dirt': '#987048',
             'coarse_dirt': '#8c6a47', 'podzol': '#745c38', 'sand': '#e2d29a',
             'red_sand': '#c87f49', 'bedrock': '#494c50', 'gravel': '#99938c',
             'netherrack': '#914d4e', 'soul_sand': '#71564a', 'soul_soil': '#584940',
             'snow': '#edf4f5', 'snow_block': '#edf4f5', 'ice': '#93c9df',
             'packed_ice': '#8cb5d9', 'blue_ice': '#65a8d2', 'glass': '#b4d9d7',
             'obsidian': '#39314e', 'crying_obsidian': '#594573', 'moss_block': '#688744',
             'clay': '#a6b2bf', 'diorite': '#c5c5bd', 'granite': '#ae8170',
             'andesite': '#999c96', 'cobblestone': '#888d86', 'stone': '#929892',
             'chest': '#c99645', 'crafting_table': '#a97940', 'farmland': '#795232'}
    if name in exact:
        return exact[name]
    if 'leaves' in name: return '#416e3c' if 'spruce' in name else '#548543'
    if any(s in name for s in ('grass', 'fern', 'sapling', 'vine', 'bamboo', 'azalea')): return '#7d9d46'
    if any(s in name for s in ('flower', 'tulip', 'orchid', 'dandelion', 'poppy')): return '#c4ac67'
    if any(s in name for s in ('water', 'kelp', 'seagrass')): return '#377ca9'
    if 'crimson' in name: return '#a34d68'
    if 'warped' in name: return '#428f85'
    if 'sandstone' in name or 'end_stone' in name: return '#d7c58e'
    if 'deepslate' in name or 'blackstone' in name or 'basalt' in name: return '#555862'
    if 'copper' in name: return '#5c9b85' if any(s in name for s in ('oxidized', 'weathered')) else '#ba8262'
    if any(s in name for s in ('planks', 'wood', 'log', 'fence', 'door')):
        if 'birch' in name: return '#d2bb85'
        if 'dark_oak' in name: return '#655034'
        if 'spruce' in name: return '#896c46'
        if 'acacia' in name: return '#b7754b'
        return '#b49660'
    dyes = {'white':'#e1e3dd', 'orange':'#da8d3b', 'magenta':'#b55ba7', 'light_blue':'#74b7d1',
            'yellow':'#dfc54c', 'lime':'#98b947', 'pink':'#d398ad', 'light_gray':'#afb1a8',
            'gray':'#676d70', 'cyan':'#45949d', 'purple':'#8663a4', 'blue':'#526da1',
            'brown':'#826244', 'green':'#668443', 'red':'#b6544b', 'black':'#343b41'}
    for dye, rgb in dyes.items():
        if name.startswith(dye + '_'): return rgb
    if 'brick' in name: return '#a47767'
    if 'quartz' in name: return '#e5dfd0'
    if 'amethyst' in name: return '#a08bb9'
    if 'gold' in name: return '#d2b951'
    if 'diamond' in name: return '#75c4c2'
    if 'lapis' in name: return '#4d70aa'
    if 'magma' in name: return '#c06f38'
    if 'stone' in name or 'ore' in name: return '#929892'
    return '#a69b84'


PALETTE = np.full((4096, 3), (219, 91, 192), dtype=np.uint8)
for block_id, name in NAMES.items():
    rgb = color(name).lstrip('#')
    PALETTE[block_id] = [int(rgb[i:i+2], 16) for i in (0, 2, 4)]
