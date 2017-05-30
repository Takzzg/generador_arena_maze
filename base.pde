float density = .7; //densidad de dibujado //<>//
float doubleDensity = .2;
float blackCell = .04; //densidad de celdas negras
int checkpoint = 2; //densidad de checkpoints
int xSize;
int ySize;

Robot robot = new Robot(0,0);

Cell[][] arena; //crea arena
Cell example = new Cell(0,0);
void setup() {

  size(1200, 600); //tamaño pantalla, ahora el doble de ancho
  //habría que destinar la mitad derecha de la pantalla para mostrar la pista desde el punto de vista del robot
  xSize = int((width)/2/example.wid); //determina ancho arena
  ySize = int((height)/example.wid); //determina alto arena
  frameRate(10);
  arena = new Cell[ySize][xSize]; //setea tamaño arena al ancho de las arena

  int px, py;

  if (random(1) > 0.5) { //posiciona el robot en un borde a una altura random
    if (random(1) > 0.5) px = 0;
    else px = xSize-1;
    py = int(random(ySize));
  } else {
    if (random(1) > 0.5) py = 0;
    else py = ySize-1;
    px = int(random(xSize));
  }

  for (int i = 0; i < ySize; i++) {
    for (int j = 0; j < xSize; j++) {
      arena[i][j] = new Cell(j, i); //crea las baldosas
    }
  }

  robot = new Robot(px, py);
  arena[py][px].start = true;
  arena[py][px].visited = true;
  robot.start();
  robot.dibujar(0);
  robot.dibujar(xSize);
}


void draw() {
  background(255, 255, 240); //fondo
  frameRate(4);
  robot.recorrer();
  for (int i = 0; i < ySize; i++) {
    for (int j = 0; j < xSize; j++) {
      arena[i][j].dibujar(0); //dibuja las baldosas, ahora con un parámetro
      if (arena[i][j].visited)arena[i][j].dibujar(xSize);//se replican las baldosas visitadas en la otra mitad de la pantalla.
    }
  }
  robot.dibujar(0);
  robot.dibujar(xSize);
}


class Cell {
  boolean north = false; //resetea todas las paredes para la baldosa nueva
  boolean south = false;
  boolean east = false;
  boolean west = false;
  boolean visited = false;
  boolean start = false;
  boolean black = false;
  int stack = robot.cont++;
  int weight = 9999;
  boolean out = false;
  char[] instructions = {};

  int x, y, wid = 30;
  int px, py;

  Cell(int bx, int by) { 

    x = bx;
    y = by;
    //px = x/wid;
    if (by == 0)//dibuja borde superior
      north = true;
    else if (arena[by-1][bx].south) //sino si la baldosa superior tiene una pared en sur 
      north = true;
    if (bx == 0)//dibuja borde izquierdo
      west = true;
    else if (arena[by][bx-1].east) //sino si la baldosa a su izquierda tiene una pared este
      west = true;
    if (by == ySize-1)//dibuja borde inferior
      south = true;
    if (bx == xSize-1)//dibuja borde derecho
      east = true; 

    if (random(1)< blackCell)black=true;

    if (random(1) < density) { //pregunta si dibuja o no
      if (random(1) < doubleDensity && (!west || !north)) { //pregunta si dibuja 2 paredes o una
        south = true;
        east = true;
      } else if (random(1) < 0.5) south = true;//dibuja abajo
      else east = true;//dibuja a la derecha
    }
  }

  void dibujar(int off) {//off es un parámetro que indica un desfazaje al pedir el dibujo de la baldosa. Se suma a x y después se revierte al salir.
    x+=off;
    px+=off;
    strokeWeight(2);
    stroke(0);
    if (north)line(x*wid, y*wid, (x+1)*wid, y*wid);//north
    if (east)line((x+1)*wid, y*wid, (x+1)*wid, (y+1)*wid);//east
    if (south) line(x*wid, (y+1)*wid, (x+1)*wid, (y+1)*wid);//south
    if (west)line(x*wid, y*wid, x*wid, (y+1)*wid);//west

    strokeWeight(0); // cuadricula gris
    stroke(0, 50);
    line(x*wid, y*wid, (x+1)*wid, y*wid);
    line((x+1)*wid, y*wid, (x+1)*wid, (y+1)*wid);

    if (visited) {
      px+=xSize;
      x+=xSize;
      stroke(50, 170, 50, 100);
      strokeWeight(2);
      fill(50, 170, 50, 50);
      rect(x*wid+6, y*wid+6, wid-12, wid-12);
      strokeWeight(2);
      //fill(0);
      //text(stack, x + 10, y + 20);
      stroke(0, 0, 255, 100);
      if (stack>0) line(px*wid + 15, py*wid + 15, x*wid + 15, y*wid + 15);
      px-=xSize;
      x-=xSize;
    }
    if (start) {
      strokeWeight(2);
      fill(0, 255, 0, 200);
      stroke(0, 255, 0);
      rect(x*wid+3, y*wid+3, wid-6, wid-6);
    }
    if (black) {
      stroke(0);
      strokeWeight(2);
      fill(0, 200);
      rect(x*wid+3, y*wid+3, wid-6, wid-6);
    }
    x-=off;
    px-=off;
  }
}


