/*
Bueno, esto es lo que hay.
Voy a dejar una lista de cosas que hay que hacer
con este código para empezar a probar el robot.

Las librerías no están.
Hay que migrar lo que está hecho con los motores,
los giros, los avances y retrocesos.
También la función loadData requiere información
de los sensores.

*incluir librerías
*agregar todo lo que se necesita para manejo de motores
  *rellenar las funciones de motores(a partir de línea 125)

*agregar todo lo que se necesita para lectura de sensores
  *rellenar la función loadData(a partir de línea 496)

*añadir una función que avance por una rampa hasta llegar a una baldosa plana.
*/



 //------------------------------------------ INITIALIZATION ------------------------------------------------
#include <mbed.h>
#include <stdlib.h>
#include <vector>
using namespace std;


/*
#include <Adafruit_BNO055.h>
 #include "MotorDC.h"
 imu::Quaternion quat;
 imu::Vector<3> vector_euler;
 imu::Vector<3> vector_acc;
 imu::Vector<3> vector_euler_init;

 MotorDC M_izq(PTD3, PTC9, PTB23);  //pwma, ain1, ain2---- M2
 MotorDC M_der(PTA1, PTB9, PTC1);  //pwmb, bin1, bin2---- M1
 DigitalOut stby(PTC8,1);

 #define BNO055_SAMPLERATE_DELAY_MS (100)
 int st;
 I2C  i2c(PTE25,PTE24);
 Adafruit_BNO055 bno = Adafruit_BNO055(55,0x28,&i2c);
 Serial pc(USBTX,USBRX);

 Ticker update_speed_motors;
 */
typedef struct Cell {
  bool north; //sets all cells' variables to false (= blank cell)
  bool south;
  bool east;
  bool west;
  bool checkpoint;
  bool start;
  bool black;
  bool visited;
  bool exit;
  bool out;
  char victimStatus;
  vector<char> instructions;
  int weight; //sets a ceiling for the weight to compare to
  unsigned int x, y, z;
  int linkedFloor;
  int linkedX;
  int linkedY;
}Cell;
/**
 * [initCells description]
 * @param targ [description]
 * @param Z    [description]
 * @param Y    [description]
 * @param X    [description]
 */
void initCells(Cell *targ, int Z, int Y, int X) {
  targ->z = Z;
  targ->y = Y;
  targ->x = X;
  targ->black = false;
  targ->exit = false;
  targ->north = false;
  targ->south = false;
  targ->west = false;
  targ->east = false;
  targ->linkedFloor = 0;
  targ->out = false;
  targ->weight = 999;
  targ->visited = false;
  targ->checkpoint = false;
  targ->start = false;
  targ->victimStatus = 'F';
  targ->instructions.clear();
}
/**
 * [assignCells description]
 * @param to   [description]
 * @param from [description]
 */
void assignCells(Cell *to, Cell from){
  to->black = from.black;
  to->exit = from.exit;
  to->north = from.north;
  to->south = from.south;
  to->west = from.west;
  to->east = from.east;
  to->linkedFloor = from.linkedFloor;
  to->out = from.out;
  to->weight =  from.weight;
  to->visited = from.visited;
  to->checkpoint = from.checkpoint;
  to->start = from.start;
  to->victimStatus =  from.victimStatus;
  to->instructions = from.instructions;
  to->linkedX = from.linkedX;
  to->linkedY = from.linkedY;
}

bool finishedFloor = false; //this floor has been explored entirely
bool ignore = false;
char dir = 'N'; //points in which direction the robot is facing. it can be N, E, W or S. Always starts facing N
unsigned int x = 0, y = 0, z = 0; //robot starts in the middle of the first floor.
int lastFloor = 0;
int quit = 0;
/**
 * [moveTileBackward description]
 */
void moveTileBackward(){

}
/**
 * [moveTileForward description]
 */
void moveTileForward(){

}
/**
 * [turn_right description]
 */
