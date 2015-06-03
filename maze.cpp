#include <cstdio>
#include <cstring>

using namespace std;

#define size 5

char maze[size][size] = {{'X','_','_','_','_'},
                         {'_','#','#','#','#'},
                         {'_','_','_','_','_'},
                         {'#','#','#','#','_'},
                         {'#','#','#','#','X'}};

bool vis[size][size];

int pos[4][2] = {{0, -1},
                 {0,  1},
                 {-1, 0},
                 { 1, 0}};

int step = -1; 

void printmaze() {
    for (int i = 0; i < size; ++i) {
        for (int j = 0; j < size; ++j) {
            printf("%c",maze[i][j]);
        }
        printf("\n");
    }
    printf("\n");
}

bool dfs(int x, int y) {
    vis[x][y] = true;
    for (int i = 0; i < 4; i++) {
        int novox = x+pos[i][0];
        int novoy = y+pos[i][1];
        if (novox >= 0 && novox < size && novoy >= 0 && novoy < size && !vis[novox][novoy]) {
            if (maze[novox][novoy] == 'X') return true;
            if (maze[novox][novoy] == '_') {
                maze[novox][novoy] = 'o';
                if (step < 0) printmaze();
                if (dfs(novox, novoy)) return true;
                maze[novox][novoy] = '_';
                if (step < 0) printmaze();
            }
        }
    }
    return false;
}

int main() {
    memset(vis, 0, sizeof(vis));
    printf("Labirinto Original:\n\n");
    printmaze();
    if (dfs(0, 0)) {
        printf("Solução do Labirinto:\n\n");
        printmaze();
    }
    else {
        printf("O Labirinto não possui solução.\n");
    }
    return 0;
}