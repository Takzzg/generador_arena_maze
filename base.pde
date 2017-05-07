float density = 0.5; //densidad de dibujado

int black_cell = 3; //densidad de celdas negras
int checkpoint = 2; //densidad de checkpoints
int xSize;
int ySize;

Robot tuvieja = new Robot(3, 0);

Cell[][] baldosas; //crea arena

void setup() {
  size(601, 601); //tamaño pantalla
  xSize = int(600/30); //determina ancho baldosas
  ySize = int(600/30); //determina alto baldosas
  baldosas = new Cell[ySize][xSize]; //setea tamanno arena al ancho de las baldosas
  
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
  
  tuvieja = new Robot(px,py);

  for (int i = 0; i < xSize; i++) {
    for (int j = 0; j < ySize; j++) {
      baldosas[i][j] = new Cell(j, i, random(1)); //crea las baldosas
    }
  }
  strokeWeight(2); //grosor lineas
}

void draw() {
  background(255); //fondo

  for (int i = 0; i < xSize; i++) {
    for (int j = 0; j < ySize; j++) {
      baldosas[i][j].dibujar(); //dibuja las baldosas
    }
  }

  tuvieja.recorrer();
  tuvieja.dibujar();
}

class Cell {
  boolean north = false; //resetea todas las paredes para la baldosa nueva
  boolean south = false;
  boolean east = false;
  boolean west = false;
  boolean visited;

  int x, y, wid = 30;

  Cell(int bx, int by, float p) {    
    x = bx * wid;
    y = by * wid;

    if (by == 0)//dibuja borde superior
      north = true;
    else if(baldosas[by-1][bx].south) //sino si la baldosa superior tiene una pared en sur     
      north = true;
    if (bx == 0)//dibuja borde izquierdo
      west = true;
    else if(baldosas[by][bx-1].east) //sino si la baldosa a su izquierda tiene una pared este
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

  void dibujar() {
    strokeWeight(2);
    stroke(0);
    if (north)line(x, y, x+wid, y);//north
    if (east)line(x+wid, y, x+wid, y+wid);//east
    if (south) line(x, y+wid, x+wid, y+wid);//south
    if (west)line(x, y, x, y+wid);//west
    
    strokeWeight(0); // cuadricula gris
    stroke(0);
    line(x, y, x+wid, y);
    line(x+wid, y, x+wid, y+wid);

    if (visited) {
      strokeWeight(2);
      stroke(50, 170, 50);
      fill(50, 170, 50);
      rect(x+5, y+5, 20, 20);
    }
  }
}

void mousePressed() { //al hacer click refrescar pista
  setup();
}

class Robot {
  int x, y;
  float wid = 30;
  Robot(int bx, int by) {
    x = bx;
    y = by;
  }

  void dibujar() {
    fill(0, 0, 255);
    strokeWeight(0);
    rect(x*wid+3, y*wid+3, wid-6, wid-6);
  }

  void recorrer() {
    baldosas[y][x].visited = true;
    if(!baldosas[y][x].east)
      x++;
    else if(!baldosas[y][x].south)
      y++;
    else if(!baldosas[y][x].west) {
      if(!baldosas[y][x].south)
        y++;
      else if(!baldosas[y][x].north)
        y--;
    }
    delay(300);
  }
}