void turn_right(){

}
/**
 * [turn_left description]
 */
void turn_left(){

}
/**
 * [moveRobot description]
 * @param destination [description]
 */
void moveRobot(char destination) {
  bool reverse = false; //instead of turning 180°, we can go back 30cm and keep the direction
  if (destination != dir) {//we have to turn or go backwards
    switch(dir) {
    case 'N':
      switch (destination) {
      case 'E':
        turn_right();
        x++;
        break;
      case 'W':
        turn_left();
        x--;
        break;
      case 'S':
        moveTileBackward();
        reverse = true;
        y++;
      }
      break;

    case 'E':
      switch (destination) {
      case 'N':
        turn_left();
        y--;
        break;
      case 'S':
        turn_right();
        y++;
        break;
      case 'W':
        moveTileBackward();
        reverse = true;
        x--;
      }
      break;

    case 'S':
      switch (destination) {
      case 'N':
        moveTileBackward();
        reverse = true;
        y--;
        break;
      case 'E':
        turn_left();
        x++;
        break;
      case 'W':
        turn_right();
        x--;
      }
      break;

    case 'W':
      switch (destination) {
      case 'N':
        turn_right();
        y--;
        break;
      case 'E':
        moveTileBackward();
        reverse = true;
        x++;
        break;
      case 'S':
        turn_left();
        y++;
      }
    }
    if (!reverse) dir = destination;
  }
  if(!reverse) moveTileForward();
}

Cell lastCheckpoint; //The last checkpoint visited
vector<Cell> history;
vector<vector<vector<Cell> > > arena;

/**
 * [addOption description]
 * @param  a           [description]
 * @param  compareFrom [description]
 * @param  compareTo   [description]
 * @param  addWeight   [description]
 * @return             [description]
 */
Cell addOption(char a, Cell compareFrom, Cell compareTo, int addWeight) {
  compareTo.weight = compareFrom.weight + addWeight; //changes its weight
  compareTo.instructions = compareFrom.instructions;
  compareFrom.instructions.push_back(a);
  arena.at(compareTo.z).at(compareTo.y).at(compareTo.x) = compareTo;
  return compareTo;
}
/**
 * [addLayer description]
 * @param axis [description]
 */
void addLayer(char axis) {
  if (axis == 'x'){
    arena.at(z).at(y).resize(arena.at(z).at(y).size() + 1);
    initCells(&arena.at(z).at(y).at(arena.at(z).at(y).size() - 1), z, y, arena.at(z).at(y).size() - 1);
  }
  else if (axis == 'y'){
    arena.at(z).resize(arena.at(z).size() + 1);//make it one unit taller
    arena.at(z).at(arena.at(z).size() - 1).resize(x + 1);//make the last layer as wide as necessary
    for(unsigned int i = 0; i < arena.at(z).size(); i++){
      initCells(&arena.at(z).at(arena.at(z).size() - 1).at(i), z, arena.at(z).size() - 1, i);
    }
  }
  else if (axis == 'z'){
    arena.resize(arena.size() + 1);
    arena.at(arena.size() - 1).resize(1);
    arena.at(arena.size() - 1).at(0).resize(1);
    initCells(&arena.at(arena.size() - 1).at(0).at(0), arena.size() - 1, 0, 0);
  }
}
/**
 * [addLayer description]
 * @param axis [description]
 * @param Y    [description]
 */
void addLayer(char axis, int Y){
  arena.at(z).at(Y).resize(arena.at(z).at(Y).size() + 1);
  initCells(&arena.at(z).at(Y).at(arena.at(z).at(Y).size() - 1), z, Y, arena.at(z).at(Y).size() - 1);
}
/**
 * [shift description]
 * @param axis [description]
 */