void mousePressed() { //al hacer click refrescar pista
  setup();
}


class Robot {
  int x, y;
  int py, px;
  char dir;//dir podrá ser 'N','S','E', o 'W', indica la dirección actual del robot.
  int cont;
  float wid = 30;
  boolean ignore = false;

  Robot(int bx, int by) {
    cont = 0;
    x = bx;
    y = by;
  }

  void start() {
    switch(y) {
    case 0:
      dir = 'W';
      break;

    case 19:
      dir = 'E';
      break;

    default:
      switch(x) {
      case 0:
        dir = 'S';
        break;

      default:
        dir = 'N';
      }
    }
  }

  void search(Cell compareFrom) {
    println("SEARCHING...");
    Cell compareTo = compareFrom;//Celda que será vista desde compareFrom
    Cell[] options = new Cell[900];//array de opciones que almacena las celdas desde las que se podría comparar después
    int amount = 0;//cantidad de celdas en el arreglo
    arena[compareFrom.y][compareFrom.x].weight = 0;//el peso de la celda actual es 0
    compareFrom.weight = 0;
    while ((!check(compareFrom.y, compareFrom.x) && !end()) || (end() && !compareFrom.start)) {//hasta que se empiece a comparar desde una celda con vecinos sin visitar.
      arena[compareFrom.y][compareFrom.x].out = true;//Se marca la baldosa en la matriz
      if (!compareFrom.north) {//no hay pared arriba
        if (!arena[compareFrom.y-1][compareFrom.x].out && !(arena[compareFrom.y-1][compareFrom.x].black && arena[compareFrom.y-1][compareFrom.x].visited)) {//la baldosa de arriba no ha sido explorada
          compareTo = arena[compareFrom.y-1][compareFrom.x];//Se usa para comparar
          if (compareFrom.weight+1 < compareTo.weight) {//Viajar desde el lugar actual hacia allá es mejor que desde el lugar anterior
            options[amount] = compareTo;//Se añade a las opciones para explorar más tarde
            amount++;//Se suma 1 a la cantidad de opciones
            arena[compareTo.y][compareTo.x].weight = compareFrom.weight+1;//Se cambia su peso
            arena[compareTo.y][compareTo.x].instructions = compareFrom.instructions;//Se copian las instrucciones para llegar a compareFrom
            arena[compareTo.y][compareTo.x].instructions = append(arena[compareTo.y][compareTo.x].instructions, 'N');//Se añade una instrucción más para llegar a compareTo
          }
        }
      }
      if (!compareFrom.east) {//no hay pared a la derecha
        if (!arena[compareFrom.y][compareFrom.x+1].out && !(arena[compareFrom.y][compareFrom.x+1].black && arena[compareFrom.y][compareFrom.x+1].visited)) {//la baldosa de la derecha no ha sido explorada
          compareTo = arena[compareFrom.y][compareFrom.x+1];//Se usa para comparar
          if (compareFrom.weight+1 < compareTo.weight) {//Viajar desde el lugar actual hacia allá es mejor que desde el lugar anterior
            options[amount] = compareTo;//Se añade a las opciones para explorar más tarde
            amount++;//Se suma 1 a la cantidad de opciones
            arena[compareTo.y][compareTo.x].weight = compareFrom.weight+1;//Se cambia su peso
            arena[compareTo.y][compareTo.x].instructions = compareFrom.instructions;//Se copian las instrucciones para llegar a compareFrom
            arena[compareTo.y][compareTo.x].instructions = append(arena[compareTo.y][compareTo.x].instructions, 'E');//Se añade una instrucción más para llegar a compareTo
          }
        }
      }
      if (!compareFrom.south) {//no hay pared abajo
        if (!arena[compareFrom.y+1][compareFrom.x].out && !(arena[compareFrom.y+1][compareFrom.x].black && arena[compareFrom.y+1][compareFrom.x].visited)) {//la baldosa de abajo no ha sido explorada
          compareTo = arena[compareFrom.y+1][compareFrom.x];//Se usa para comparar
          if (compareFrom.weight+1 < compareTo.weight) {//Viajar desde el lugar actual hacia allá es mejor que desde el lugar anterior
            options[amount] = compareTo;//Se añade a las opciones para explorar más tarde
            amount++;//Se suma 1 a la cantidad de opciones
            arena[compareTo.y][compareTo.x].weight = compareFrom.weight+1;//Se cambia su peso
            arena[compareTo.y][compareTo.x].instructions = compareFrom.instructions;//Se copian las instrucciones para llegar a compareFrom
            arena[compareTo.y][compareTo.x].instructions = append(arena[compareTo.y][compareTo.x].instructions, 'S');//Se añade una instrucción más para llegar a compareTo
          }
        }
      }
      if (!compareFrom.west) {//no hay pared a la izquierda
        if (!arena[compareFrom.y][compareFrom.x-1].out && !(arena[compareFrom.y][compareFrom.x-1].black && arena[compareFrom.y][compareFrom.x-1].visited)) {//la baldosa de la izquierda no ha sido explorada
          compareTo = arena[compareFrom.y][compareFrom.x-1];//Se usa para comparar
          //stroke(0, 0, 150);
          //strokeWeight(15);
          //point((compareFrom.x+xSize)*wid+15, compareTo.y*wid+15);
          if (compareFrom.weight+1 < compareTo.weight) {//Viajar desde el lugar actual hacia allá es mejor que desde el lugar anterior
            options[amount] = compareTo;//Se añade a las opciones para explorar más tarde
            amount++;//Se suma 1 a la cantidad de opciones
            arena[compareTo.y][compareTo.x].weight = compareFrom.weight+1;//Se cambia su peso
            arena[compareTo.y][compareTo.x].instructions = compareFrom.instructions;//Se copian las instrucciones para llegar a compareFrom
            arena[compareTo.y][compareTo.x].instructions = append(arena[compareTo.y][compareTo.x].instructions, 'W');//Se añade una instrucción más para llegar a compareTo
            //arena[compareTo.y][compareTo.x] = compareTo;//Se actualiza la matriz con la nueva información
          }
        }
      }

      int bestWeight = 9999;
      for (int i = 0; i < amount; i++) {//Se recorre el arreglo para buscar las celdas con el menor costo
        if (arena[options[i].y][options[i].x].weight < bestWeight && !arena[options[i].y][options[i].x].out) {
          bestWeight = arena[options[i].y][options[i].x].weight;
        }
      }
      for (int i = 0; i < amount; i++) {
        if (!arena[options[i].y][options[i].x].out && arena[options[i].y][options[i].x].weight == bestWeight) {
          compareFrom = arena[options[i].y][options[i].x];
          break;
        }
      }
    }

    strokeWeight(15);
    for (int i = 0; i < amount; i++) {//Se recorre el arreglo para buscar las celdas con el menor costo
      if (arena[options[i].y][options[i].x].out) {
        stroke(0, 0, 0, 200);
        point((options[i].x+xSize)*wid+15, options[i].y*wid+15);
      } else {
        stroke(255, 0, 0);
        point((options[i].x+xSize)*wid+15, options[i].y*wid+15);
      }
    }
    println(compareFrom.y);
    println(compareFrom.x);
    follow(arena[compareFrom.y][compareFrom.x]);

    for (int i = 0; i < ySize; i++) {
      for (int j = 0; j < xSize; j++) {
        arena[i][j].weight = 9999;
        arena[i][j].out = false;
        arena[i][j].instructions = new char[0];
      }
    }
    ignore = true;
  }

