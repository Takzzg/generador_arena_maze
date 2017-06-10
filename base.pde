float density = .5; //walls density
float doubleDensity = .2; //double walls in a cell density
float blackCell = .03; //black cells density
float victimDensity = .2; //victims density
float checkpoint = .015; //checkpoint density
int xSize;
int ySize;

Robot robot = new Robot(0, 0);
Cell lastCheckpoint = new Cell(0, 0, 0);
Cell[] history = new Cell[0];
Cell[][][] arena; //creates arena
Cell example = new Cell(0, 0, 0);
//--------------------------------------------------------------------------------  SETUP  ----------------------------------------------------------------------------
void setup() {
  int px, py;

  size(1200, 600); //screen size
  xSize = int((width)/2/example.wid); //arena width
  ySize = int((height)/example.wid); //arena height
  frameRate(60);
  arena = new Cell[5][ySize][xSize]; //bigger arena = bigger cells

  for (int h = 0; h < 5; h++) {
    for (int i = 0; i < ySize; i++) {
      for (int j = 0; j < xSize; j++) {
        arena[h][i][j] = new Cell(h, j, i); //creates the cells
      }
    }
  }

  for (int h = 0; h < 4; h++) {
    int place = 0;
    switch(int(random(4))) { //randomly places the ramps/entrances to the other levels/rooms

    case 0: //places an exit at the top of the arena
      while (arena[h][0][place].black || arena[h+1][0][place].black || place == 0) place = int(random(ySize));
      arena[h][0][place].exit = true;
      arena[h+1][0][place].exit = true;
      break;

    case 1:  //places an exit a the bottom of the arena
      while (arena[h][ySize-1][place].black || arena[h+1][ySize-1][place].black || place == 0) place = int(random(ySize));
      arena[h][ySize-1][place].exit = true;
      arena[h+1][ySize-1][place].exit = true;
      break;

    case 2: //places an exit on the left face of the arena
      while (arena[h][place][0].black || arena[h+1][place][0].black || place == 0) place = int(random(xSize));
      arena[h][place][0].exit = true;
      arena[h+1][place][0].exit = true;
      break;

    default: //places an exit on the right face of the arena
      while (arena[h][place][xSize-1].black || arena[h+1][place][xSize-1].black || place == 0) place = int(random(xSize));
      arena[h][place][xSize-1].exit = true;
      arena[h+1][place][xSize-1].exit = true;
    }
  }

  do { //places the robot on an empty cell at a random height next to a random wall
    if (random(1) > 0.5) {
      if (random(1) > 0.5) px = 0;
      else px = xSize-1;
      py = int(random(ySize));
    } else {
      if (random(1) > 0.5) py = 0;
      else py = ySize-1;
      px = int(random(xSize));
    }
  } while (arena[0][py][px].black || arena[0][py][px].exit);
  robot = new Robot(px, py);

  arena[robot.z][py][px].start = true; //sets the cell where the robot starts as the start cell
  arena[robot.z][py][px].visited = true; //sets the start cell as visited
  robot.start(); //starts the robot
  robot.dibujar(0); //draws the robot in the arena
  robot.dibujar(xSize); //draws the robot's path on the right of the screen
  lastCheckpoint = arena[robot.z][py][px]; //sets the starting cell as the last checkpoint visited
}
//--------------------------------------------------------------------------------  SETUP  ----------------------------------------------------------------------------
//--------------------------------------------------------------------------------  DRAW  ----------------------------------------------------------------------------
void draw() {
  background(255, 255, 240); //background color
  frameRate(60);
  fill(0); 
  text(robot.z, 20, 20); //shows the floor number 
  text(robot.floorDir, 20, 40); //shows the direccion the robot is going (up or down according to z)
  robot.recorrer(); 

  for (int i = 0; i < ySize; i++) {
    for (int j = 0; j < xSize; j++) {
      arena[robot.z][i][j].dibujar(0); //draws the cells
      if (arena[robot.z][i][j].visited)arena[robot.z][i][j].dibujar(xSize); //visited cells duplicate on the right of the screen
    }
  }

  robot.dibujar(0); //draws the robot in both sides of the screen
  robot.dibujar(xSize);
}
//--------------------------------------------------------------------------------  DRAW  ----------------------------------------------------------------------------
//--------------------------------------------------------------------------------  CELL  ----------------------------------------------------------------------------
class Cell {
  boolean north = false; //sets all cell´s variables to false (= blank cell)
  boolean south = false;
  boolean east = false;
  boolean west = false;
  boolean check = false;
  boolean visited = false;
  boolean start = false;
  boolean black = false;
  boolean exit = false;
  boolean deleted = false;
  boolean oneKit = false;
  boolean twoKits = false;
  boolean out = false;
  char victim = 'F';
  char victimStatus = 'F';
  char[] instructions = {};
  int weight = 9999; //sets a sealing for the weight to compare to
  int x, y, z, wid = 30; //wid = width of the cells
  int px, py;