void shift(char axis) {
  if (axis == 'x') {//add a layer to the left
    x++;
    for(unsigned int i = 0; i < arena.at(z).size(); i++){
      addLayer('x', i);
    }
    for(unsigned int i = 0; i < arena.at(z).size(); i++){
      for(int j = arena.at(z).at(i).size() - 1; j > 0; j--){
        assignCells(&arena.at(z).at(i).at(j), arena.at(z).at(i).at(j-1));
      }
    }
    for(unsigned int i = 0; i < arena.at(z).size(); i++){
      initCells(&arena.at(z).at(i).at(0), z, i, 0);
    }
  }
  else if (axis == 'y') {
    y++;
    addLayer('y');

    for(int i = arena.at(z).size() - 1; i > 0; i--){
      arena.at(z).at(i) = arena.at(z).at(i-1);
    }
    for(unsigned int i = 0; i < arena.at(z).size(); i++){
      for(unsigned int j = 0; j < arena.at(z).at(i).size(); j++){
        arena.at(z).at(i).at(j).y++;//we fix the Y coordinate
      }
    }
    arena.at(z).at(0).clear();
    arena.at(z).at(0).resize(x + 1);
    for(unsigned int i = 0; i < x + 1; i++){
      initCells(&arena.at(z).at(arena.at(z).size() - 1).at(i), z, arena.at(z).size() - 1, i);
    }
  }
}
/**
 * [check description]
 * @param  y [description]
 * @param  x [description]
 * @return   [description]
 */
bool check(int y, int x) { //returns true if at least one neighbour cell isn't explored and there's no wall between the robot and it
  if (!arena.at(z).at(y).at(x).north)
    if (!arena.at(z).at(y - 1).at(x).visited) return true;

  if (!arena.at(z).at(y).at(x).south)
    if (!arena.at(z).at(y + 1).at(x).visited) return true;

  if (!arena.at(z).at(y).at(x).east)
    if (!arena.at(z).at(y).at(x + 1).visited) return true;

  if (!arena.at(z).at(y).at(x).west)
    if (!arena.at(z).at(y).at(x - 1).visited) return true;

  return false;
}
/**
 * [end description]
 * @return [description]
 */
bool end() { //checks if the whole room has been visited
  for(unsigned int i = 0; i < arena.at(z).size(); i++){
    for(unsigned int j = 0; j < arena.at(z).at(i).size(); j++){
      if(arena.at(z).at(i).at(j).visited && !arena.at(z).at(i).at(j).black)
        if(check(i, j)) return false;
    }
  }
  return true;
}
/**
 * [follow description]
 * @param target [description]
 */
void follow(Cell target) {
  for(unsigned int i = 0; i < target.instructions.size(); i++)
    moveRobot(target.instructions.at(i));
}
/**
 * [search description]
 * @param compareFrom [description]
 */