  boolean end() {
    for (int i = 0; i < ySize; i++) {
      for (int j = 0; j < xSize; j++) {
        if (arena[i][j].visited && !arena[i][j].black) {
          if (check(i, j))return false;
        }
      }
    }
    return true;
  }

  void follow(Cell target) {
    println("FOLLOWING");
    if (target.weight == 0 || target.weight > 4)frameRate(.25);
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
      switch(heading){
        case 'N':
          line((x+xSize)*wid+15, y*wid+15,(x+xSize)*wid+15, (y-1)*wid+15);
          y--;
          break;
  
        case 'S':
          line((x+xSize)*wid+15, y*wid+15,(x+xSize)*wid+15, (y+1)*wid+15);
          y++;
          break;
  
        case 'W':
          line((x+xSize)*wid+15, y*wid+15,(x-1+xSize)*wid+15, y*wid+15);
          x--;
          break;
  
        default:
          line((x+xSize)*wid+15, y*wid+15,(x+1+xSize)*wid+15, y*wid+15);
          x++;
      }
    }
    strokeWeight(15);
    point((x+xSize)*wid+15, y*wid+15);
  }

  boolean check(int y, int x) {
    if (!arena[y][x].north) {
      if (!arena[y-1][x].visited) {
        return true;
      }
    }
    if (!arena[y][x].south) {
      if (!arena[y+1][x].visited) {
        return true;
      }
    } 
    if (!arena[y][x].east) {
      if (!arena[y][x+1].visited) {
        return true;
      }
    }
    if (!arena[y][x].west) {
      if (!arena[y][x-1].visited) {
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
        if (!arena[y][x].west) {
          if (!arena[y][x-1].visited) {
            ignore = true;
            return;
          } else init();
        } else init();

      case 'W':
        dir = 'S';
        if (!arena[y][x].south) {
          if (!arena[y+1][x].visited) {
            ignore = true;
            return;
          } else init();
        } else init();

      case 'S':
        dir = 'E';
        if (!arena[y][x].east) {
          if (!arena[y][x+1].visited) {
            ignore = true;
            return;
          } else init();
        } else init();

      case 'E':
        dir = 'N';
        if (!arena[y][x].north) {
          if (!arena[y-1][x].visited) {
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
  }

  void recorrer() {

    if (!ignore)arena[y][x].stack = cont++;

    px = x;
    py = y;
    ignore = false;

    if (!check(y, x))search(arena[y][x]);

    if (!ignore) {
      switch (dir) {
      case 'N'://está yendo hacia arriba
        if (!arena[y][x].east) {//y encuentra una baldosa a su derecha
          if (!arena[y][x+1].visited) {//no está visitada
            dir = 'E';
            ignore = true;
          } else if (arena[y][x].north) {//hay una pared al frente
            init();
          } else if (arena[y-1][x].visited) {
            init();
          }
        } else if (arena[y][x].north) {//o una pared al frente
          init();
        } else if (arena[y-1][x].visited) {
          init();
        }
        break;
      case 'W'://está yendo hacia la izquierda
        if (!arena[y][x].north) {//y encuentra una baldosa a su derecha
          if (!arena[y-1][x].visited) {
            dir = 'N';
            ignore = true;
          } else if (arena[y][x].west) {//o una pared al frente
            init();
          } else if (arena[y][x-1].visited) {
            init();
          }
        } else if (arena[y][x].west) {//o una pared al frente
          init();
        } else if (arena[y][x-1].visited) {
          init();
        }
        break;
      case 'S'://está yendo hacia abajo
        if (!arena[y][x].west) {//y encuentra una baldosa a su derecha
          if (!arena[y][x-1].visited) {
            dir = 'W';
            ignore = true;
          } else if (arena[y][x].south) {//o una pared al frente
            init();
          } else if (arena[y+1][x].visited) {
            init();
          }
        } else if (arena[y][x].south) {//o una pared al frente
          init();
        } else if (arena[y+1][x].visited) {
          init();
        }
        break;
      default:
        if (!arena[y][x].south) {//está yendo a la derecha y encuentra una baldosa a su derecha
          if (!arena[y+1][x].visited) {
            dir = 'S';
            ignore = true;
          } else if (arena[y][x].east) {//o una pared al frente
            init();
          } else if (arena[y][x+1].visited) {//o está visitada al frente
            init();
          }
        } else if (arena[y][x].east) {//o una pared al frente
          init();
        } else if (arena[y][x+1].visited) {//o está visitada al frente
          init();
        }
      }
    }
    if (!ignore) {
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
      //delay(200);
      arena[y][x].visited = true;
      arena[y][x].px = px;
      arena[y][x].py = py;
      if (arena[y][x].black) {
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
      }
    }
  }
}
/*
  void stack() {
   int best = 9999;
   int bestY = 0, bestX = 0;
   int bestStack = 0;
   for (int i = 0; i < ySize; i++) {
   for (int j = 0; j < xSize; j++) {
   if (arena[i][j].visited) {
   if (arena[y][x].stack - arena[i][j].stack < best && check(i, j)) {
   best = arena[y][x].stack - arena[i][j].stack;
   bestY = i;
   bestX = j;
   bestStack = arena[i][j].stack;
   }
   }
   }
   }
   for (int i = 0; i < ySize; i++) {
   for (int j = 0; j < xSize; j++) {
   if (arena[i][j].visited && arena[i][j].stack == bestStack+1) {
   if (i < bestY) {
   dir = 'S';
   } else if (i > bestY) {
   dir = 'N';
   } else if (j < bestX) {
   dir = 'E';
   } else if (j > bestX) {
   dir = 'W';
   }
   }
   }
   }
   x = bestX;
   y = bestY;
   if (best  == 9999) {
   delay(1000);
   setup();
   }
   }
   */
