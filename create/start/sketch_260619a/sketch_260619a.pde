PImage rexImage;
float gravity = 1; // 下向きの重力加速度
Player rex;

void setup(){
  size(600,200);
  background(255);
  frameRate(60);
  imageMode(CENTER);
  rexImage = loadImage("trex.png");
  rex = new Player();
}

void draw(){
  background(255);
  line(0, 0.8*height, width, 0.8*height); // 地面
  rex.update();
}

void keyPressed(){
  if(key==' '){rex.jump();} 
}

class Player{
  float py; // 位置
  float vy; // 速度
  float spotHeight = 0.7*height; // 基準点
  boolean isGrounded; // 地面に接地しているか
  
  Player(){
    py = spotHeight;
    vy = 0;
    isGrounded = true;
  }
  
  // function
  void update(){
    vy += gravity;
    py += vy;
    if(py>=spotHeight){
      isGrounded = true; // Playerの位置が0.75*heightであれば接地しているとする
      py = spotHeight;
    }
    image(rexImage, 50, py, 60, 60);
  }
  
  void jump(){ 
    if(isGrounded){ // 地面に接地しているときだけjumpできる
      isGrounded = false;
      vy = -14;
    }
  }
}