void search(Cell compareFrom) {
  Cell compareTo; //cell that's going to be visited from compareFrom
  vector<Cell> options(0);
  arena.at(z).at(compareFrom.y).at(compareFrom.x).weight = 0; //current cell's value is 0
  compareFrom.weight = 0;
  finishedFloor = end();
  int weightGain = 1;

  while ((!check(compareFrom.y, compareFrom.x) && !finishedFloor) || (finishedFloor && ((!compareFrom.start && z == 0) || (!compareFrom.exit && z != 0)))) { //until it starts comparing from a cell with unvisited neighbours
    arena.at(z).at(compareFrom.y).at(compareFrom.x).out = true;
    if (!compareFrom.north) { //if there's no north wall
      if (!arena.at(z).at(compareFrom.y - 1).at(compareFrom.x).out && !(arena.at(z).at(compareFrom.y - 1).at(compareFrom.x).black && arena.at(z).at(compareFrom.y - 1).at(compareFrom.x).visited)) { //if the north cell hasn't been explored
        compareTo = arena.at(z).at(compareFrom.y - 1).at(compareFrom.x); //it's used to compare
        if ((('N' != compareFrom.instructions.at(compareFrom.instructions.size() - 1)  || 'S' != compareFrom.instructions.at(compareFrom.instructions.size() - 1)) && compareFrom.weight != 0) || (compareFrom.weight == 0 && ('N' != dir || 'S' != dir)))weightGain++; //Add weight if a turn is involved
          if (compareFrom.weight+weightGain < compareTo.weight) //if traveling from the actual place there is better than from the last place
            options.push_back(addOption('N', compareFrom, compareTo, weightGain));

      }
    }

    if (!compareFrom.east && compareFrom.x != arena.at(z).at(y).size()-1) { //if there's no east wall
      if (!arena.at(z).at(compareFrom.y).at(compareFrom.x + 1).out && !(arena.at(z).at(compareFrom.y).at(compareFrom.x + 1).black && arena.at(z).at(compareFrom.y).at(compareFrom.x + 1).visited)) { //if the north cell hasn't been explored
        compareTo = arena.at(z).at(compareFrom.y).at(compareFrom.x + 1); //it's used to compare
        if ((('E' != compareFrom.instructions.at(compareFrom.instructions.size() - 1)  || 'W' != compareFrom.instructions.at(compareFrom.instructions.size() - 1)) && compareFrom.weight != 0) || (compareFrom.weight == 0 && ('E' != dir || 'W' != dir)))weightGain++; //Add weight if a turn is involved
          if (compareFrom.weight+weightGain < compareTo.weight) //if traveling from the actual place there is better than from the last place
            options.push_back(addOption('E', compareFrom, compareTo, weightGain));

      }
    }

    if (!compareFrom.south && compareFrom.y != arena.at(z).size()-1) { //if there's no south wall
      if (!arena.at(z).at(compareFrom.y + 1).at(compareFrom.x).out && !(arena.at(z).at(compareFrom.y + 1).at(compareFrom.x).black && arena.at(z).at(compareFrom.y + 1).at(compareFrom.x).visited)) { //if the north cell hasn't been explored
        compareTo = arena.at(z).at(compareFrom.y + 1).at(compareFrom.x); //it's used to compare
        if ((('S' != compareFrom.instructions.at(compareFrom.instructions.size() - 1)  || 'N' != compareFrom.instructions.at(compareFrom.instructions.size() - 1)) && compareFrom.weight != 0) || (compareFrom.weight == 0 && ('S' != dir || 'N' != dir)))weightGain++; //Add weight if a turn is involved
        if (compareFrom.weight+weightGain < compareTo.weight) //if traveling from the actual place there is better than from the last place
          options.push_back(addOption('S', compareFrom, compareTo, weightGain));

      }
    }

    if (!compareFrom.west) { //if there's no west wall
      if (!arena.at(z).at(compareFrom.y).at(compareFrom.x - 1).out && !(arena.at(z).at(compareFrom.y).at(compareFrom.x - 1).black && arena.at(z).at(compareFrom.y).at(compareFrom.x - 1).visited)) { //if the north cell hasn't been explored
        compareTo = arena.at(z).at(compareFrom.y).at(compareFrom.x - 1); //it's used to compare
        if ((('W' != compareFrom.instructions.at(compareFrom.instructions.size() - 1)  || 'E' != compareFrom.instructions.at(compareFrom.instructions.size() - 1)) && compareFrom.weight != 0) || (compareFrom.weight == 0 && ('E' != dir || 'W' != dir)))weightGain++; //Add weight if a turn is involved
        if (compareFrom.weight+weightGain < compareTo.weight) //if traveling from the actual place there is better than from the last place
          options.push_back(addOption('W', compareFrom, compareTo, weightGain));

      }
    }
    int bestWeight = 9999;
    for (unsigned int i = 0; i < options.size(); i++){
      if(arena.at(options.at(i).z).at(options.at(i).y).at(options.at(i).x).weight < bestWeight && !arena.at(options.at(i).z).at(options.at(i).y).at(options.at(i).x).out){
        bestWeight = arena.at(options.at(i).z).at(options.at(i).y).at(options.at(i).x).weight;
      }
    }
    for (unsigned int i = 0; i < options.size(); i++){
      if(!arena.at(options.at(i).z).at(options.at(i).y).at(options.at(i).x).out && arena.at(options.at(i).z).at(options.at(i).y).at(options.at(i).x).weight == bestWeight){
        compareFrom = arena.at(options.at(i).z).at(options.at(i).y).at(options.at(i).x);
        break;
      }
    }
  }

  follow(compareFrom);

  for (unsigned int i = 0; i < arena.at(z).size(); i++) {
    for (unsigned int j = 0; j < arena.at(z).at(y).size(); j++) {
      arena.at(z).at(i).at(j).weight = 9999;
      arena.at(z).at(i).at(j).out = false;
      arena.at(z).at(i).at(j).instructions.clear();
    }
  }
  options.clear();
  ignore = true;
}
/**
 * [init description]
 */
