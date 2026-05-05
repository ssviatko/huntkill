#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

/*
 * Maze format:
 *
 * Byte array of height, width
 * Bits in byte:
 * 7 = visited
 * 6 = top wall
 * 5 = left wall
 * 0-4 unused
 *
 */

extern void maze_init(uint64_t a_height, uint64_t a_width, uint8_t *array);
extern void maze_display(uint64_t a_height, uint64_t a_width, uint8_t *array, uint64_t a_height_scale, uint64_t a_width_scale);
extern void maze_generate(uint64_t a_height, uint64_t a_width, uint8_t *array);

int main(int argc, char **argv)
{
	if (argc != 6) {
		printf("usage: huntkill <height> <width> <cellheight> <cellwidth> <dumpfile>\n");
		exit(0);
	}

	unsigned int l_height = atoi(argv[1]);
	unsigned int l_width = atoi(argv[2]);
	unsigned int l_cellheight = atoi(argv[3]);
	unsigned int l_cellwidth = atoi(argv[4]);

	if (l_cellheight < 1) {
		printf("cellheight must be at least 1.\n");
		exit(0);
	}
	if (l_cellwidth < 3) {
		printf("cellwidth must be at least 3.\n");
		exit(0);
	}

	char *l_testary = NULL;
	l_testary = malloc(l_height * l_width);
	if (l_testary == NULL) {
		printf("unable to allocate maze array!\n");
		exit(-1);
	}

	maze_init(l_height, l_width, l_testary);
	maze_generate(l_height, l_width, l_testary);
	maze_display(l_height, l_width, l_testary, l_cellheight, l_cellwidth);

	int df = open(argv[5], O_CREAT | O_TRUNC | O_RDWR, S_IRUSR | S_IRGRP | S_IROTH | S_IWUSR);
	if (df < 0) {
		fprintf(stderr, "unable to open dump file: %s\n", strerror(errno));
		exit(-1);
	}
	int res = write(df, l_testary, l_height * l_width);
	if (res < 0) {
		fprintf(stderr, "unable to write dump file: %s\n", strerror(errno));
		exit(-1);
	}
	close(df);

	return 0;
}

