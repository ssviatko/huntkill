#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define MAZE_WIDTH 50
#define MAZE_HEIGHT 30

typedef struct {
	int visited;
	int oob;
	int left_wall;
	int top_wall;
} maze_cell_t;

typedef struct {
	maze_cell_t maze[MAZE_HEIGHT + 1][MAZE_WIDTH + 1];
	unsigned int traverse_h;
	unsigned int traverse_w;
} maze_t;

typedef struct {
	int offset_h;
	int offset_w;
} unvis_neigh_t;

maze_t m1;

void maze_init(maze_t *m)
{
	unsigned int i, j;

	for (i = 0; i < MAZE_HEIGHT; ++i) {
		for (j = 0; j < MAZE_WIDTH; ++j) {
			m->maze[i][j].visited = 0;
			m->maze[i][j].oob = 0;
			m->maze[i][j].left_wall = 1;
			m->maze[i][j].top_wall = 1;
		}
		m->maze[i][MAZE_WIDTH].visited = 0;
		m->maze[i][MAZE_WIDTH].oob = 1;
		m->maze[i][MAZE_WIDTH].left_wall = 1;
		m->maze[i][MAZE_WIDTH].top_wall = 0;
	}
	for (j = 0; j < MAZE_WIDTH; ++j) {
		m->maze[MAZE_HEIGHT][j].visited = 0;
		m->maze[MAZE_HEIGHT][j].oob = 1;
		m->maze[MAZE_HEIGHT][j].left_wall = 0;
		m->maze[MAZE_HEIGHT][j].top_wall = 1;
	}
}

void maze_display(maze_t *m)
{
	unsigned int i, j, k;

	for (i = 0; i <= MAZE_HEIGHT; ++i) {
		for (j = 0; j <= MAZE_WIDTH; ++j) {
			if (m->maze[i][j].top_wall > 0) {
				printf("---");
			} else {
				printf("   ");
			}
		}
		printf("\n");
		for (k = 0; k < 1; ++k) {
			for (j = 0; j <= MAZE_WIDTH; ++j) {
				if (m->maze[i][j].left_wall > 0) {
					printf("|  ");
				} else {
					printf("   ");
				}
			}
			printf("\n");
		}
	}
}

int maze_hunt_check(maze_t *m, unsigned int h, unsigned int w)
{
//	printf("maze_hunt_check checking h=%d w=%d\n", h, w);
	if (m->maze[h][w].visited == 0) {
//		printf("Found unvisited cell h=%d w=%d\n", h, w);
		if (h > 0) {
			// check up neighbor
			if (m->maze[h - 1][w].visited = 1) {
				m->traverse_h = h;
				m->traverse_w = w;
				m->maze[h][w].visited = 1;
				m->maze[h][w].top_wall = 0;
				return 1;
			}
		}
		if (w > 0) {
			// check left neighbor
			if (m->maze[h][w - 1].visited = 1) {
				m->traverse_h = h;
				m->traverse_w = w;
				m->maze[h][w].visited = 1;
				m->maze[h][w].left_wall = 0;
				return 1;
			}
		}
		if (w < MAZE_WIDTH - 1) {
			// check right neighbor
			if (m->maze[h][w + 1].visited = 1) {
				m->traverse_h = h;
				m->traverse_w = w;
				m->maze[h][w].visited = 1;
				m->maze[h][w + 1].left_wall = 0;
				return 1;
			}
		}
		if (h < MAZE_HEIGHT - 1) {
			// check down neighbor
			if (m->maze[h + 1][w].visited = 1) {
				m->traverse_h = h;
				m->traverse_w = w;
				m->maze[h][w].visited = 1;
				m->maze[h + 1][w].top_wall = 0;
				return 1;
			}
		}
	}
	return 0;
}