  Cell(int bz, int bx, int by) { 
    x = bx;
    y = by;
    z = bz;
    if (by == 0)//draws a wall all along the top side of the arena
      north = true;
    else if (arena[z][by-1][bx].south) //also draws a north wall if the cell above the current one has a south wall
      north = true;
    if (bx == 0)//draws a wall all along the left side of the arena
      west = true;
    else if (arena[z][by][bx-1].east) //also draws a left wall if the cell to the right of the current one has a right wall
      west = true;
    if (by == ySize-1)//draws a wall all along the bottom of the arena
      south = true;
    if (bx == xSize-1)//draws a wall all along the right side of the arena
      east = true; 

    if (random(1) < blackCell) black=true; //randomly makes black cells
    if (random(1) < checkpoint) check = true; //randomly makes checkpoints

    if (random(1) < density) { //randomly draws walls on the cells
      if (random(1) < doubleDensity && (!west || !north)) { //if true the cell has both south and west walls
        south = true;
        east = true;
      } else if (random(1) < 0.5) south = true;//else if true only has a south wall
      else east = true;//else only has a west wall
    }

    if (random(1) < victimDensity && !black && !start && !check) { //randomly places victims on the cells
      if (random(1) < 0.3)victimStatus = 'U'; //if true the victim´s status is UNHARMED
      else if (random(1) < 0.5)victimStatus = 'S'; //if true the victim´s status is STABLE
      else victimStatus = 'H'; //else the victim's status is HARMED
      int w = int(random(4));
      switch(w) { //randomly decides in which wall the victim is going to be placed
      case 1:
        victim = 'N';
        if (north)break;
      case 2:
        victim = 'E';
        if (east)break;
      case 3:
        victim = 'S';
        if (south)break;
      default:
        victim = 'W';
        if (!west)victim = 'F';
      }
    }
  }

