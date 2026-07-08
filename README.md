# Love Life

Conway's Game of Life in Lua LÖVE

## Run

From the repo root:

```bash
love .
```

Requires [LÖVE 11.x](https://love2d.org/).

## Milestone 1 (current)

- Configurable grid (`src/config.lua`: `rows`, `cols`, `tileSize`, `activeTheme`)
- Themes: `classic`, `zenburn`, `solarized` (`src/themes.lua`)
- Toroidal Conway B3/S23 with next-generation preview dots
- Centered board in resizable window (space reserved for future bottom status bar)

## Features

1. Configurable board sizes
2. Animations and Next Round previews
3. Multiple color schemes
4. Alternate rule strings
  - Rule strings are `Bx/Sy` where `x` refers to the number of cells that allow a cell to be born, and `y` refers to the number of cells required for survival
  - Classic Game of Life has the universe string `B3/S23`: A dead cell with exactly 2 neighbors will be born next round, and a cell with exactly 2 or 3 neighbors will survive the next round. A live cell with 0 or 1 neighbors will die of loneliness, and a live cell with 4 or more neighbors will die of overcrowding
  - Another life string `B3/S234` is called the Ant Colony Life, as the board begins to resemble an ant farm: the edges gradually expand, while the center gradually settles down, resembling an ant colony
5. Video export: gif or mp4 (or some kind of simple video) showing the evolution of the board over a specified number of generations

### Attribution

The idea for this came from the youtube video [The Conway Multiverse](https://www.youtube.com/watch?v=QK_KZv-YyOc&pp=ygURY29ud2F5IG11bHRpdmVyc2U%3D) by user [carykh](https://www.youtube.com/@carykh)