void init() {
  char one_direction[5] = {'N', 'W', 'S', 'E', 'N'};
  for (int i = 0; i < 4; i++){
    if (dir == one_direction[i]){
      dir = one_direction[i + 1];
      return;
    }
  }
}
/**
 * [loadData description]
 */
void loadData() {
  Cell loadCell;
  loadCell.visited = true;
  /*if (cny70 < ???)*/loadCell.black = true;
  /*if (cny70 > ???)*/loadCell.checkpoint = true;
  /*if (sensores ultrasonido frontales detectan pared)*/loadCell.north = true;
  /*if (sensores ultrasonido derechos detectan pared)*/loadCell.east = true;
  /*if (sensores ultrasonido traseros detectan pared)*/loadCell.south = true;
  /*if (sensores ultrasonido izquierdos detectan pared)*/loadCell.west = true;
  /*if (inclinación ???)*/loadCell.exit = true;

  //IMPORTANTE: izquierda, derecha, adelante, atrás, son relativos a la arena, no al robot. Así que, por ejemplo, si la variable dir == 'S', todo sería al revés, los sensores de adelante serían los de atrás y viceversa, lo mismo con los costados.
  //queda la información de las víctimas y otras cosas. Para testear lo único que importa es que funcione la detección de paredes.
  assignCells(&arena.at(z).at(y).at(x), loadCell);
}
/**
 * [changeDir description]
 */
void changeDir() { //changes robot's direction
  bool f = false;
  switch (dir) {
  case 'N': //it's going north
    if (!arena.at(z).at(y).at(x).east) { //if the east cell isn't explored and has no wall in between
      if (!arena.at(z).at(y).at(x + 1).visited) {
        moveRobot('E');
        ignore = true;
        f = true;
      }
    }
    if (!f) { //else if the north cell hasn't been explored and has no wall between
      if (arena.at(z).at(y).at(x).north) init();
      else if (arena.at(z).at(y - 1).at(x).visited)init();
    }
    break;

  case 'W': //it's going left
    if (!arena.at(z).at(y).at(x).north) { //if the north cell isn't explored and has no wall in between
      if (!arena.at(z).at(y - 1).at(x).visited) {
        moveRobot('N');
        ignore = true;
        f = true;
      }
    }
    if (!f) { //else if the west cell hasn't been explored and has no wall between
      if (arena.at(z).at(y).at(x).west) init();
      else if (arena.at(z).at(y).at(x - 1).visited)init();
    }
    break;

  case 'S': //it's going down
    if (!arena.at(z).at(y).at(x).west) { //if the north cell isn't explored and has no wall in between
      if (!arena.at(z).at(y).at(x - 1).visited) {
        moveRobot('W');
        ignore = true;
        f = true;
      }
    }
    if (!f) { //else if the south cell hasn't been explored and has no wall between
      if (arena.at(z).at(y).at(x).south) init();
      else if (arena.at(z).at(y + 1).at(x).visited)init();
    }
    break;

  default: //it's going right
    if (!arena.at(z).at(y).at(x).south) { //if the north cell isn't explored and has no wall in between
      if (!arena.at(z).at(y + 1).at(x).visited) {
        moveRobot('S');
        ignore = true;
        f = true;
      }
    }
    if (!f) { //else if the east cell hasn't been explored and has no wall between
      if (arena.at(z).at(y).at(x).east) init();
      else if (arena.at(z).at(y).at(x + 1).visited)init();
    }
  }
}
/**
 * [run description]
 */