  void dibujar(int off) {//draws the cells. off is the offset where the cell must be drawn (it's added to x and substracted before ending)
    x+=off;
    px+=off;
    strokeWeight(2);
    stroke(0);
    if (north)line(x*wid, y*wid, (x+1)*wid, y*wid);//north wall
    if (east)line((x+1)*wid, y*wid, (x+1)*wid, (y+1)*wid);//east wall
    if (south) line(x*wid, (y+1)*wid, (x+1)*wid, (y+1)*wid);//south wall
    if (west)line(x*wid, y*wid, x*wid, (y+1)*wid);//west wall

    strokeWeight(0); //grey grid
    stroke(0, 50);
    if (!north) line(x*wid, y*wid, (x+1)*wid, y*wid);
    if (!east) line((x+1)*wid, y*wid, (x+1)*wid, (y+1)*wid);

    if (victimStatus != 'F') { //if there's a victim
      if (victimStatus == 'H')fill(255, 0, 0); //sets the color for the victim
      if (victimStatus == 'S')fill(255, 255, 0);
      if (victimStatus == 'U')fill(0, 255, 0);
      strokeWeight(0);
      switch(victim) { //and draws it
      case 'N':
        rect(x*wid +10, y*wid +2, 10, 5);
        break;
      case 'E':
        rect(x*wid +24, y*wid +10, 5, 10);
        break;
      case 'S':
        rect(x*wid +10, y*wid +24, 10, 5);
        break;
      case 'W':
        rect(x*wid +2, y*wid +10, 5, 10);
      }
    }

    if (visited && off != 0) { //if the cell is visited draws a green square on top of it on the right side of the screen
      stroke(50, 170, 50, 100);
      strokeWeight(2);
      fill(50, 170, 50, 50);
      rect(x*wid+6, y*wid+6, wid-12, wid-12);
    }
    if (start) { //if it's the starting cell, draws a bright green square on top of it
      strokeWeight(2);
      fill(0, 255, 0, 200);
      stroke(0, 255, 0);
      rect(x*wid+3, y*wid+3, wid-6, wid-6);
    }
    if (check) { //if it´s a checkpoint draws a <3 PINK <3 square on top of it
      stroke(255, 200, 200);
      fill(255, 200, 200, 250);
      strokeWeight(2);
      rect(x*wid+3, y*wid+3, wid-6, wid-6);
    }
    if (black) { //if it's a black cell, draws a clack square on top of it
      stroke(0);
      strokeWeight(2);
      fill(0, 200);
      rect(x*wid+3, y*wid+3, wid-6, wid-6);
    }
    if (exit) { //if it's an exit, draws a bright blue square on top of it
      strokeWeight(2);
      stroke(0, 0, 255);
      fill(0, 0, 255, 200);
      rect(x*wid+5, y*wid+5, wid-10, wid-10);
    } 
    if (deleted) { //if the exit has been deleted, draws a bright blue X where the exit was
      strokeWeight(2);
      stroke(0, 0, 255);
      line(x*wid+5, y*wid+5, x*wid+wid-5, y*wid+wid-5);
      line(x*wid+wid-5, y*wid+5, x*wid+5, y*wid+wid-5);
    }
    if (oneKit) { //if the robot placed a kit on this cell, a small green and yellow square will appear 
      stroke(0, 255, 0);
      strokeWeight(2);
      fill(255, 255, 0);
      rect(x*wid+10, y*wid +10, 10, 10);
    }
    if (twoKits) { //if the robot placed two kits here, two smaller green and yellow squares will appear
      stroke(0, 255, 0);
      strokeWeight(2);
      fill(255, 255, 0);
      rect(x*wid+5, y*wid+10, 7, 7);
      rect(x*wid+17, y*wid+10, 7, 7);
    }
    x-=off;
    px-=off;
  }
}
//--------------------------------------------------------------------------------  CELL  ----------------------------------------------------------------------------
//----------------------------------------------------------------------------  MOUSE PRESSED  ----------------------------------------------------------------------------
void mousePressed() { //clicking on the arena refreshes it
  setup();
}
//----------------------------------------------------------------------------  MOUSE PRESSED  ----------------------------------------------------------------------------
//-----------------------------------------------------------------------------  KEY PRESSED  ----------------------------------------------------------------------------
void keyPressed() { //if a key is pressed the robot will return to the last checkpoint visited, forgeting anything learnt after it
  for (int h = 0; h < 5; h++) {
    for (int i = 0; i < ySize; i++) {
      for (int j = 0; j < xSize; j++) {
        for (int k = 0; k < history.length; k++) {
          if (h == history[k].z && i == history[k].y && j == history[k].x) {
            arena[h][i][j].visited = false;
            robot.z = lastCheckpoint.z;
            robot.y = lastCheckpoint.y;
            robot.x = lastCheckpoint.x;
          }
        }
      }
    }
  }
}
//-----------------------------------------------------------------------------  KEY PRESSED  ----------------------------------------------------------------------------
//--------------------------------------------------------------------------------  ROBOT  ----------------------------------------------------------------------------
class Robot {
  boolean finishedFloor = false;
  boolean ignore = false;
  float wid = 30;
  char dir; //points in which direction the robot is facing. it can be N, E, W or S.
  int x, y, z;
  int py, px;
  int floorDir = 1; //set the robot to start exploring upwards (according to the z-axis)

  Robot(int bx, int by) { //starting values for the robot
    x = bx;
    y = by;
    z = 0;
  }

  void start() { //sets the direction the robot starts facing to
    switch(y) {
    case 0: //if its on the left edge
      dir = 'W';
      break;

    case 19: //if it's on th right edge
      dir = 'E';
      break;

    default: //else
      switch(x) { //if it's on the top edge
      case 0:
        dir = 'S';
        break;

      default: //else (south edge)
        dir = 'N';
      }
    }
  }

  Cell addOption(char a, Cell compareFrom, Cell compareTo) {
    compareTo.weight = compareFrom.weight+1; //changes it's weight
    compareTo.instructions = compareFrom.instructions; //instructions to get to compareFrom are copied
    compareTo.instructions = append(compareTo.instructions, a); //an extra instruction to get to compareFrom is added
    arena[z][compareTo.y][compareTo.x] = compareTo;//the matrix is updated with the newest information
    return compareTo;
  }

