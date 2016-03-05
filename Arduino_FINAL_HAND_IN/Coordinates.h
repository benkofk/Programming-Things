
class Coordinates{
  private:
  int x, y;

  public:
  void setX(int x);
  void setY(int y);
  int getX();
  int getY();
};


 void Coordinates::setX(int x){
    this->x = x;
  }

 void Coordinates::setY(int y){
    this->y = y;
  }

  int Coordinates::getX(){
    return x;
  }

  
  int Coordinates::getY(){
    return y;
  }

// enum for ZumoAction's, would be in main if Arduino let us

typedef enum ZumoAction{
left, forward, right, backwards, found, largeLeft, largeFinalTurn
};