int maze_hunt(maze_t *m)
{
	unsigned int h, w;
	unsigned int start_h = rand() % MAZE_HEIGHT;
	unsigned int start_w = rand() % MAZE_WIDTH;

//	printf("starting hunt at h=%d w=%d\n", start_h, start_w);
	// find an unvisited cell with a visited neighbor
	for (h = start_h; h < MAZE_HEIGHT; ++h) {
		for (w = start_w; w < MAZE_WIDTH; ++w) {
			if (maze_hunt_check(m, h, w) == 1) {
				return 1;
			}
		}
	}
	for (h = 0; h < MAZE_HEIGHT; ++h) {
		for (w = 0; w < MAZE_WIDTH; ++w) {
			if ((h == start_h) && (w == start_w)) {
				break;
			}
			if (maze_hunt_check(m, h, w) == 1) {
				return 1;
			}
		}
	}
	
	// made it down here without finding a visited neighbor
//	printf("no visited neighbors!\n");
//	maze_display(m);
	return 0;
}

void maze_traverse(maze_t *m)
{
	do {
		unvis_neigh_t nl[4];
		unsigned int num_unvis_neighs = 0;
		// check up neighbor
		if (m->traverse_h > 0) {
			if (m->maze[m->traverse_h - 1][m->traverse_w].visited == 0) {
				nl[num_unvis_neighs].offset_h = -1;
				nl[num_unvis_neighs].offset_w = 0;
				++num_unvis_neighs;
			}
		}
		// check left neighbor
		if (m->traverse_w > 0) {
			if (m->maze[m->traverse_h][m->traverse_w - 1].visited == 0) {
				nl[num_unvis_neighs].offset_h = 0;
				nl[num_unvis_neighs].offset_w = -1;
				++num_unvis_neighs;
			}
		}
		// check right neighbor
		if (m->traverse_w < MAZE_WIDTH - 1) {
			if (m->maze[m->traverse_h][m->traverse_w + 1].visited == 0) {
				nl[num_unvis_neighs].offset_h = 0;
				nl[num_unvis_neighs].offset_w = 1;
				++num_unvis_neighs;
			}
		}
		// check down neighbor
		if (m->traverse_h < MAZE_HEIGHT - 1) {
			if (m->maze[m->traverse_h + 1][m->traverse_w].visited == 0) {
				nl[num_unvis_neighs].offset_h = 1;
				nl[num_unvis_neighs].offset_w = 0;
				++num_unvis_neighs;
			}
		}

		if (num_unvis_neighs == 0) {
			// didn't find any neighbors
			break;
		}
		// choose random neighbor
		unsigned int rand_neighbor = rand() % num_unvis_neighs;
//		printf("chose random neighbor %d out of %d off_h=%d off_w=%d\n", rand_neighbor, num_unvis_neighs, nl[rand_neighbor].offset_h, nl[rand_neighbor].offset_w);
		// break down wall to random neighbor
		if (nl[rand_neighbor].offset_h == -1) {
			m->maze[m->traverse_h][m->traverse_w].top_wall = 0;
		}
		if (nl[rand_neighbor].offset_w == -1) {
			m->maze[m->traverse_h][m->traverse_w].left_wall = 0;
		}
		if (nl[rand_neighbor].offset_w == 1) {
			m->maze[m->traverse_h][m->traverse_w + 1].left_wall = 0;
		}
		if (nl[rand_neighbor].offset_h == 1) {
			m->maze[m->traverse_h + 1][m->traverse_w].top_wall = 0;
		}
		// mark ourselves as visited
		m->maze[m->traverse_h][m->traverse_w].visited = 1;
		// traverse
		m->traverse_h += nl[rand_neighbor].offset_h;
		m->traverse_w += nl[rand_neighbor].offset_w;
//		printf("moved to h=%d w=%d\n", m->traverse_h, m->traverse_w);
	} while (1);
}

void maze_generate(maze_t *m)
{
	// randomize the very first cell
	m->traverse_h = rand() % MAZE_HEIGHT;
	m->traverse_w = rand() % MAZE_WIDTH;
	m->maze[m->traverse_h][m->traverse_w].visited = 1;

	do {
		// traverse until we get backed into a corner
		maze_traverse(m);
//		maze_display(m);
		// if our hunt algorithm fails to find a cell,
		// then we are finished.
		if (maze_hunt(m) == 0) break;
//		maze_display(m);
	} while (1);
}

int main(int argc, char **argv)
{
	srand(time(NULL));
	maze_init(&m1);
	maze_generate(&m1);
	maze_display(&m1);
	return 0;
}

