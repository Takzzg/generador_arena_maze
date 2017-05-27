float density = .6; //densidad de dibujado

int cont = 0;

float blackCell = .01; //densidad de celdas negras

int checkpoint = 2; //densidad de checkpoints

int xSize;

int ySize;


Robot robot = new Robot(3, 0);


Cell[][] arena; //crea arena


void setup() {

  size(1201, 601); //tamaño pantalla, ahora el doble de ancho

  //habría que destinar la mitad derecha de la pantalla para mostrar la pista desde el punto de vista del robot

  xSize = int((width-1)/2/30); //determina ancho arena

  ySize = int((height-1)/30); //determina alto arena

  arena = new Cell[ySize][xSize]; //setea tamanno arena al ancho de las arena



  int px, py;



  if (random(1) > 0.5) { //posiciona el robot en un borde a una altura random

    if (random(1) > 0.5)

      px = 0;

    else

      px = xSize-1;

    py = int(random(ySize));
  } else {

    if (random(1) > 0.5)

      py = 0;

    else

      py = ySize-1;

    px = int(random(xSize));
  }






  for (int i = 0; i < xSize; i++) {

    for (int j = 0; j < ySize; j++) {

      arena[i][j] = new Cell(j, i, random(1)); //crea las baldosas
    }
  }

  robot = new Robot(px, py);
  arena[py][px].start = true;

  robot.start();

  strokeWeight(2); //grosor lineas
}


void draw() {

  background(255, 255, 240); //fondo

  robot.dibujar(0);
  robot.dibujar(xSize);
  robot.recorrer();

  for (int i = 0; i < xSize; i++) {

    for (int j = 0; j < ySize; j++) {

      arena[i][j].dibujar(0); //dibuja las baldosas, ahora con un parámetro

      if (arena[i][j].visited)arena[i][j].dibujar(width/2);//se replican las baldosas visitadas en la otra mitad de la pantalla.
    }
  }
}


class Cell {

  boolean north = false; //resetea todas las paredes para la baldosa nueva
  boolean south = false;
  boolean east = false;
  boolean west = false;
  boolean visited = false;
  boolean start = false;
  boolean black = false;
  int stack = cont++;


  int x, y, wid = 30;
  int px, py;

  Cell(int bx, int by, float p) { 

    x = bx * wid;
    y = by * wid;
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
    
    if(random(1)< blackCell)black=true;
     

    if (p < density) { //pregunta si dibuja o no
      if (random(1) < 0.2 && (!west || !north)) { //pregunta si dibuja 2 paredes o una
        south = true;
        east = true;
      } else if (random(1) < 0.5) {//dibuja abajo
        south = true;
      } else {//dibuja adentro

        east = true;
      }
    }
  }


  void dibujar(int off) {//off es un parámetro que indica un desfazaje al pedir el dibujo de la baldosa. Se suma a x y después se revierte al salir.

    strokeWeight(2);
    x+=off;
    stroke(0);
    if (north)line(x, y, x+wid, y);//north
    if (east)line(x+wid, y, x+wid, y+wid);//east
    if (south) line(x, y+wid, x+wid, y+wid);//south
    if (west)line(x, y, x, y+wid);//west

    strokeWeight(0); // cuadricula gris
    stroke(0, 50);
    line(x, y, x+wid, y);
    line(x+wid, y, x+wid, y+wid);

    if (visited) {
      fill(50, 170, 50, 50);
      rect(x+6, y+6, wid-12, wid-12);
      strokeWeight(2);
      //fill(0);
      //text(stack, x + 10, y + 20);
      stroke(0, 0, 255,60);
      if (stack>0)line(px*wid + 15, py*wid + 15, x-off + 15, y + 15);
    }

    if (start) {
      fill(0, 255, 0);
      rect(x+6, y+6, wid-12, wid-12);
    }
    if (black) {
      fill(0);
      rect(x,y,wid,wid);
    }

    x-=off;
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

  boolean check(int y, int x) {
    if (!arena[y][x].north) {
      if (!arena[y-1][x].visited && !arena[y-1][x].black) {
        return true;
      }
    }
    if (!arena[y][x].south) {
      if (!arena[y+1][x].visited && !arena[y+1][x].black) {
        return true;
      }
    } 
    if (!arena[y][x].east) {
      if (!arena[y][x+1].visited && !arena[y][x+1].black) {
        return true;
      }
    }
    if (!arena[y][x].west) {
      if (!arena[y][x-1].visited && !arena[y][x-1].black) {
        return true;
      }
    }
    return false;
  }

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
    if (best  == 9999){
      delay(5000);
      setup();
      
    }
  }