  void search(Cell compareFrom) {
    println("SEARCHING...");
    Cell compareTo = new Cell(0, 0, 0);//cell it's going to be visited from compareFrom
    Cell[] options = new Cell[0];//array which stores the cells that later can be used to compare from
    arena[z][compareFrom.y][compareFrom.x].weight = 0;//current cell's value is 0
    compareFrom.weight = 0;
    finishedFloor = end();
    int amount = 0;//amount of cells in the array

    while ((!check(compareFrom.y, compareFrom.x) && !finishedFloor) || (finishedFloor && ((!compareFrom.start && z == 0) || (!compareFrom.exit && z != 0)))) {//until it starts comparing from a cell with unvisited neighbours
      arena[z][compareFrom.y][compareFrom.x].out = true;//the cell is marked on the matrix

      if (!compareFrom.north) {//if there's no north wall
        if (!arena[z][compareFrom.y-1][compareFrom.x].out && !(arena[z][compareFrom.y-1][compareFrom.x].black && arena[z][compareFrom.y-1][compareFrom.x].visited)) {//if the north cell hasn't been explored
          compareTo = arena[z][compareFrom.y-1][compareFrom.x];//it's used to compare
          if (compareFrom.weight+1 < compareTo.weight) { //if traveling from the actual place there is better than from the last place
            amount++; //amount of options is incremented
            options = (Cell[])append(options, addOption('N', compareFrom, compareTo));
          }
        }
      }

      if (!compareFrom.east && compareFrom.x != xSize-1) {//no hay pared a la derecha
        if (!arena[z][compareFrom.y][compareFrom.x+1].out && !(arena[z][compareFrom.y][compareFrom.x+1].black && arena[z][compareFrom.y][compareFrom.x+1].visited)) {//la baldosa de la derecha no ha sido explorada
          compareTo = arena[z][compareFrom.y][compareFrom.x+1];//Se usa para comparar
          if (compareFrom.weight+1 < compareTo.weight) { //if traveling from the actual place there is better than from the last place
            amount++; //amount of options is incremented
            options = (Cell[])append(options, addOption('E', compareFrom, compareTo));//Sugerencia: hace que esto devuelva una celda, que la función no acepte el último parámetro y cambia esta línea a options = (Cell[])append('W', options, addOption(compareFrom, compareTo))
          }
        }
      }

      if (!compareFrom.south && compareFrom.y != ySize-1) {//no hay pared abajo
        if (!arena[z][compareFrom.y+1][compareFrom.x].out && !(arena[z][compareFrom.y+1][compareFrom.x].black && arena[z][compareFrom.y+1][compareFrom.x].visited)) {//la baldosa de abajo no ha sido explorada
          compareTo = arena[z][compareFrom.y+1][compareFrom.x];//Se usa para comparar
          if (compareFrom.weight+1 < compareTo.weight) { //if traveling from the actual place there is better than from the last place
            amount++; //amount of options is incremented
            options = (Cell[])append(options, addOption('S', compareFrom, compareTo));//Sugerencia: hace que esto devuelva una celda, que la función no acepte el último parámetro y cambia esta línea a options = (Cell[])append('W', options, addOption(compareFrom, compareTo))
          }
        }
      }

      if (!compareFrom.west) {//no hay pared a la izquierda
        if (!arena[z][compareFrom.y][compareFrom.x-1].out && !(arena[z][compareFrom.y][compareFrom.x-1].black && arena[z][compareFrom.y][compareFrom.x-1].visited)) {//la baldosa de la izquierda no ha sido explorada
          compareTo = arena[z][compareFrom.y][compareFrom.x-1];//Se usa para comparar
          if (compareFrom.weight+1 < compareTo.weight) { //if traveling from the actual place there is better than from the last place
            amount++; //amount of options is incremented
            options = (Cell[])append(options, addOption('W', compareFrom, compareTo));//Sugerencia: hace que esto devuelva una celda, que la función no acepte el último parámetro y cambia esta línea a options = (Cell[])append('W', options, addOption(compareFrom, compareTo))
          }
        }
      }

      int bestWeight = 9999;
      for (int i = 0; i < amount; i++) {//Se recorre el arreglo para buscar las celdas con el menor costo
        if (arena[z][options[i].y][options[i].x].weight < bestWeight && !arena[z][options[i].y][options[i].x].out) {
          bestWeight = options[i].weight;
        }
      }
      for (int i = 0; i < amount; i++) {
        if (!arena[z][options[i].y][options[i].x].out && arena[z][options[i].y][options[i].x].weight == bestWeight) {
          compareFrom = options[i];
          break;
        }
      }
    }

    strokeWeight(15);
    for (int i = 0; i < amount; i++) {//Se recorre el arreglo para buscar las celdas con el menor costo
      if (arena[z][options[i].y][options[i].x].out) {
        stroke(0, 0, 0, 200);
        point((options[i].x+xSize)*wid+15, options[i].y*wid+15);
      } else {
        stroke(255, 0, 0);
        point((options[i].x+xSize)*wid+15, options[i].y*wid+15);
      }
    }
    println(compareFrom.y);
    println(compareFrom.x);
    follow(compareFrom);

    for (int i = 0; i < ySize; i++) {
      for (int j = 0; j < xSize; j++) {
        arena[z][i][j].weight = 9999;
        arena[z][i][j].out = false;
        arena[z][i][j].instructions = new char[0];
      }
    }
    ignore = true;
  }

