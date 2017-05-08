float density = 0.5; //densidad de dibujado

int black_cell = 3; //densidad de celdas negras
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
  
  int px,py;
  
  if(random(1) > 0.5) { //posiciona el robot en un borde a una altura random
    if(random(1) > 0.5)
      px = 0;
    else
      px = xSize-1;
    py = int(random(ySize));
  }
  else{
    if(random(1) > 0.5)
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
  robot = new Robot(px,py);
  robot.init();
  strokeWeight(2); //grosor lineas
}

void draw() {
  background(255,255,240); //fondo
  robot.dibujar();
  robot.recorrer();
  for (int i = 0; i < xSize; i++) {
    for (int j = 0; j < ySize; j++) {
      arena[i][j].dibujar(0); //dibuja las baldosas, ahora con un parámetro
      if(arena[i][j].visited)arena[i][j].dibujar(width/2);//se replican las baldosas visitadas en la otra mitad de la pantalla.
    }
  }
}

class Cell {
  boolean north = false; //resetea todas las paredes para la baldosa nueva
  boolean south = false;
  boolean east = false;
  boolean west = false;
  boolean visited = false;

  int x, y, wid = 30;

  Cell(int bx, int by, float p) {    
    x = bx * wid;
    y = by * wid;

    if (by == 0)//dibuja borde superior
      north = true;
    else if(arena[by-1][bx].south) //sino si la baldosa superior tiene una pared en sur     
      north = true;
    if (bx == 0)//dibuja borde izquierdo
      west = true;
    else if(arena[by][bx-1].east) //sino si la baldosa a su izquierda tiene una pared este
      west = true;
    if (by == ySize-1)//dibuja borde inferior
      south = true;
    if (bx == xSize-1)//dibuja borde derecho
      east = true; 

    if (p < density) { //pregunta si dibuja o no
      if (random(1) < 0.3 && (!west || !north)) { //pregunta si dibuja 2 paredes o una
        south = true;
        east = true;
      }  
      else if (random(1) < 0.5) {//dibuja abajo
        south = true;
      } 
      else {//dibuja adentro
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
    stroke(0);
    line(x, y, x+wid, y);
    line(x+wid, y, x+wid, y+wid);

    if (visited){
      strokeWeight(2);
      stroke(50, 170, 50);
      fill(50, 170, 50, 50);
      rect(x+6, y+6, wid-12, wid-12);
    }
    x-=off;
  }
}

void mousePressed() { //al hacer click refrescar pista
  setup();
}

class Robot {
  int x, y;
  char dir;//dir podrá ser 'N','S','E', o 'W', indica la dirección actual del robot.
  
  float wid = 30;
  
  Robot(int bx, int by) {
    x = bx;
    y = by;
  }
  
  void init(){
    if(arena[y][x].north){//empezamos en el borde de arriba
      if(arena[y][x].west){//tenemos una pared a la izquierda
        if(arena[y][x].south){//y otra abajo
          if(arena[y][x].east){//y a la derecha. Estamos encerrados
            setup();//fuck
          }
          else dir = 'E';//hay salida a la derecha
        }
        else dir = 'S';//hay salida abajo, no importa otra cosa
      }
      else dir = 'W';//hay salida a la izquierda, no importa otra cosa
    }
    else if(arena[y][x].west){//hay una pared a la izquierda. Arriba no hay, pero se prefiere otra dirección
      if(arena[y][x].south){//hay una pared abajo
        if(arena[y][x].east){//y otra a la derecha. Única opción es arriba
          dir = 'N';
        }
        else dir = 'E';//hay salida a la derecha 
      }
      else dir = 'S';//hay salida abajo
    }
    else if(arena[y][x].south){//hay una pared abajo, salidas arriba y a la izquierda
      if(arena[y][x].east){//hay pared abajo y a la derecha, subir
        dir = 'N';
      }
      else dir = 'E';//hay salida a la derecha
    }
    else dir = 'N';//hay una pared a la derecha solamente, subir.
  }
  
  void dibujar() {
    fill(0, 0, 255);
    strokeWeight(0);
    rect(x*wid+4, y*wid+4, wid-8, wid-8);
  }

  void recorrer() {
    
      if(dir == 'N'){//está yendo hacia arriba
        if(!arena[y][x].east){//y encuentra una baldosa a su derecha
          dir = 'E';
        }
        else if(arena[y][x].north){//o una pared al frente
          init();
        }
      }
      else if(dir == 'W'){//está yendo hacia la izquierda
        if(!arena[y][x].north){//y encuentra una baldosa a su derecha
          dir = 'N';
        }
        else if(arena[y][x].west){//o una pared al frente
          init();
        }
      }
      else if(dir == 'S'){//está yendo hacia abajo
        if(!arena[y][x].west){//y encuentra una baldosa a su derecha
          dir = 'W';
        }
        else if(arena[y][x].south){//o una pared al frente
          init();
        }
      }
      else if(!arena[y][x].south){//está yendo a la derecha y encuentra una baldosa a su derecha
        dir = 'S';
      }
      else if(arena[y][x].east){//o una pared al frente
        init();
      }
    arena[y][x].visited = true;
    
    
    //lo que significa cada dirección en términos de índices
    if(dir == 'N'){
      y--;
    }
    else if(dir == 'E'){
      x++;
    }
    else if(dir == 'S'){
      y++;
    }
    else x--;
    
    /*
    if(!arena[y][x].east)
      x++;
    else if(!arena[y][x].south)
      y++;
    else if(!arena[y][x].west) {
      if(!arena[y][x].south)
        y++;
      else if(!arena[y][x].north)
        y--;
    }
    */
    //delay(200);
  }
}