  void init() {
    switch(dir) {
    case 'N':
      dir = 'W';
      if (!arena[y][x].west) {
        if (!arena[y][x-1].visited && !arena[y][x-1].black) {
          return;
        } else init();
      } else init();

    case 'W':
      dir = 'S';
      if (!arena[y][x].south) {
        if (!arena[y+1][x].visited && !arena[y+1][x].black) {
          return;
        } else init();
      } else init();

    case 'S':
      dir = 'E';
      if (!arena[y][x].east) {
        if (!arena[y][x+1].visited && !arena[y][x+1].black) {
          return;
        } else init();
      } else init();

    case 'E':
      dir = 'N';
      if (!arena[y][x].north) {
        if (!arena[y-1][x].visited && !arena[y-1][x].black) {
          return;
        } else init();
      } else init();
    }
  }

  void dibujar(int off) {
    x+=off;
    fill(0, 0, 255);

    strokeWeight(0);
    rect(x*wid+4, y*wid+4, wid-8, wid-8);
    fill(255, 50, 50);
    if (dir=='N')rect(x*wid+4, y*wid+4, 22, 5);
    else if (dir=='E')rect(x*wid+22, y*wid+4, 5, 22);
    else if (dir=='S')rect(x*wid+4, y*wid+22, 22, 5);
    else if (dir=='W')rect(x*wid+4, y*wid+4, 5, 22);

    x-=off;
  }
  void recorrer() {

    arena[y][x].stack = cont++;
    arena[y][x].visited = true;
    px = x;
    py = y;

    if (!check(y, x))stack();

    if (dir == 'N') {//está yendo hacia arriba
      if (!arena[y][x].east) {//y encuentra una baldosa a su derecha
        if (!arena[y][x+1].visited && !arena[y][x+1].black) {//no está visitada
          dir = 'E';
        } else if (arena[y][x].north) {//hay una pared al frente
          init();
        } else if (arena[y-1][x].visited || arena[y-1][x].black) {
          init();
        }
      } else if (arena[y][x].north) {//o una pared al frente
        init();
      } else if (arena[y-1][x].visited || arena[y-1][x].black) {
        init();
      }
    } else if (dir == 'W') {//está yendo hacia la izquierda
      if (!arena[y][x].north) {//y encuentra una baldosa a su derecha
        if (!arena[y-1][x].visited && !arena[y-1][x].black) {
          dir = 'N';
        } else if (arena[y][x].west) {//o una pared al frente
          init();
        } else if (arena[y][x-1].visited || arena[y][x-1].black) {
          init();
        }
      } else if (arena[y][x].west) {//o una pared al frente
        init();
      } else if (arena[y][x-1].visited || arena[y][x-1].black) {
        init();
      }
    } else if (dir == 'S') {//está yendo hacia abajo
      if (!arena[y][x].west) {//y encuentra una baldosa a su derecha
        if (!arena[y][x-1].visited && !arena[y][x-1].black) {
          dir = 'W';
        } else if (arena[y][x].south) {//o una pared al frente
          init();
        } else if (arena[y+1][x].visited || arena[y+1][x].black) {
          init();
        }
      } else if (arena[y][x].south) {//o una pared al frente
        init();
      } else if (arena[y+1][x].visited || arena[y+1][x].black) {
        init();
      }
    } else if (!arena[y][x].south) {//está yendo a la derecha y encuentra una baldosa a su derecha
      if (!arena[y+1][x].visited && !arena[y+1][x].black) {
        dir = 'S';
      } else if (arena[y][x].east) {//o una pared al frente
        init();
      } else if (arena[y][x+1].visited || arena[y][x+1].black) {//o está visitada al frente
        init();
      }
    } else if (arena[y][x].east) {//o una pared al frente
      init();
    } else if (arena[y][x+1].visited || arena[y][x+1].black) {//o está visitada al frente
      init();
    }
    //lo que significa cada dirección en términos de índices

    if (dir == 'N') {
      y--;
    } else if (dir == 'E') {
      x++;
    } else if (dir == 'S') {
      y++;
    } else x--;
    //delay(50);
    arena[y][x].px = px;
    arena[y][x].py = py;
  }
}