void run() {
  moveRobot(dir);
    loadData();
    //arena[getIndex(z, y, x)].visited = true; //sets the current cell as visited
    if (!arena.at(z).at(y).at(x).checkpoint) { //if it's not a checkpoint, it's added to the history of visited cells
      history.push_back(arena.at(z).at(y).at(x));
    }
    else { //if it is a checkpoint, sets it as the last visited checkpoint and resets the history
      lastCheckpoint = arena.at(z).at(y).at(x);
      history.clear();
    }
    if (arena.at(z).at(y).at(x).black) { //if it finds a black cell, it'll go back
      moveTileBackward();
    }
    else if (arena.at(z).at(y).at(x).exit) { //if it finds an exit
      arena.at(z).at(y).at(x).linkedFloor = ++lastFloor;
      addLayer('z');
      arena.at(lastFloor).at(y).at(x).linkedFloor = z;
      arena.at(lastFloor).at(y).at(x).linkedX = x;
      arena.at(lastFloor).at(y).at(x).linkedY = y;
      //[INSERTE FUNCIÓN PARA SUBIR RAMPAS AQUÍ] //
      x = 0;
      y = 0;
      z = lastFloor;
      ignore = true;
      arena.at(z).at(y).at(x).visited = true;
     }
}
/**
 * [expand description]
 */
void expand(){
  if(x == 0){
    if(!arena.at(z).at(y).at(x).west)
      shift('x');
  }
  else if(x == arena.at(z).at(y).size() - 1){
    if(!arena.at(z).at(y).at(x).east)
      addLayer('x');
  }
  if(y == 0){
    if(!arena.at(z).at(y).at(x).north)
      shift('y');
  }
  else if(y == arena.at(z).size() - 1){
    if(!arena.at(z).at(y).at(x).south)
      addLayer('y');
  }
}
/**
 * [explore description]
 */
void explore() {
  loadData();
  expand();
  ignore = false;
  finishedFloor = false ;
  if (!check(y, x)) { //if the robot is stuck
    if (!arena.at(z).at(y).at(x).exit) search(arena.at(z).at(y).at(x)); //if it's stuck on a visited ramp and the room isn't finished it'll continue exploring the room
    else if (!finishedFloor) search(arena.at(z).at(y).at(x)); //got stuck on a visited ramp, but there are still some tiles left unvisited.
    else {
      //[PLEASE INSERTE FUNCIÓN PARA SUBIR O BAJAR UNA RAMPA AQUÍ PLEASEEEEE] //
      z = arena.at(z).at(y).at(x).linkedFloor;
      x = arena.at(z).at(y).at(x).linkedX;
      y = arena.at(z).at(y).at(x).linkedY;
      ignore = true;
      arena.at(z).at(y).at(x).visited = true;
      arena.at(z).at(y).at(x).exit = false;
      finishedFloor = false;
    }
  }
  else {
    changeDir();
    if (!ignore) run();
  }
}
/**
 * [main description]
 * @return [description]
 */
int main() {
  arena.resize(1);
  arena.at(0).resize(1);
  arena.at(0).at(0).resize(1);
  initCells(&arena.at(0).at(0).at(0), 0, 0, 0);
  arena.at(0).at(0).at(0).start = true;
  while (1) {
    explore();
  }
}