  boolean end() {
    for (int i = 0; i < ySize; i++) {
      for (int j = 0; j < xSize; j++) {
        if (arena[z][i][j].visited && !arena[z][i][j].black) {
          if (check(i, j))return false;
        }
      }
    }
    return true;
  }

  void follow(Cell target) {
    println("FOLLOWING");
    if (target.weight == 0 || target.weight > 4)frameRate(2);
    char heading;
    stroke(0, 0, 255);
    strokeWeight(15);
    for (int i = 0; i < target.weight; i++) {
      println(target.instructions[i]);
      heading = target.instructions[i];
      strokeWeight(15);
      point((x+xSize)*wid+15, y*wid+15);
      dir = heading;
      strokeWeight(5);
      switch(heading) {
      case 'N':
        line((x+xSize)*wid+15, y*wid+15, (x+xSize)*wid+15, (y-1)*wid+15);
        y--;
        break;

      case 'S':
        line((x+xSize)*wid+15, y*wid+15, (x+xSize)*wid+15, (y+1)*wid+15);
        y++;
        break;

      case 'W':
        line((x+xSize)*wid+15, y*wid+15, (x-1+xSize)*wid+15, y*wid+15);
        x--;
        break;

      default:
        line((x+xSize)*wid+15, y*wid+15, (x+1+xSize)*wid+15, y*wid+15);
        x++;
      }
    }
    strokeWeight(15);
    point((x+xSize)*wid+15, y*wid+15);
  }

  boolean check(int y, int x) {
    if (!arena[z][y][x].north) {
      if (!arena[z][y-1][x].visited) {
        return true;
      }
    }
    if (!arena[z][y][x].south) {
      if (!arena[z][y+1][x].visited) {
        return true;
      }
    } 
    if (!arena[z][y][x].east) {
      if (!arena[z][y][x+1].visited) {
        return true;
      }
    }
    if (!arena[z][y][x].west) {
      if (!arena[z][y][x-1].visited) {
        return true;
      }
    }
    return false;
  }

  void init() {
    if (check(y, x)) {
      switch(dir) {
      case 'N':
        dir = 'W';
        if (!arena[z][y][x].west) {
          if (!arena[z][y][x-1].visited) {
            ignore = true;
            return;
          } else init();
        } else init();

      case 'W':
        dir = 'S';
        if (!arena[z][y][x].south) {
          if (!arena[z][y+1][x].visited) {
            ignore = true;
            return;
          } else init();
        } else init();

      case 'S':
        dir = 'E';
        if (!arena[z][y][x].east) {
          if (!arena[z][y][x+1].visited) {
            ignore = true;
            return;
          } else init();
        } else init();

      case 'E':
        dir = 'N';
        if (!arena[z][y][x].north) {
          if (!arena[z][y-1][x].visited) {
            ignore = true;
            return;
          } else init();
        } else init();
      }
    } else ignore = true;
  }

  void dibujar(int off) {
    x+=off;
    fill(0, 0, 255);
    stroke(0, 0, 255, 60);
    strokeWeight(2);
    rect(x*wid+4, y*wid+4, wid-8, wid-8);
    fill(255, 50, 50);
    switch(dir) {
    case 'N' : 
      rect(x*wid+4, y*wid+4, wid-8, wid/6); 
      break;
    case 'E' : 
      rect(x*wid+wid-8, y*wid+4, wid/6, wid-8); 
      break;
    case 'S' : 
      rect(x*wid+4, y*wid+wid-8, wid-8, wid/6); 
      break;
    default : 
      rect(x*wid+4, y*wid+4, wid/6, wid-8);
    }
    x-=off;
    if (arena[z][y][x].victim != 'F' && arena[z][y][x].oneKit == false && arena[z][y][x].victimStatus == 'S')arena[z][y][x].oneKit = true;
    if (arena[z][y][x].victim != 'F' && arena[z][y][x].twoKits == false && arena[z][y][x].victimStatus == 'H')arena[z][y][x].twoKits = true;
  }

