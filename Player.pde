public class Player extends Entity {

  private static final int GUN = 0;
  private static final int LASER = 1;

  private static final int REVIVE_TIME = 100;

  public static final int BULLET_RATE = 10;
  public static final int LASER_RATE = 1;

  public int id;
  public ArrayList<Bullet> bullets;

  public Player partner;
  public int reviveTime;
  public boolean down;

  public PowerUp powerUp;
  public int pickUpTime;

  public Controller controller;

  public int weapon;
  public float aim;

  public int lastShot;

  public int lastLaser;
  public float laserX;
  public float laserY;

  public boolean leftBumperState;
  public boolean rightBumperState;

  public boolean haxMode;

  public Player(int id, int x, int y, Controller controller, boolean down) {
    super(x, y, 10, 75);
    this.id = id;
    this.bullets = new ArrayList<Bullet>();
    this.reviveTime = 0;
    this.partner = null;
    this.controller = controller;
    this.down = down;
    this.aim = 0;
    this.weapon = GUN;
  }

  public boolean usingLaser() {
    return weapon == LASER;
  }

  public boolean usingGun() {
    return weapon == GUN;
  }

  public boolean hasSpeed() {
    return powerUp != null && powerUp.type == PowerUp.SPEED;
  }

  public boolean hasDamage() {
    return powerUp != null && powerUp.type == PowerUp.DAMAGE;
  }

  public boolean hasFireRate() {
    return powerUp != null && powerUp.type == PowerUp.FIRE_RATE;
  }

  public boolean hasBulletSpeed() {
    return powerUp != null && powerUp.type == PowerUp.BULLET_SPEED;
  }

  public boolean hasInvincibility() {
    return powerUp != null && powerUp.type == PowerUp.INVINCIBILITY;
  }

  private Player getPartner() {
    for (Player player : game.players) {
      if (player != this && player.down && game.playerDist(player, this) < 75) {
        return player;
      }
    }
    return null;
  }

  public int getReviveDuration() {
    return frameCount - reviveTime;
  }

  private boolean canStartRevivalProcess() {
    return (keys['X'] || controller.X.pressed()) && !down && reviveTime == 0 && getPartner() != null;
  }

  private void startRevivalProcess() {
    partner = getPartner();
    partner.partner = this;
    partner.reviveTime = reviveTime = frameCount;
  }

  private boolean hasRevivalProcessBeenCancelled() {
    return !(keys['X'] || controller.X.pressed()) && partner != null;
  }

  private void cancelRevivalProcess() {
    partner.reviveTime = reviveTime = 0;
    partner.partner = partner = null;
  }

  private boolean hasRevivalBeenSuccessful() {
    return getReviveDuration() >= REVIVE_TIME && partner != null;
  }

  private void revive() {
    if (down) {
      hp = maxHp / 2;
      down = false;
    }
    partner = null;
    reviveTime = 0;
  }

  public void heal() {
    hp = maxHp;
  }

  public void update() {

    updateAim();
    checkWeaponChange();
    checkHaxMode();

    for (Bullet bullet : bullets) {
      bullet.update(this);
    }

    if (canStartRevivalProcess()) {
      startRevivalProcess();
    } else if (hasRevivalProcessBeenCancelled()) {
      cancelRevivalProcess();
    } else if (hasRevivalBeenSuccessful()) {
      revive();
    }  

    if (down || partner != null) {
      return;
    }

    if (haxMode) {
      doHaxMode();
    } else {
      if (isFiring()) {
        shoot();
      }
    }

    movePlayer();

    fixPosition();

    if (frameCount - pickUpTime > PowerUp.DURATION) {
      powerUp = null;
    }
  }

  public void checkWeaponChange() {
    if (!leftBumperState && controller.leftB.pressed()) {
      if (weapon == GUN) {
        weapon = LASER;
      } else if (weapon == LASER) {
        weapon = GUN;
      }
    }
    leftBumperState = controller.leftB.pressed();
  }

  public void checkHaxMode() {
    if (!rightBumperState && controller.rightB.pressed() && controller.Y.pressed()) {
      haxMode = !haxMode;
    }
    rightBumperState = controller.rightB.pressed() && controller.Y.pressed();
  }

  public void movePlayer() {
    x += controller.getLeftX() * getSpeed();
    y += controller.getLeftY() * getSpeed();

    if (keys[UP] || keys['W']) {
      y-= getSpeed();
    }

    if (keys[DOWN] || keys['S']) {
      y += getSpeed();
    }

    if (keys[LEFT] || keys['A']) {
      x -= getSpeed();
    }

    if (keys[RIGHT] || keys['D']) {
      x += getSpeed();
    }
  }

  private float getSpeed() {
    float speed = 2;
    if (hasSpeed()) {
      speed *= 2;
    }
    if (controller.leftClick.pressed()) {
      speed += 1;
    }
    return speed;
  }

  public void fixPosition() {    
    if (y < radius ) {
      y = radius;
    }

    if (y > height - radius) {
      y = height - radius;
    }

    if (x < radius) {
      x = radius;
    }
    if (x > width - radius) {
      x = width - radius;
    }
  }

  public boolean isFiring() {
    return controller.getLeftT() < -0.5;
  }

  public void updateAim() {
    aim = (float) (Math.atan2(controller.getRightY(), controller.getRightX()) * 180.0 / Math.PI);
  }

  public boolean cantShoot() {
    return frameCount - lastShot < BULLET_RATE / (hasFireRate() ? 2 : 1) || usingLaser();
  }

  public void doHaxMode() {
    aim = frameCount * 10;
    
    Bullet bullet = new Bullet(41, 128, 185);
    float bulletX = x + (float) (radius * Math.sin(Math.toRadians(90 - aim)));
    float bulletY = y + (float) (radius * Math.sin(Math.toRadians(aim)));
    bullet.setPosition(bulletX, bulletY);
    bullet.setVelocity(Bullet.BULLET_SPEED, aim);
    bullets.add(bullet);
  }

  public void shoot() {
    if (cantShoot()) {
      return;
    }
    Bullet bullet = new Bullet(41, 128, 185);
    float bulletX = x + (float) (radius * Math.sin(Math.toRadians(90 - aim)));
    float bulletY = y + (float) (radius * Math.sin(Math.toRadians(aim)));
    bullet.setPosition(bulletX, bulletY);
    bullet.setVelocity(Bullet.BULLET_SPEED, aim);
    bullets.add(bullet);
    lastShot = frameCount;
  }

  public void hit() {
    hp--;
    if (isDead()) {
      down = true;
      powerUp = null;
      hp = 0;
    }
  }

  public void respawn() {
    hp = maxHp;
    down = false;
  }

  public void display() {
    drawDownEffect();
    drawPlayer();
    drawId();
    drawLaser();
    drawCursor();
    drawBullets();
    drawHpBar();
    drawPowerUp();
    drawRevivalSystem();
    drawCrosshairs();
  }

  private void drawLaser() {
    if (usingGun() || down || !isFiring()) {
      return;
    }
    float x1 = x + (float) (radius * Math.sin(Math.toRadians(90 - aim)));
    float y1 = y + (float) (radius * Math.sin(Math.toRadians(aim)));
    stroke(255, 0, 0, 100);
    line(x1, y1, laserX, laserY);
  }

  private void drawDownEffect() {
    if (!down) {
      return;
    }
    noStroke();
    fill(255, 102, 102, 200 - (frameCount % 50) * 4);
    ellipse(x, y, radius * 2 + (frameCount % 50) * 4, radius * 2 + (frameCount % 50) * 4);
  }

  private void drawPlayer() {
    noStroke();
    if (powerUp != null) {
      fill(powerUp.red, powerUp.green, powerUp.blue, 150 - (frameCount % 50) * 4);
      ellipse(x, y, radius * 2 + (frameCount % 50) * 2, radius * 2 + (frameCount % 50) * 2);
    }
    stroke(0, 0, 0, 255);
    strokeWeight(2);
    if (down) {
      fill(255, 102, 102);
    } else {
      fill(41, 128, 185, 255);
    }
    ellipse(x, y, radius * 2, radius  * 2);
    if (powerUp != null) {
      fill(powerUp.red, powerUp.green, powerUp.blue, 200 + (float) Math.sin(frameCount / (float) 3) * 25);
      ellipse(x, y, radius * 2, radius  * 2);
    }
  }

  private void drawId() {
    fill(0, 0, 0, 255);
    textAlign(CENTER);
    textSize(24);
    text(id, x, y + 10);
  }

  private void drawCursor() {
    noCursor();
    fill(0);
    ellipse(mouseX, mouseY, 1, 1);
  }

  public void drawBullets() {
    for (Bullet bullet : bullets) {
      bullet.display(this);
    }
  }

  public void drawHpBar() {
    int hpBarX = id * 325 - 175;

    textSize(18);
    fill(0);
    text("Player " + id, hpBarX, height - 40);

    rectMode(CORNER);
    rect(hpBarX - 75, height - 30, 150, 15, 3);

    stroke(0);
    if (down) {
      fill(255 - (frameCount % 25) * 5, 102 - (frameCount % 25) * 5, 102 - (frameCount % 25) * 5);
      rect(hpBarX - 75, height - 30, 150, 15, 3);
    } else {
      setHPBarColor();
      rect(hpBarX - 75, height - 30, 150 * hp / maxHp, 15, 3);
    }
  }

  public void drawPowerUp() {
    if (powerUp == null) {
      return;
    }

    int textX = id * 325 - 175;

    textSize(18);
    fill(0);
    text(powerUp.name + " active", textX, height - 110);

    int powerUpBar = id * 325 - 175;
    rectMode(CORNER);
    fill(0);
    rect(powerUpBar - 75, height - 100, 150, 15, 3);
    float shift = (float) Math.sin(frameCount / (float) 5) * (float) 50; 
    fill(powerUp.red + shift, powerUp.green + shift, powerUp.blue + shift);
    rect(powerUpBar - 75, height - 100, (frameCount - pickUpTime) * 150 / PowerUp.DURATION, 15, 3);
  }

  public void drawRevivalSystem() {
    if (partner == null) {
      if (getPartner() != null && !down) {
        int textX = id * 325 - 175;
        textSize(18);
        fill(0);
        text("Hold 'X' to revive.", textX, height - 70);
      }
      return;
    }

    int revivalBarX = id * 325 - 175;
    rectMode(CORNER);
    fill(0);
    rect(revivalBarX - 75, height - 80, 150, 15, 3);
    fill(255);
    rect(revivalBarX - 75, height - 80, getReviveDuration() * 150 / REVIVE_TIME, 15, 3);
  }

  private void drawCrosshairs() {
    drawCrosshair(40, 5);
    drawCrosshair(45, 3);
    drawCrosshair(48, 2);
  }

  private void drawCrosshair(int distance, int radius) {
    float crossX = x + (float) (distance * Math.sin(Math.toRadians(90 - aim)));
    float crossY = y + (float) (distance * Math.sin(Math.toRadians(aim)));
    fill(0);
    ellipse(crossX, crossY, radius, radius);
  }
}