  void changeDir() {
    switch (dir) {
    case 'N'://está yendo hacia arriba
      if (!arena[z][y][x].east) {//y encuentra una baldosa a su derecha
        if (!arena[z][y][x+1].visited) {//no está visitada
          dir = 'E';
          ignore = true;
        } else if (arena[z][y][x].north) {//hay una pared al frente
          init();
        } else if (arena[z][y-1][x].visited) {
          init();
        }
      } else if (arena[z][y][x].north) {//o una pared al frente
        init();
      } else if (arena[z][y-1][x].visited) {
        init();
      }
      break;
    case 'W'://está yendo hacia la izquierda
      if (!arena[z][y][x].north) {//y encuentra una baldosa a su derecha
        if (!arena[z][y-1][x].visited) {
          dir = 'N';
          ignore = true;
        } else if (arena[z][y][x].west) {//o una pared al frente
          init();
        } else if (arena[z][y][x-1].visited) {
          init();
        }
      } else if (arena[z][y][x].west) {//o una pared al frente
        init();
      } else if (arena[z][y][x-1].visited) {
        init();
      }
      break;
    case 'S'://está yendo hacia abajo
      if (!arena[z][y][x].west) {//y encuentra una baldosa a su derecha
        if (!arena[z][y][x-1].visited) {
          dir = 'W';
          ignore = true;
        } else if (arena[z][y][x].south) {//o una pared al frente
          init();
        } else if (arena[z][y+1][x].visited) {
          init();
        }
      } else if (arena[z][y][x].south) {//o una pared al frente
        init();
      } else if (arena[z][y+1][x].visited) {
        init();
      }
      break;
    default:
      if (!arena[z][y][x].south) {//está yendo a la derecha y encuentra una baldosa a su derecha
        if (!arena[z][y+1][x].visited) {
          dir = 'S';
          ignore = true;
        } else if (arena[z][y][x].east) {//o una pared al frente
          init();
        } else if (arena[z][y][x+1].visited) {//o está visitada al frente
          init();
        }
      } else if (arena[z][y][x].east) {//o una pared al frente
        init();
      } else if (arena[z][y][x+1].visited) {//o está visitada al frente
        init();
      }
    }
  }

  void run() {
    {
      //lo que significa cada dirección en términos de índices
      switch(dir) {
      case 'N': 
        y--; 
        break;
      case 'E': 
        x++; 
        break;
      case 'S': 
        y++; 
        break;
      default: 
        x--;
      }
      arena[z][y][x].visited = true;

      if (!arena[z][y][x].check) {
        history = (Cell[])append(history, arena[z][y][x]);
      } else { 
        history = new Cell[0];
        lastCheckpoint = arena[z][y][x];
      }
      if (arena[z][y][x].black) {
        switch (dir) {
        case 'N': 
          y++; 
          break;
        case 'E': 
          x--; 
          break;
        case 'S': 
          y--; 
          break;
        default: 
          x++;
        }
      } else if (arena[z][y][x].exit) {
        if (!arena[z][y][x].check) {
          history = (Cell[])append(history, arena[z][y][x]);
        } else {
          history = new Cell[0];
          lastCheckpoint = arena[z][y][x];
        }
        z += floorDir;
        ignore = true;
        arena[z][y][x].visited = true;
      }
    }
  }

  void recorrer() {
    ignore = false;
    if (finishedFloor)floorDir = -1;
    if (!check(y, x)) {
      if (!arena[z][y][x].exit) {
        search(arena[z][y][x]);
      } else if (!finishedFloor) {
        search(arena[z][y][x]);
      } else {
        if (!arena[z][y][x].check) {
          history = (Cell[])append(history, arena[z][y][x]);
        } else {
          history = new Cell[0];
          lastCheckpoint = arena[z][y][x];
        }
        z += floorDir;
        ignore = true;
        arena[z][y][x].visited = true;
        arena[z][y][x].exit = false;
        arena[z][y][x].deleted = true;
        finishedFloor = false;
      }
    } else {

      changeDir();

      if (!ignore) run();
    }
  }
}
